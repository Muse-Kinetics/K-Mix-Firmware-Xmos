#include <xs1.h>
#include <platform.h>
#include <xs1_su.h>
#include <print.h>

#include "ports.h"
#include "i2c_app.h"
#include "flash_data.h"
#include "cutils.h"
#ifdef USE_SPI_MASTER
#include "spi_master.h"
#else
#include "flash.h"
#include "flash_interface.h"
#endif

#define MAX_BLOCK_SIZE  512
#define REQUEST_BLOCK_SIZE  MAX_BLOCK_SIZE

#define TEST_FIRMWARE_UPDATE_TYPE       1
#define TEST_FIRMWARE_UPDATE_SUBTYPE    2


#define RX_CHAR(index)  (event->buffer[index])
#define RX_SHORT(index) (event->buffer[index] + (event->buffer[index+1]<<8))
#define RX_INT(index)   (event->buffer[index] + (event->buffer[index+1]<<8) + (event->buffer[index+2]<<16) + (event->buffer[index+3]<<24))

#define RX_MESSAGE_TYPE    lib__message_type(event->buffer)
#define RX_REQUESTER       lib__requester_address(event->buffer)
#define RX_BIN_TYPE        lib_build_num_request__bin_type(event->buffer)
#define RX_BIN_SUBTYPE     lib_build_num_request__bin_subtype(event->buffer)
#define RX_BLOCK_REQUEST_SIZE      lib_chunk_request__block_size(event->buffer)
#define RX_BLOCK_REQUEST_NUMBER    lib_chunk_request__block_number(event->buffer)
#define RX_BUILD_NUM__BUILD_NUM lib_build_num__buildnum(event->buffer)
#define RX_BUILD_NUM__LENGTH    lib_build_num__length(event->buffer)

#define RX_REQUEST_BLOCK__REQUESTER     RX_REQUESTER
#define RX_REQUEST_BLOCK__BIN_TYPE      RX_BIN_TYPE
#define RX_REQUEST_BLOCK__BIT_SUBTYPE   RX_BIN_SUBTYPE
#define RX_REQUEST_BLOCK__BLOCK_SIZE    RX_BLOCK_REQUEST_SIZE
#define RX_REQUEST_BLOCK__BLOCK_NUMBER  RX_BLOCK_REQUEST_NUMBER

#define RX_BLOCK_HEADER__SIZE       lib_chunk_header__block_size(event->buffer)
#define RX_BLOCK_HEADER__NUMBER     lib_chunk_header__block_number(event->buffer)



#define SET_BYTE(index,val) i2c_command_data[index] = val;
#define SET_SHORT(index,val) i2c_command_data[index] = val; i2c_command_data[index+1] = val >> 8;
#define SET_INT(index,val) i2c_command_data[index] = val;i2c_command_data[index+1] = val>>8;i2c_command_data[index+2] = val>>16;i2c_command_data[index+3] = val>>24;

#define TX_BUILD_NUM_REQUEST__REQUESTER(val)    SET_BYTE(0,val)
#define TX_BUILD_NUM_REQUEST__BIN_TYPE(val)     SET_SHORT(1,val)
#define TX_BUILD_NUM_REQUEST__BIN_SUBTYPE(val)  SET_SHORT(3,val)
#define SIZE_OF_TX_BUILD_NUM_REQUEST   5

#define TX_BUILD_NUM__BUILD_NUM(val)    SET_INT(0,val)
#define TX_BUILD_NUM__LENGTH(val)       SET_INT(4,val)
#define SIZE_OF_TX_BUILD_NUM            8


#define TX_REQUEST_BLOCK__REQUESTER(val)        TX_BUILD_NUM_REQUEST__REQUESTER(val)
#define TX_REQUEST_BLOCK__BIN_TYPE(val)         TX_BUILD_NUM_REQUEST__BIN_TYPE(val)
#define TX_REQUEST_BLOCK__BIT_SUBTYPE(val)      TX_BUILD_NUM_REQUEST__BIN_SUBTYPE(val)
#define TX_REQUEST_BLOCK__BLOCK_SIZE(val)       SET_INT(5,val)
#define TX_REQUEST_BLOCK__BLOCK_NUMBER(val)     SET_INT(7,val)
#define SIZE_OF_TX_REQUEST_BLOCK                9

#define TX_BLOCK_HEADER__BLOCK_SIZE(val)        SET_SHORT(0,val)
#define TX_BLOCK_HEADER__BLOCK_NUMBER(val)      SET_SHORT(2,val)
#define SIZE_OF_TX_BLOCK_HEADER                 4

