#include <xs1.h>
#include <print.h>
#include "customdefines.h"
#include "kmi_mixer.h"
#include "oscillator.h"
#include "ports.h"
#include "i2c_app.h"
#include "utils.h"
#include "sharc.h"
//#include "i2c.h"
#include "i2c_msi.h"
#ifdef XSCOPE
#include "xscope.h"
#include "xscope_user.h"
#endif
#include "cutils.h"
#include "flash_data.h"
#include "kmi_audio.h"

void slave_select(){P_SPI_SS <: 0;}
void slave_deselect(){P_SPI_SS <: 1;}
void slave_select_c();
void slave_deselect_c();

void slave_select_debug_c();

MISC misc;

void slave_select_debug()
{
    P_SPI_SS :> void;

}

int debug_count_stop = 0;

void debug_i2c_test(client interface kmi_background_if i)
{
    int x;

    init_debug_count_stop_c();


    for (x=0;x<40;x++)
    {
        int flag = i2c_msi_write_reg_word(I2C_ADDRESS_8051U, I2C_MSG_TYPE_MIDI_TO_8051,x,-1);

        if (!flag)
        {
            i.poke();
            while(!i2c_msi_write_reg_word(I2C_ADDRESS_8051U, I2C_MSG_TYPE_MIDI_TO_8051,x,-1));

        }
    }
    i.poke();

    for(;;);

}

void dfu_debug_msg(unsigned val1,unsigned val2)
{
//    i2c_msi_write_reg_word(I2C_MIDI_DESTINATION,123,val1<<16 | val2,I2C_TX_INTERFACE_1);
//    while (!i2c_queue_empty());
}

#ifdef USE_SPI_MASTER
extern spi_master_interface spi_if;
#endif

int DFUReportResetState(chanend ?c_user_cmd);
extern unsigned  DFU_mode_active;
extern int DFU_reset_override;

void kmi_init(client interface kmi_background_if i,chanend chan_i2c_client){


#ifdef XSCOPE_DEBUG_I2C
    xscope_int(XSCOPE_USER_PROGRESS,2);
#endif


#ifdef MASTER_XMOS
    p_spi_misc :> int _; // make sure this is an input port
#else
    p_sync :> void;  // make input port so won't interfere with booting
    p_sync2 :> void;
#endif


 //    test_i2c_lines();
    internal_oscillator_switch_to();
//    internal_oscillator_shut_off();

#ifndef XSCOPE_MODE_1_BUG
    printstr("oscillator source is: ");
    if (oscillator_source())
        printstr("internal\n");
    else
        printstr("external\n");
#endif


    if (!init_clock(DEFAULT_OSC_REGS,0,187,i))
        printstr("unable to init clock chip\n");
    else
        external_oscillator_switch_to();

#ifndef XSCOPE_MODE_1_BUG
    printstr("oscillator source is: ");
    if (oscillator_source())
        printstr("internal\n");
    else
        printstr("external\n");
#endif

//    debug_i2c_test(i);

//    dfu_debug_msg(1,2);

    //#ifdef UNUSED

    i.port_gpio( CODEC_PATH | SPI_PATH_1  | SPI_PATH_3,SPI_PATH_2);

    i.port_gpio(SHARC_RESET , 0);

    flash_create_map(spi_if);

#ifdef DO_FIRMWARE_CHECK_ON_STARTUP

    if (DFU_reset_override != 0x11042011)  // qqq
    {
#ifndef DEV_VERSION
        printstr("serve_remote_firmware_update");
        serve_remote_firmware_update(i,chan_i2c_client);
#endif
    }



#endif


//#ifdef SHARC_ENABLED
//    wait_xc(100000000);
//    i.port_gpio(0,CODEC_ADC_PDN);
//    init_codecs(DEFAULT_FREQ,i);

    sharc_master_boot(i);

//    deliver_tdm_i2s2(30000);

//    sharc_master_boot(i);


//    i.port_gpio(0,CODEC_ADC_PDN);
//    init_codecs(DEFAULT_FREQ,i);
//    deliver_tdm_i2s2(3000);


//    for(;;);

//#else
//    i.port_gpio(SHARC_RESET , CODEC_PATH);  // holts SHARC in reset, connect directly to codecs
//#endif

//    speed_check();
#ifdef XSCOPE_DEBUG_I2C
    xscope_int(XSCOPE_USER_PROGRESS,3);
#endif

#ifdef DO_NOTHING
    printstr("Doing nothing...");
    printstr("because there is nothing to do");
    for(;;);

#endif

//    i.port_gpio(ADC_PDN | CODEC_PDN | CODEC_PATH | SHARC_RESET ,SPI_PATH_2);

//    dfu_test();

//    for(;;);

//    timer t;
//    unsigned time;
//    t:>time;
//    t when timerafter(time+50000000) :> void;


}
//asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
//asm("stw %0, %1[%2]"::"r"(sample),"r"(adc_buffer_address),"r"(i));

