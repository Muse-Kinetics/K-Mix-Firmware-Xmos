#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include "kmi_mixer.h"
#include "ports.h"
#include "spi_master.h"
#include "utils.h"
#include "flash_data.h"
#include "cutils.h"
#include "flash.h"


#ifdef USE_SPI_MASTER
extern spi_master_interface spi_if;
#endif

void stop_here();

#ifdef UNUSED

unsigned int flash_debug_data[256];

void flash_debug_read(spi_master_interface &spi_if)
{
    unsigned int command_address = 0x40000;
    int i;

    slave_deselect_c(); // disable flash chip select

    slave_select_c();  // enable flash chip select

    spi_master_out_word(spi_if,(0x03<<24) | command_address);


        for (i=0;i<256;i++)
            flash_debug_data[i] = spi_master_in_word(spi_if);
        stop_here();
    for(;;);
}

int DFU_Dnload_Data(unsigned int request_len, unsigned int block_num, unsigned int request_data[16], chanend ?c_user_cmd);
void dfu_debug_init();

void flash_debug_write(spi_master_interface &spi_if)
{
    unsigned int block_num,request_data[16],inc_val=0,i;

    dfu_debug_init();


    for (block_num = 0;block_num < 8;block_num++)
    {
        for (i=0;i<16;i++)
            request_data[i] = inc_val++;

        DFU_Dnload_Data(16,block_num, request_data,null);

    }

    for(;;);
}
#endif


void slave_deselect_c();
void slave_select();
void reset_spi_clock_pin_c();

//spi_master_interface spi_if =
//{
//        CLKBLK_SPI_1,
//        CLKBLK_SPI_2,
//        XS1_PORT_1D,  // MOSI
//        XS1_PORT_1C,    // Clock
//        XS1_PORT_1A     // MISO
//};

#define BOOT_CLOCK             CLKBLK_SPI_1
#define BOOT_DATA_IN_PORT    XS1_PORT_1A
#define BOOT_CLOCK_PORT      XS1_PORT_1C


void spi_slave_init2(spi_master_interface &spi_if)
{
    int clk_start;
//    set_clock_on(spi_if.blk);
    set_clock_on(spi_if.blk1);
//    set_port_use_on(spi_if.ss);
//    set_port_use_on(spi_if.mosi);
    set_port_use_on(spi_if.miso);
    set_port_use_on(spi_if.sclk);
#if SPI_SLAVE_MODE == 0
    set_port_no_inv(spi_if.sclk);
    clk_start = 0;
#elif SPI_SLAVE_MODE == 1
    set_port_inv(spi_if.sclk); // invert clk signal
    clk_start = 1;
#elif SPI_SLAVE_MODE == 2
    set_port_inv(spi_if.sclk); // invert clk signal
    clk_start = 0;
#elif SPI_SLAVE_MODE == 3
    set_port_no_inv(spi_if.sclk);
    clk_start = 1;
#else
    #error "Unrecognised SPI mode."
#endif
    // configure ports and clock blocks
    // note: SS port is inverted, assertion is port value 1 (pin value 0 - slave active low)
//    configure_clock_src(spi_if.blk, spi_if.sclk);
    configure_clock_src(spi_if.blk1, spi_if.sclk);
//    configure_in_port(spi_if.mosi, spi_if.blk);
    configure_in_port(spi_if.miso, spi_if.blk1);
//    configure_out_port(spi_if.miso, spi_if.blk, 0);
//    set_clock_ready_src(spi_if.blk, spi_if.ss);
//    set_port_inv(spi_if.ss); // spi_if.blk ready-in signalled when SS pin is 0
//    set_port_strobed(spi_if.mosi);
    set_port_strobed(spi_if.miso);
//    set_port_slave(spi_if.mosi);
    set_port_slave(spi_if.miso);
    start_clock(spi_if.blk1);
//    spi_if.ss when pinseq(0) :> void;
//    spi_if.sclk when pinseq(clk_start) :> void;
    clearbuf(spi_if.miso);
    clearbuf(spi_if.mosi);
}