#define TX_REQUEST_FINISHED

//#define I2C_TX_BUILD_NUM(val)   tx_buf[0] = val;tx_buf[1] = val>>8;tx_buf[2] = val>>16;tx_buf[3] = val>>24;


#ifndef PDN2
#define PDN2
#endif


void dfu_test();

FLASH_MAP flash_map;
FLASH_MAP_ENTRY flash_map_entry;

#define FLASH_DATA_BASE_ADDRESS 0x40000

void slave_deselect_c();
void slave_select_c();
void reboot(void);

extern spi_master_interface spi_if;

#define XS1_SU_PERIPH_USB_ID 0x1

void reboot()
{
    unsigned data[] = {4};
    write_periph_32(usb_tile, XS1_SU_PERIPH_USB_ID, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 1, data);

/* Ideally we would reset SU1 here but then we loose power to the xcore and therefore the DFU flag */
/* Disable USB and issue reset to xcore only - not analog chip */
    write_node_config_reg(usb_tile, XS1_SU_CFG_RST_MISC_NUM,0b10);

}

unsigned flash_map_entry_flags()
{
    return flash_map_entry.fe.e.flags;
}


#ifdef USE_SPI_MASTER
void configure_spi()
{
    config_spi_ports();
    set_clock_off(spi_if.blk1);
    set_clock_on(spi_if.blk1);
    stop_clock(spi_if.blk1);

    set_clock_off(spi_if.blk2);
    set_clock_on(spi_if.blk2);
    stop_clock(spi_if.blk2);

    //    stop_clock(spi_if.blk2);
    spi_master_init(spi_if, DEFAULT_SPI_CLOCK_DIV);
}

void flash_set_address(unsigned int address,spi_master_interface &spi_if)
{
    configure_spi_c();
//    i.configure_spi();
////    config_spi_ports();
//    spi_master_init(spi_if, 16*DEFAULT_SPI_CLOCK_DIV);

    slave_deselect_c(); // disable flash chip select

    slave_select_c();  // enable flash chip select

    spi_master_out_word(spi_if,(0x03<<24) | address + FLASH_DATA_BASE_ADDRESS);

}



void flash_create_map(spi_master_interface &spi_if)
{
    unsigned int command_address = 4;

    flash_map.count = 0;

    flash_set_address(0,spi_if);
    spi_master_in_buffer(spi_if,(char *) &flash_map.format,sizeof(flash_map.format));


    for(;;) {

        flash_set_address(command_address,spi_if);

        spi_master_in_buffer(spi_if,(char *) &flash_map.entry[flash_map.count],sizeof(FLASH_ENTRY));
        flash_map.entry[flash_map.count].address = command_address + sizeof(FLASH_ENTRY);

        command_address += flash_map.entry[flash_map.count].fe.e.binlength + sizeof(FLASH_ENTRY);

        if (flash_map.entry[flash_map.count++].fe.e.type == 0xff)
            break;
    }
}

#else

signed int flash_cmd_enable_ports(void);

void flash_set_address(unsigned int address)
{
    config_spi_ports_c();

//    flash_cmd_enable_ports();
    flash_cmd_init();

    fl_setAddress(address);

}


void flash_create_map()
{
    unsigned int command_address = 0;

    config_spi_ports_c();

//    flash_cmd_enable_ports();
    flash_cmd_init();

    flash_map.count = 0;



    for(;;) {

        fl_readData(command_address, 16,(char *) &flash_map.entry[flash_map.count]);
        flash_map.entry[flash_map.count].d.address = command_address + sizeof(flash__map.entry);

        command_address += flash_map.entry[flash_map.count].d.binlength + 16;

        if (flash_map.entry[flash_map.count++].d.type == 0xff)
            break;
    }
}

#endif




int flash_find_entry(unsigned int seek_type,unsigned int seek_subtype)
{
    unsigned int i;

    for (i=0;i<flash_map.count;i++)
    {
        if (flash_map.entry[i].fe.e.type != seek_type)
            continue;
        if (flash_map.entry[i].fe.e.subtype != seek_subtype)
            continue;

        flash_map_entry = flash_map.entry[i];
        return 1;
    }
    return 0;
}


unsigned char i2c_command_data[20];