void i2c_slave_read_prepare(unsigned int index)
{
    timer t;
    unsigned int time;

    t :> time;
//    t when timerafter(time + 200000) :> void;
    t when timerafter(time + 0) :> void;
}

int i2c_slave_read_data(unsigned int index)
{
//    return index + 7;
    return 0x018;
}

extern void stop_here();


#define BLINK_LEDS

void kmi_background(server interface kmi_background_if i[2],chanend chan_i2c_client[NLINK],chanend chan_i2c_server[NLINK],unsigned NLINK,int i2c_address_slave){
    unsigned char tmp;
    unsigned boot_debug_time = 0;
    timer boot_debug_timer;
//    unsigned int dfu_debug;
//    unsigned int c_mix_out_data;

#ifdef BLINK_LEDS
    int led_state=0;
    timer t;
    unsigned int led_time1,led_time2;
#endif

#ifdef XSCOPE_DEBUG_I2C
    xscope_int(XSCOPE_USER_PROGRESS,1);
#endif

    set_port_a32(SHARC_RESET | CODEC_ADC_PDN | ADC_MASK(DEFAULT_FREQ) | SPI_PATH_3 | CODEC_PATH,  ADC_ORVAL(DEFAULT_FREQ)  );

//    i2c_msi_init(I2C_ADDRESS_XMOS);
    i2c_msi_init(0xff);

//    configure_in_port(p_4c,clk_audio_bclk);

#ifdef BLINK_LEDS
    t :> led_time1;
#endif


    for(;;)
    {

        if (i2c_msi_bus_free())
        {
#ifdef XSCOPE_DEBUG_MIDI
//                xscope_int(XSCOPE_SERVE_MIDI_FROM_HOST,12);
#endif
            i2c_tx_queue_check(chan_i2c_client,chan_i2c_server,NLINK);

 #pragma ordered
            select
            {

#ifdef UNUSED
                case inuint_byref(chan_dfu_debug, dfu_debug):
//        i2c_msi_write_reg_word(dfu_debug,0,5,0);

          while(dfu_debug--)
          {
              set_port_a32(TEST_POINT2,0);
              set_port_a32(0,TEST_POINT2);

          }
                outuint(chan_dfu_debug,0);
                     break;
#endif

                case inct_byref (chan_i2c_server[int i], tmp ): // receive notification
#ifdef XSCOPE_DEBUG_MIDI
                xscope_int(XSCOPE_SERVE_MIDI_FROM_HOST,10);
#endif
//                        while (testct(chan_i2c_server[i]))
                        {
#ifdef XSCOPE_DEBUG_MIDI
//                xscope_int(XSCOPE_SERVE_MIDI_FROM_HOST,11);
#endif
//                            inct(chan_i2c_server[i]);
                        }
                     break;

                case i[int i].port_gpio(int mask, int orval):
                     set_port_a32(mask,orval);
                     break;
                case i[int i].set_i2c_address(int address):
                        i2c_msi_set_address(address);
                     break;

#ifdef DEBUG_SHARC_BOOT
                case i[int i].boot_debug():
                        boot_debug_timer :> boot_debug_time;
                        boot_debug_time += 100000000;
                        break;

                case boot_debug_time => boot_debug_timer when timerafter(boot_debug_time) :> boot_debug_time:
                    boot_debug_time = 0;
                i2c_msi_write_reg_word(I2C_ADDRESS_SHARC,0x0F,0x0001B880,-1);
                    break;
#endif


#ifdef unused
                case i[int i].port_gpio_read(void) -> unsigned  return_val:

                    return_val = peek(p_32a);

                     break;
#endif

#ifdef BLINK_LEDS
                case t when timerafter(led_time1) :> led_time2 :
                     led_state ^=LED1;
                    if (led_state)
                        set_port_a32(LED1,0);
                    else
                        set_port_a32(0,LED1);

                    led_time1 +=(unsigned int) 5E7;

                     break;
#endif
                case i[int i].poke():
                        stop_here();
                        break;
#ifdef I2C_SQUARE_WAVE
                case i.square_wave():
                        i2c_square_wave(400);
                    break;
#endif
                case i2c_msi_start_select(chan_i2c_client,chan_i2c_server,NLINK);
             }
         } else
         {
         }

    }
}



void sync_i2s_xc()
{
    set_port_a32(0,I2S_SYNC);

}
void wait_xc(unsigned wait_time)
{
    timer t;
    unsigned time;
    t :> time;
    t when timerafter(time+wait_time) :> void;
}


#ifdef UNUSED
void dfu_debug_toggle(chanend chan_dfu_debug,int count)
{
//#ifdef XSCOPE_DEBUG_DFU
//    xscope_int(XSCOPE_DFU_PROGRESS,count);
//#endif
    outuint(chan_dfu_debug,count);
    inuint(chan_dfu_debug);
}
#endif