unsigned sharc_boot_start(unsigned samplerate)
{

//    set_i2s_enabled_c(0);

//    t :> time;
//    t when timerafter(time + 100000000) :> void;  // all waiting should be done outside the start, otherwise will delay serving other events


    port_gpio_c(SHARC_RESET | CODEC_PATH | SPI_PATH_1  | SPI_PATH_3,SPI_PATH_2);

//    port_gpio_c(SHARC_RESET , 0);

    slave_deselect_c(); // Ensure slave select is in correct start state


#ifdef USE_SPI_MASTER
//    flash_create_map(spi_if);
    flash_find_entry(0,samplerate);
    if (!flash_map_entry.address)
        return 0;
    flash_set_address(flash_map_entry.address,spi_if);
//    for(;;);
#else
//    flash_create_map();
    flash_find_entry(0,samplerate);
    if (!flash_entry.d.address)
        return 0;
    fl_setAddress(flash_entry.d.address);
    for(;;);
//    fl_readData(flash_entry.d.address, 0,(char *) 0);
#endif

#ifndef NO_SPI_PATH_3
//    i.port_gpio(0,SPI_PATH_3);
    port_gpio_c(0,SPI_PATH_3);

#endif


    reset_spi_clock_pin_c();

//    for(;;);

    //    return 0;



//    cs_state_last = i.port_gpio_read()  & SH_SPI_CS;

    wait_xc(1000000);

    port_gpio_c(TEST_POINT1,SHARC_RESET);


    return flash_map_entry.fe.e.binlength;

}


signed int flash_cmd_disable_ports(void);


//struct {unsigned bootlength, bootrequests;} misc;


void sharc_boot_wait(unsigned binlength)
{
    unsigned miso_word,time_start,time_end;
    timer t;

    misc.binlength = binlength/4;
    misc.bootrequests = 0;
    misc.bootcounts = 0;

//    spi_slave_init2(spi_if);


    t :> time_start;

    unsigned sample_time,done=0;


#if 1

    do
    {
        unsigned state_old;

        t :> sample_time;
        t when timerafter(sample_time + 100000) :> sample_time;

        P_SPI_SCK :> state_old;

        select
        {
            case P_SPI_SCK when pinsneq(state_old) :> void:
                misc.bootcounts++;
                done = 0;
                    break;
//            case P_SPI_MISO :> miso_word:
//                done = 0;
//                break;
            case t when timerafter(sample_time+1000000):> sample_time:
                    done = 1;
                break;
        }
    } while (!done);

#else

//    misc.binlength+=5;

    while(misc.binlength--)
        P_SPI_MISO :> miso_word;

//    for(;;)
//    {
//        P_SPI_MISO :> miso_word;
//        misc.bootrequests++;
//        misc.binlength--;
//    }


#endif

//    for(;;);

    t :> time_end;

#ifndef NO_SPI_PATH_3
    port_gpio_c(SPI_PATH_3,TEST_POINT1);
#endif

//    printstr("sharc image size: ");
//    printint(binlength);
//    printstr(" bytes\n");


//    printstr("sharc boot time: ");
//    printuint((time_end-time_start)/1E5);
//    printstr(" ms\n");

    misc.binlength = binlength;
    misc.boot_time = (time_end-time_start)/1E5;

    wait_xc(30000000);

    slave_deselect_c(); // disable flash chip select

#ifdef USE_SPI_MASTER
    spi_master_shutdown(spi_if);
#else
    flash_cmd_disable_ports();
#endif

}


void sharc_master_boot(client interface kmi_background_if i)
{

    i.set_i2c_address(-1);


    unsigned binlength = sharc_boot_start_c(DEFAULT_FREQ) / 4;

    if (binlength)
        sharc_boot_wait_c(binlength);




//    for(;;);

}