#ifdef TEST_FIRMWARE_UPDATE
unsigned int request_block(int request_block_number,int request_length,client interface kmi_background_if i)
{
        TX_REQUEST_BLOCK__REQUESTER(I2C_ADDRESS_XMOS)
        TX_REQUEST_BLOCK__BIN_TYPE(TEST_FIRMWARE_UPDATE_TYPE)
        TX_REQUEST_BLOCK__BIT_SUBTYPE(TEST_FIRMWARE_UPDATE_SUBTYPE)
        TX_REQUEST_BLOCK__BLOCK_SIZE(REQUEST_BLOCK_SIZE)
        TX_REQUEST_BLOCK__BLOCK_NUMBER(request_block_number)
        i2c_msi_write_reg_buffer(I2C_ADDRESS_XMOS,I2C_MSG_TYPE_CHUNK_REQUEST,i2c_command_data,SIZE_OF_TX_REQUEST_BLOCK,-1);
        i.poke();

        if (request_length > REQUEST_BLOCK_SIZE)
            request_length -= REQUEST_BLOCK_SIZE;
        else
            request_length = 0;

        return request_length;

}
#endif

struct {
    unsigned int expecting_block_data,request_block_number,request_flag;
    unsigned int request_length;
    unsigned char data_buffer[MAX_BLOCK_SIZE];
} srf = {0,0,0};

extern unsigned normal_mode;

unsafe {
int flash_8051_serve(I2C_MSI_EVENT * unsafe event,client interface kmi_background_if i)
{

#ifdef TEST_FIRMWARE_UPDATE

                            if (srf.expecting_block_data)
                            {
//                                printstr("BLOCK_DATA\n");
//                                printhexln(event->count);
                                srf.expecting_block_data = 0;


                                if (srf.request_length)
                                {

                                    srf.request_length = request_block(srf.request_block_number++,srf.request_length,i);

                                } else
                                {
                                    i2c_msi_write_reg_buffer(I2C_ADDRESS_XMOS,I2C_MSG_TYPE_BUILD_QUERY_FINISHED,i2c_command_data,0,-1);
                                    i.poke();
                                }

                            } else

#endif

//                                i2c_8051_fw = &event->buffer[0];
    switch (RX_MESSAGE_TYPE)
    {
        case I2C_MSG_TYPE_QUERY_FINISHED:
            return 1;
            break;

        case I2C_MSG_TYPE_CHUNK_REQUEST:
            normal_mode = 0;
            set_i2s_enabled_wait_c(0);
            port_gpio_c(SHARC_RESET | CODEC_PATH,0);  // holts SHARC in reset, disable codec driver
            srf.request_flag = 1;  // indicate that update process has begun and we should reset when finished

//          printstr("I2C_MSG_TYPE_CHUNK_REQUEST\n");
//          printhexln(RX_REQUEST_BLOCK__REQUESTER);
//          printhexln(RX_REQUEST_BLOCK__BIN_TYPE);
//          printhexln(RX_REQUEST_BLOCK__BIT_SUBTYPE);
//          printhexln(RX_REQUEST_BLOCK__BLOCK_SIZE);
//          printhexln(RX_REQUEST_BLOCK__BLOCK_NUMBER);


            if (RX_REQUEST_BLOCK__BLOCK_SIZE <= MAX_BLOCK_SIZE)
            {
                int sent_length;

                flash_find_entry(RX_REQUEST_BLOCK__BIN_TYPE,RX_REQUEST_BLOCK__BIT_SUBTYPE);

                sent_length = RX_REQUEST_BLOCK__BLOCK_SIZE * RX_REQUEST_BLOCK__BLOCK_NUMBER;
                sent_length = flash_map_entry.fe.e.binlength - sent_length;
                sent_length = sent_length < RX_REQUEST_BLOCK__BLOCK_SIZE ? sent_length : RX_REQUEST_BLOCK__BLOCK_SIZE;

#ifdef USE_SPI_MASTER
                flash_set_address(flash_map_entry.address + RX_REQUEST_BLOCK__BLOCK_SIZE * RX_REQUEST_BLOCK__BLOCK_NUMBER,spi_if);
                spi_master_in_buffer(spi_if,srf.data_buffer,sent_length);
#else
                fl_readData(flash_entry.d.address + RX_REQUEST_BLOCK__BLOCK_SIZE * RX_REQUEST_BLOCK__BLOCK_NUMBER, sent_length, data_buffer);
#endif
                TX_BLOCK_HEADER__BLOCK_SIZE(sent_length)
                TX_BLOCK_HEADER__BLOCK_NUMBER(RX_REQUEST_BLOCK__BLOCK_NUMBER)


                i2c_msi_write_reg_buffer(RX_REQUEST_BLOCK__REQUESTER,I2C_MSG_TYPE_CHUNK_HEADER,i2c_command_data,SIZE_OF_TX_BLOCK_HEADER,-1);
                i2c_msi_write_reg_buffer(RX_REQUEST_BLOCK__REQUESTER,-1,srf.data_buffer,sent_length,-1);
                i.poke();
            }
            break;

        case I2C_MSG_TYPE_BUILDNUM_REQUEST:

//          printstr("I2C_MSG_TYPE_BUILDNUM_REQUEST\n");
//          printhexln(RX_BIN_TYPE);
//          printhexln(RX_BIN_SUBTYPE);
            flash_find_entry(RX_BIN_TYPE,RX_BIN_SUBTYPE);
//          printhexln(flash_entry.d.type);
//          printhexln(flash_entry.d.subtype);
//          printhexln(flash_entry.d.buildnum);
//          printhexln(flash_entry.d.binlength);
            TX_BUILD_NUM__BUILD_NUM(flash_map_entry.fe.e.buildnum);
            TX_BUILD_NUM__LENGTH(flash_map_entry.fe.e.binlength);
            i2c_msi_write_reg_buffer(RX_REQUESTER,I2C_MSG_TYPE_BUILDNUM,i2c_command_data,SIZE_OF_TX_BUILD_NUM,-1);
            i.poke();
            break;
#ifdef TEST_FIRMWARE_UPDATE
        case I2C_MSG_TYPE_BUILDNUM:
//          i2c_8051_fw = (I2C_8051_FW * unsafe) &event->buffer[0];
//          printstr("I2C_MSG_TYPE_BUILDNUM\n");
//          printhexln(RX_BUILD_NUM__BUILD_NUM);
//          printhexln(RX_BUILD_NUM__LENGTH);

            srf.request_length = RX_BUILD_NUM__LENGTH;

            srf.request_block_number = 1;

            srf.request_length = request_block(0,srf.request_length,i);

            break;

        case I2C_MSG_TYPE_CHUNK_HEADER:
//          printstr("I2C_MSG_TYPE_CHUNK_HEADER\n");
//          printhexln(RX_BLOCK_HEADER__SIZE);
//          printhexln(RX_BLOCK_HEADER__NUMBER);
            srf.expecting_block_data = 1;
            break;
#endif
        case I2C_MSG_TYPE_REBOOT:
            //          printstr("I2C_MSG_TYPE_BUILD_QUERY_FINISHED\n");

             reboot();
             break;
        default:
            return 0;
    }

    return 0;
}
}

#ifdef TEST_FIRMWARE_UPDATE
void serve_remote_firmware_test(client interface kmi_background_if i)
{
    unsafe {
        TX_BUILD_NUM_REQUEST__REQUESTER(I2C_ADDRESS_XMOS)
        TX_BUILD_NUM_REQUEST__BIN_TYPE(TEST_FIRMWARE_UPDATE_TYPE)
        TX_BUILD_NUM_REQUEST__BIN_SUBTYPE(TEST_FIRMWARE_UPDATE_SUBTYPE)
        i2c_msi_write_reg_buffer(I2C_ADDRESS_XMOS,I2C_MSG_TYPE_BUILDNUM_REQUEST,(char *) i2c_command_data,SIZE_OF_TX_BUILD_NUM_REQUEST,-1);
        i.poke();
    }
}
#endif

void serve_remote_firmware_update(client interface kmi_background_if i,chanend chan_i2c_client)
{
    unsigned char tmp;

    timer srfu_timer;
    unsigned srfu_time;

#if 0
    srfu_timer :> srfu_time;
    srfu_time += 200000000;  // wait for update commands from 8051
#else
    srfu_time = 0;
#endif


#ifdef USE_SPI_MASTER
//    flash_create_map(spi_if);
#else
//    flash_create_map();
#endif

    i.set_i2c_address(I2C_ADDRESS_XMOS);


    i2c_msi_write_reg_word(I2C_ADDRESS_8051U, I2C_MSG_TYPE_READY,0,-1);
     i.poke();


    for(;;)
    {
        select {

            case srfu_time => srfu_timer when timerafter(srfu_time):>void:

#ifdef TEST_FIRMWARE_UPDATE
                serve_remote_firmware_test(i);
            break;
#else
                return;  // We have time out waiting for firmware queiry
#endif

            case inct_byref (chan_i2c_client, tmp ): // receive notification

                srfu_time = 0;  // cancel the timeout

             unsafe{
                for(;;)
                {
                    I2C_MSI_EVENT * unsafe event = slave_event_buffer_pop();
                    if (!event)
                        break;

                    switch(event->type)
                    {
                        case SLAVE_EVENT_RX:

                                if (flash_8051_serve(event,i))
                                    return;
                                break;
                    }
                }
                break;
        }
    }
}
}
