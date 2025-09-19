
#include <xs1.h>
#include <print.h>
#include <xscope.h>
#include "xscope_user.h"

#include "devicedefines.h"
#ifdef MIDI
#include "usb_midi.h"
#endif
#ifdef IAP
#include "iap.h"
#endif
#include "xc_ptr.h"
#include "commands.h"
#include "xud.h"
#include "testct_byref.h"

#include "sharc.h"

#ifdef KMI
#include "kmi_mixer.h"
#include "i2c_app.h"
#include "interrupt.h"
#include "ports.h"
#include "cutils.h"
#include "flash_data.h"
#endif

#ifdef HID_CONTROLS
#include "user_hid.h"
unsigned char g_hidData[1] = {0};
#endif

void GetADCCounts(unsigned samFreq, int &min, int &mid, int &max);
#define BUFFER_SIZE_OUT       (1028 >> 2)
#define BUFFER_SIZE_IN        (1028 >> 2)

/* Packet nuffers for audio data */

extern unsigned int g_curSamFreqMultiplier;

#ifdef CHAN_BUFF_CTRL
#define SET_SHARED_GLOBAL0(x,y) SET_SHARED_GLOBAL(x,y); outuchar(c_buff_ctrl, 0);
#else
#define SET_SHARED_GLOBAL0(x,y) SET_SHARED_GLOBAL(x,y)
#endif


/* Global var for speed.  Related to feedback. Used by input stream to determine IN packet size */
unsigned g_speed;
unsigned g_freqChange = 0;

/* Interrupt EP data */
unsigned char g_intData[8];

#if defined (MIDI) || defined(IAP)
static inline void swap(xc_ptr &a, xc_ptr &b)
{
  xc_ptr tmp;
  tmp = a;
  a = b;
  b = tmp;
  return;
}
#endif

#ifdef MIDI
static unsigned int g_midi_to_host_buffer_A[MIDI_USB_BUFFER_TO_HOST_SIZE/4];
static unsigned int g_midi_to_host_buffer_B[MIDI_USB_BUFFER_TO_HOST_SIZE/4];
static unsigned int g_midi_from_host_buffer[MAX_USB_MIDI_PACKET_SIZE/4];
#endif

#ifdef IAP
unsigned char  gc_zero_buffer[4];
#endif

unsigned char fb_clocks[16];

//#define FB_TOLERANCE_TEST
#define FB_TOLERANCE 0x100

//extern unsigned inZeroBuff[];

extern int debug_buffer[256];
extern unsigned char debug_index;

int midi_data_remaining_to_device = 0;
xc_ptr midi_from_host_rdptr;

unsigned int last_midi_rx=0,deferred_midi_from_host = 0;

void debug_me()
{

}

struct {unsigned enabled,count;} midi_debug = {0,0};



void serve_midi_from_host(chanend chan_i2c_server,XUD_ep &ep_midi_from_host,xc_ptr &midi_from_host_buffer)
{
    unsigned int datum;
    int notify_count=0;;

//    if (midi_data_remaining_to_device==92)
//        outct(chan_i2c_server,XS1_CT_END);


    for(;;)
    {

#ifdef UNUSED
        if (deferred_midi_from_host)
        {
            if (i2c_msi_write_reg_word(I2C_MIDI_DESTINATION,I2C_MSG_TYPE_MIDI_TO_8051,deferred_midi_from_host,I2C_TX_INTERFACE_1) >= 0)
            {
#ifdef XSCOPE_DEBUG_MIDI
                xscope_int(XSCOPE_MIDI_TX_BYTE,deferred_midi_from_host);
#endif
                notify_count++;
                deferred_midi_from_host = 0;

                midi_from_host_rdptr += 4;
                midi_data_remaining_to_device -= 4;
            } else
            {
                if (notify_count)
                    outct(chan_i2c_server,XS1_CT_END);

                return;
            }
        }
#endif

        if (midi_data_remaining_to_device>0)
        {
            read_via_xc_ptr(datum, midi_from_host_rdptr);

#ifdef XSCOPE_DEBUG_MIDI
                xscope_int(XSCOPE_MIDI_TX_BYTE,datum);
#endif
            if (midi_debug.enabled)
                datum = midi_debug.count;

            if (i2c_msi_write_reg_word(I2C_MIDI_DESTINATION,I2C_MSG_TYPE_MIDI_TO_8051,datum,I2C_TX_INTERFACE_1))
            {
                midi_debug.count++;
                notify_count++;
                midi_from_host_rdptr += 4;
                midi_data_remaining_to_device -= 4;
            }
            else
            {
                if (notify_count)
                    outct(chan_i2c_server,XS1_CT_END);

                deferred_midi_from_host = datum;
                return;
            }
        } else
        {
            int reset = XUD_SetReady_OutPtr(ep_midi_from_host, midi_from_host_buffer);

                if (notify_count)
                    outct(chan_i2c_server,XS1_CT_END);

            return;
        }
    }

}



void set_audio_dfu_mode(unsigned mode)
{
    SET_SHARED_GLOBAL(g_freqChange_sampFreq,mode);  /* Set Flag */
    SET_SHARED_GLOBAL(g_freqChange, SET_SAMPLE_FREQ);                /* Set command */
    SET_SHARED_GLOBAL(g_freqChange_flag, SET_SAMPLE_FREQ);                /* Set command */
}

void wait_for_dfu_mode_change()
{
    unsigned int freqChange;
    do
    {
    GET_SHARED_GLOBAL(freqChange, g_freqChange);
    } while(freqChange);

}
extern unsigned i2s_enabled;

void set_i2s_enabled(unsigned state)
{
#if 0
    unsigned tmp;

    if (state)
        SET_SHARED_GLOBAL(g_powerChange_flag,AUDIO_START_FROM_DFU);
    else
        SET_SHARED_GLOBAL(g_powerChange_flag,AUDIO_STOP_FOR_DFU);

    do {
        GET_SHARED_GLOBAL(tmp,g_powerChange_flag);
    } while (tmp);

#else
    i2s_enabled = state;
#endif
}
void power_change_low()
{
    set_i2s_enabled_c(0);
}
void power_change_high()
{
//    unsigned sampFreq;


    set_i2s_enabled_c(0);

//    GET_SHARED_GLOBAL(sampFreq,g_curSamFreq);

//    SET_SHARED_GLOBAL(g_powerChange_flag,sampFreq);

//    outuint(c_meta_ctl,sampFreq);

}

unsigned power_test_state,power_test_time;
timer timer_power;

void set_power_test_state(unsigned state,unsigned time)
{
    timer_power :> power_test_time;
    power_test_time += time;
    power_test_state = state;
}
unsigned reboot_debug=0;

unsigned sofCount = 0;
unsigned clocks = 0;
unsigned remnant = 0,cycles;

void sync_feedback()
{
    sofCount = 0;
    clocks = 0;
    remnant = 0;

}


#ifdef KMI
struct {unsigned count,data[16];} debug2;
#endif

void reboot(void);

unsigned normal_mode = 1;
extern unsigned  DFU_mode_active;

void dfu_debug_put_c(int val);
/**
 * Buffers data from audio endpoints
 * @param   c_aud_out     chanend for audio from xud
 * @param   c_aud_in      chanend for audio to xud
 * @param   c_aud_fb      chanend for feeback to xud
 * @return  void
 */
void buffer(register chanend c_aud_out, register chanend c_aud_in, chanend c_aud_fb,
#ifdef MIDI
            chanend c_midi_from_host,
            chanend c_midi_to_host,
#ifndef KMI
            chanend c_midi,
#endif
#endif
#ifdef IAP
            chanend c_iap_from_host,
            chanend c_iap_to_host,
#ifdef IAP_INT_EP
            chanend c_iap_to_host_int,
#endif
            chanend c_iap,
#endif
#if defined(SPDIF_RX) || defined(ADAT_RX)
            chanend ?c_int,
#endif
            chanend c_sof,
            chanend c_audioControl,
            in port p_off_mclk
#ifdef HID_CONTROLS
            , chanend c_hid
#endif
#ifdef CHAN_BUFF_CTRL
            , chanend c_buff_ctrl
#endif
#ifdef KMI
            ,chanend chan_i2c_client
             ,chanend chan_i2c_server
             ,client interface kmi_background_if i
//             ,chanend c_meta_ctl
#endif
            )
{
    XUD_ep ep_aud_out = XUD_InitEp(c_aud_out);
    XUD_ep ep_aud_in = XUD_InitEp(c_aud_in);
    XUD_ep ep_aud_fb = XUD_InitEp(c_aud_fb);
#ifdef MIDI
    XUD_ep ep_midi_from_host = XUD_InitEp(c_midi_from_host);
    XUD_ep ep_midi_to_host = XUD_InitEp(c_midi_to_host);
#endif
#ifdef IAP
    XUD_ep ep_iap_from_host   = XUD_InitEp(c_iap_from_host);
    XUD_ep ep_iap_to_host     = XUD_InitEp(c_iap_to_host);
#ifdef IAP_INT_EP
    XUD_ep ep_iap_to_host_int = XUD_InitEp(c_iap_to_host_int);
#endif
#endif
#if defined(SPDIF_RX) || defined(ADAT_RX)
    XUD_ep ep_int = XUD_InitEp(c_int);
#endif

#ifdef HID_CONTROLS
    XUD_ep ep_hid = XUD_InitEp(c_hid);
#endif
#ifdef KMI
    unsigned char tmp;
#endif
    unsigned u_tmp;
    unsigned sampleFreq = 0;
    unsigned lastClock;


#if (NUM_USB_CHAN_IN > 0)
    unsigned bufferIn = 1;
#endif
    unsigned freqChange = 0;

#ifdef FB_TOLERANCE_TEST
    unsigned expected_fb = 0;
#endif

    xc_ptr aud_from_host_buffer = 0;



#ifdef MIDI
    xc_ptr midi_from_host_buffer = array_to_xc_ptr(g_midi_from_host_buffer);

    xc_ptr midi_to_host_buffer_being_sent = array_to_xc_ptr(g_midi_to_host_buffer_A);
    xc_ptr midi_to_host_buffer_being_collected = array_to_xc_ptr(g_midi_to_host_buffer_B);

//    int is_ack;
//    unsigned int datum;
    int midi_data_collected_from_device = 0;
    int midi_waiting_on_send_to_host = 0;
#endif

#ifdef IAP
    xc_ptr iap_from_host_rdptr;
    unsigned char iap_from_host_buffer[IAP_MAX_PACKET_SIZE+4];
    unsigned char iap_to_host_buffer[IAP_MAX_PACKET_SIZE];

    int is_ack_iap;
    int is_reset;
    unsigned int datum_iap;
    int iap_data_remaining_to_device = 0;
    int iap_data_collected_from_device = 0;
    int iap_expected_data_length = 0;
    int iap_draining_chan = 0;
#endif

#if defined(SPDIF_RX) || defined(ADAT_RX)
    asm("stw %0, dp[int_usb_ep]"::"r"(ep_int));
#endif
    /* Store EP's to globals so that decouple() can access them */
    asm("stw %0, dp[aud_from_host_usb_ep]"::"r"(ep_aud_out));
    asm("stw %0, dp[aud_to_host_usb_ep]"::"r"(ep_aud_in));
    asm("stw %0, dp[buffer_c_audioControl]"::"r"(c_audioControl));

#ifdef FB_TOLERANCE_TEST
    expected_fb = ((DEFAULT_FREQ * 0x2000) / 1000);
#endif

#if (NUM_USB_CHAN_OUT > 0)
    SET_SHARED_GLOBAL(g_aud_from_host_flag, 1);
#endif

#if (NUM_USB_CHAN_IN > 0)
    SET_SHARED_GLOBAL(g_aud_to_host_flag, 1);
#endif

    (fb_clocks, unsigned[])[0] = 0;

    /* Mark OUT endpoints ready to receive data from host */
#ifdef MIDI
    XUD_SetReady_OutPtr(ep_midi_from_host, midi_from_host_buffer);
#endif

#ifdef IAP
    XUD_SetReady_Out(ep_iap_from_host, iap_from_host_buffer);
#endif

#ifdef HID_CONTROLS
    XUD_SetReady_In(ep_hid, g_hidData, 1);
#endif

    i.set_i2c_address(I2C_ADDRESS_XMOS);


//#define POWER_CYCLE_LOW_HIGH_TIME   4*SEC

//    set_power_test_state(KS_ANNOUNCE_READY,1*SEC);
#ifdef POWER_CYCLE_LOW_HIGH_TIME
    set_power_test_state(KS_TEST_LOW_START,POWER_CYCLE_LOW_HIGH_TIME);
    //    set_power_test_state(KS_TEST_HIGH_START,POWER_CYCLE_LOW_HIGH_TIME);
#else
    power_test_time = 0;

#ifdef  TEST_FIRMWARE_UPDATE
    set_power_test_state(KS_TEST_FW_UPDATE,2*SEC);
#endif
#endif

    while(1)
    {
        XUD_Result_t result;
        unsigned length;

        /* Wait for response from XUD and service relevant EP */

#pragma ordered
        {
        select
        {
#if defined(SPDIF_RX) || defined(ADAT_RX)
            /* Interrupt EP, send back interrupt data.  Note, request made from decouple */
            case XUD_SetData_Select(c_int, ep_int, result):
            {
                int sent_ok = 0;
                asm("stw   %0, dp[g_intFlag]" :: "r" (0)  );
                break;
            }
#endif
            /* Sample Freq or chan count update from Endpoint 0 core */
            case normal_mode => testct_byref(c_audioControl, u_tmp):
            {
                if (u_tmp)
                {
                   // is a control token sent by reboot_device
                   inct(c_audioControl);
                   outct(c_audioControl, XS1_CT_END);
                   while(1) {};
                }
                else
                {
                    unsigned cmd = inuint(c_audioControl);

                    if(cmd == SET_SAMPLE_FREQ)
                    {
                        sampleFreq = inuint(c_audioControl);

                        /* Don't update things for DFU command.. */
                        if(sampleFreq != AUDIO_STOP_FOR_DFU)
                        {
   #ifdef FB_TOLERANCE_TEST
                            expected_fb = ((sampleFreq * 0x2000) / frameTime);
   #endif
                            /* Reset FB */
                            /* Note, Endpoint 0 will hold off host for a sufficient period to allow our feedback
                             * to stabilise (i.e. sofCount == 128 to fire) */

                            sync_feedback_c();

                        }
                        /* Ideally we want to wait for handshake (and pass back up) here.  But we cannot keep this
                        * core locked, it must stay responsive to packets (MIDI etc) and SOFs.  So, set a flag and check for
                        * handshake elsewhere */
                        dfu_debug_put_c(32);
                        dfu_debug_put_c(sampleFreq);

                        SET_SHARED_GLOBAL(g_freqChange_sampFreq, sampleFreq);
                    }
                    else if(cmd == SET_STREAM_FORMAT_IN)
                    {
                        unsigned formatChange_DataFormat = inuint(c_audioControl);
                        unsigned formatChange_NumChans = inuint(c_audioControl);
                        unsigned formatChange_SubSlot = inuint(c_audioControl);
                        unsigned formatChange_SampRes = inuint(c_audioControl);

                        SET_SHARED_GLOBAL(g_formatChange_NumChans, formatChange_NumChans);
                        SET_SHARED_GLOBAL(g_formatChange_SubSlot, formatChange_SubSlot);
                        SET_SHARED_GLOBAL(g_formatChange_DataFormat, formatChange_DataFormat);
                        SET_SHARED_GLOBAL(g_formatChange_SampRes, formatChange_SampRes);
                    }
                    else if (cmd == SET_STREAM_FORMAT_OUT)
                    {
                        XUD_BusSpeed_t busSpeed;
                        unsigned formatChange_DataFormat = inuint(c_audioControl);
                        unsigned formatChange_NumChans = inuint(c_audioControl);
                        unsigned formatChange_SubSlot = inuint(c_audioControl);
                        unsigned formatChange_SampRes = inuint(c_audioControl);

                        SET_SHARED_GLOBAL(g_formatChange_NumChans, formatChange_NumChans);
                        SET_SHARED_GLOBAL(g_formatChange_SubSlot, formatChange_SubSlot);
                        SET_SHARED_GLOBAL(g_formatChange_DataFormat, formatChange_DataFormat);
                        SET_SHARED_GLOBAL(g_formatChange_SampRes, formatChange_SampRes);

                        /* Host is starting up the output stream. Setup (or potentially resize) feedback packet based on bus-speed
                         * This is only really important on inital start up (when bus-speed
                           was unknown) and when changing bus-speeds */
                        GET_SHARED_GLOBAL(busSpeed, g_curUsbSpeed);

                        if (busSpeed == XUD_SPEED_HS)
                        {
                            XUD_SetReady_In(ep_aud_fb, fb_clocks, 4);
                        }
                        else
                        {
                            XUD_SetReady_In(ep_aud_fb, fb_clocks, 3);
                        }

                    }
                    /* Pass on sample freq change to decouple() via global flag (saves a chanend) */
                    /* Note: freqChange flags now used to communicate other commands also */
                    SET_SHARED_GLOBAL0(g_freqChange, cmd);                /* Set command */
                    SET_SHARED_GLOBAL(g_freqChange_flag, cmd);  /* Set Flag */
                }
                break;
            }

            #define MASK_16_13            (7)   /* Bits that should not be transmitted as part of feedback */
            #define MASK_16_10            (127) /* For Audio 1.0 we use a mask 1 bit longer than expected to avoid Windows LSB issues */
                                                /* (previously used 63 instead of 127) */

            /* SOF notifcation from XUD_Manager() */
            case inuint_byref(c_sof, u_tmp):

//PACKET_SIZE_BUG_96KHZ   SOF notification

                /* NOTE our feedback will be wrong for a couple of SOF's after a SF change due to
                 * lastClock being incorrect */

                /* Get MCLK count */
                asm (" getts %0, res[%1]" : "=r" (u_tmp) : "r" (p_off_mclk));

                GET_SHARED_GLOBAL(freqChange, g_freqChange);
                if(freqChange == SET_SAMPLE_FREQ)
                {
                    /* Keep getting MCLK counts */
                    lastClock = u_tmp;
                }
                else
                {
                    unsigned mask = MASK_16_13, usb_speed;

                    GET_SHARED_GLOBAL(usb_speed, g_curUsbSpeed);

                    if(usb_speed != XUD_SPEED_HS)
                        mask = MASK_16_10;

                    /* Number of MCLKS this SOF, approx 125 * 24 (3000), sample by sample rate */
                    GET_SHARED_GLOBAL(cycles, g_curSamFreqMultiplier);


//                    debug_buffer[debug_index++] = cycles;
//                    debug_buffer[debug_index++] = u_tmp;

                    cycles = ((int)((short)(u_tmp - lastClock))) * cycles;

#ifdef KMI
                    debug2.data[debug2.count++ & 15] = cycles;
#endif

                    /* Any odd bits (lower than 16.23) have to be kept seperate */
                    remnant += cycles & mask;

                    /* Add 16.13 bits into clock count */
                    clocks += (cycles & ~mask) + (remnant & ~mask);

                    /* and overflow from odd bits. Remove overflow from odd bits. */
                    remnant &= mask;

                    /* Store MCLK for next time around... */
                    lastClock = u_tmp;

                    /* Reset counts based on SOF counting.  Expect 16ms (128 HS SOFs/16 FS SOFS) per feedback poll
                     * We always count 128 SOFs, so 16ms @ HS, 128ms @ FS */
                    if(sofCount == 128)
                    {
                        sofCount = 0;
#ifdef FB_TOLERANCE_TEST
                        if (clocks > (expected_fb - FB_TOLERANCE) &&
                            clocks < (expected_fb + FB_TOLERANCE))
#endif
                        {
                            int usb_speed;
                            asm("stw %0, dp[g_speed]"::"r"(clocks));   // g_speed = clocks

#ifdef XSCOPE_DEBUG_FEEDBACK
//                            xscope_int(XSCOPE_FEEDBACK_CLOCK,clocks);
#endif


//                            debug_buffer[debug_index++] = g_speed;

                            GET_SHARED_GLOBAL(usb_speed, g_curUsbSpeed);

                            if (usb_speed == XUD_SPEED_HS)
                            {
                                (fb_clocks, unsigned[])[0] = clocks;
                            }
                            else
                            {
                                (fb_clocks, unsigned[])[0] = clocks>>2;
                            }
                        }
#ifdef FB_TOLERANCE_TEST
                        else
                        {
                        }
#endif
                        clocks = 0;
                    }

                    sofCount++;
                }
            break;



#if (NUM_USB_CHAN_IN > 0)
            /* Sent audio packet DEVICE -> HOST */
            case XUD_SetData_Select(c_aud_in, ep_aud_in, result):
            {
                /* Inform stream that buffer sent */
                SET_SHARED_GLOBAL0(g_aud_to_host_flag, bufferIn+1);
            }
            break;
#endif

#if (NUM_USB_CHAN_OUT > 0)
            /* Feedback Pipe */
            case XUD_SetData_Select(c_aud_fb, ep_aud_fb, result):
            {
                XUD_BusSpeed_t busSpeed;

                GET_SHARED_GLOBAL(busSpeed, g_curUsbSpeed);

                if (busSpeed == XUD_SPEED_HS)
                {
                    XUD_SetReady_In(ep_aud_fb, fb_clocks, 4);
                }
                else
                {
                    XUD_SetReady_In(ep_aud_fb, fb_clocks, 3);
                }
            }
            break;

            /* Received Audio packet HOST -> DEVICE. Datalength written to length */
            case XUD_GetData_Select(c_aud_out, ep_aud_out, length, result):
            {
                GET_SHARED_GLOBAL(aud_from_host_buffer, g_aud_from_host_buffer);

                write_via_xc_ptr(aud_from_host_buffer, length);

                /* Sync with decouple thread */
                SET_SHARED_GLOBAL0(g_aud_from_host_flag, 1);
             }
                break;
#endif

#ifdef MIDI

        case XUD_GetData_Select(c_midi_from_host, ep_midi_from_host, length, result):

            if((result == XUD_RES_OKAY) && (length > 0))
            {

#ifdef XSCOPE_DEBUG_MIDI
                xscope_int(XSCOPE_MIDI_LENGTH,length);
#endif

                /* Get buffer data from host - MIDI OUT from host always into a single buffer */
                midi_data_remaining_to_device = length;
                midi_from_host_rdptr = midi_from_host_buffer;


                serve_midi_from_host(chan_i2c_server,ep_midi_from_host,midi_from_host_buffer);


            }
            break;


            //#ifdef TEST_POWER
         case power_test_time => timer_power when timerafter(power_test_time):> power_test_time:
             power_test_time = 0;

              switch(power_test_state)
             {
              case KS_ANNOUNCE_READY:

                  if (!DFU_mode_active)
                  {
                      i2c_msi_write_reg_word(I2C_ADDRESS_8051U, I2C_MSG_TYPE_READY,0,-1);
                      i.poke();
                  }




                  break;

              case KS_TEST_LOW_START2:
#ifdef POWER_CYCLE_LOW_HIGH_TIME
                  set_power_test_state(KS_TEST_LOW_START,POWER_CYCLE_LOW_HIGH_TIME);
#endif
                  break;
                 case KS_TEST_LOW_START:

#ifdef XSCOPE_DEBUG_POWER // 6 KS_TEST_LOW_START
                     xscope_int(XSCOPE_POWER,6);
#endif
                     i2c_msi_write_reg_word(I2C_ADDRESS_XMOS, I2C_MSG_TYPE_POWER_LOW,0,-1);
//                     i.poke();
                     break;
                 case KS_TEST_HIGH_START:
                   i2c_msi_write_reg_word(I2C_ADDRESS_XMOS, I2C_MSG_TYPE_POWER_HIGH,0,-1);
//                   i.poke();
                     break;
                 case KS_DFU_WAIT:
                     GET_SHARED_GLOBAL(freqChange, g_freqChange);
                     if (freqChange)
                     {
                         set_power_test_state(KS_DFU_WAIT,SEC/10);
                     } else
                     {

                          sharc_boot_start(DEFAULT_FREQ);
                         set_power_test_state(KS_SHARC_BOOT_WAIT,SEC/100);
                     }
                     break;
                 case KS_SHARC_BOOT_START:

                     int sampFreq;

                     GET_SHARED_GLOBAL(sampFreq,g_curSamFreq);
                     sharc_boot_start(sampFreq);


                     set_power_test_state(KS_SHARC_BOOT_WAIT,SEC/100);
//                     set_power_test_state(KS_SHARC_BOOT_FINISH,2*SEC);

                     reboot_debug = 0;
                      break;

                 case KS_SHARC_BOOT_WAIT:
                     {
                     unsigned miso_word,state_old;

                     set_power_test_state(0,SEC/30000);

                     select
                     {

                         case P_SPI_MISO :> miso_word:
                             set_power_test_state(KS_SHARC_BOOT_WAIT,SEC/100);
                         reboot_debug++;

                             break;
                         case timer_power when timerafter(power_test_time) :> void:
                             power_test_time = 0;
                     power_state_set(POWER_STATE_HIGH);

                     set_i2s_enabled_c(1);


#ifdef POWER_CYCLE_LOW_HIGH_TIME
    set_power_test_state(KS_TEST_LOW_START,POWER_CYCLE_LOW_HIGH_TIME);
#endif

                            break;
                     }
                     }


                     break;
                 case KS_SHARC_BOOT_FINISH:
   #ifdef POWER_CYCLE_LOW_HIGH_TIME
       set_power_test_state(KS_TEST_LOW_START,POWER_CYCLE_LOW_HIGH_TIME);
   #endif
       set_i2s_enabled_c(1);
                    break;
#ifdef TEST_FIRMWARE_UPDATE
                 case KS_TEST_FW_UPDATE:
                     serve_remote_firmware_test(i);
                     break;
#endif
              }
              break;

        case inct_byref (chan_i2c_client, tmp ): // receive notificatio
                if (master_event_buffer_pop(I2C_TX_INTERFACE_1))
                {
                    while(master_event_buffer_pop(I2C_TX_INTERFACE_1));

#ifdef XSCOPE_DEBUG_MIDI
                    xscope_int(XSCOPE_MIDI_REMAINING_TO_DEVICE,midi_data_remaining_to_device);
#endif

                    serve_midi_from_host(chan_i2c_server,ep_midi_from_host,midi_from_host_buffer);
                }

            unsafe{
                for(;;)
                {
                    I2C_MSI_EVENT * unsafe event = slave_event_buffer_pop();
                    if (!event)
                        break;

                    switch(event->type)
                    {
                        case SLAVE_EVENT_RX:
#ifndef DO_FIRMWARE_CHECK_ON_STARTUP
                            if (!flash_8051_serve(event,i))
#endif
                             switch (event->buffer[0])
                            {
                                case I2C_MSG_TYPE_MIDI_TO_8051:
                                case I2C_MSG_TYPE_8051_TO_MIDI:
                                    if (event->count>=4)
                                    {
                                        unsigned int rxval;
                                        rxval = event->buffer[1] << 0 | event->buffer[2] << 8 | event->buffer[3] << 16 | event->buffer[4] << 24;
                                        last_midi_rx = rxval;

                                        if (midi_data_collected_from_device < MIDI_USB_BUFFER_TO_HOST_SIZE)
                                        {
                                            /* There is room in the collecting buffer for the data */
                                            xc_ptr p = midi_to_host_buffer_being_collected + midi_data_collected_from_device;
                                            // Add data to the buffer
                                            write_via_xc_ptr(p, rxval);
                                            midi_data_collected_from_device += 4;
                                        }
                                        else
                                        {
                                            // Too many events from device - drop
                                        }

                                        // If we are not sending data to the host then initiate it
                                        if (!midi_waiting_on_send_to_host)
                                        {
                                            swap(midi_to_host_buffer_being_collected, midi_to_host_buffer_being_sent);

                                            // Signal other side to swap
                                            XUD_SetReady_InPtr(ep_midi_to_host, midi_to_host_buffer_being_sent, midi_data_collected_from_device);
                                            midi_data_collected_from_device = 0;
                                            midi_waiting_on_send_to_host = 1;
                                        }
                                    }
                                    break;

                                case I2C_MSG_TYPE_POWER_LOW:
                                    port_gpio_c(SHARC_RESET , CODEC_PATH);  // holts SHARC in reset, connect directly to codecs
                                     power_state_set(POWER_STATE_LOW);
#ifdef POWER_CYCLE_LOW_HIGH_TIME
    set_power_test_state(KS_TEST_HIGH_START,POWER_CYCLE_LOW_HIGH_TIME);
#endif
                                    set_i2s_enabled_c(1);  // just in case we were disabled

                                    break;
                                case I2C_MSG_TYPE_POWER_HIGH:

                                    set_i2s_enabled_c(0);


//                                    power_change_high();
                                    set_power_test_state(KS_SHARC_BOOT_START,SEC/10);
#ifdef POWER_CYCLE_LOW_HIGH_TIME
    set_power_test_state(KS_TEST_LOW_START,POWER_CYCLE_LOW_HIGH_TIME);
#endif

                                    break;

                                case I2C_MSG_TYPE_POWER_OFF:
                                    break;
                                case I2C_MSG_TYPE_MIDI_DEBUG_ON:
                                    midi_debug.count = 0;
                                    midi_debug.enabled = 1;
                                    break;
                                case I2C_MSG_TYPE_MIDI_DEBUG_OFF:
                                    midi_debug.enabled = 0;
                                    break;

                                case I2C_MSG_TYPE_REBOOT:
                                    //          printstr("I2C_MSG_TYPE_BUILD_QUERY_FINISHED\n");

                                     reboot();
                                     break;
                            }
                            break;

                        case SLAVE_EVENT_TX:
                                {
                                    unsafe{
//                             i_i2c_msi_tx.i2c_master_suspend_clear();

                                        }
                                }
                            break;

                        default:
                            break;
                    }

                }}
                break;



#ifdef CHANGE_THIS
        case i_i2c_msi_rx.i2c_slave_rx_reg_word(int dest_reg,unsigned int datum,int len):
                sdfsf
#ifdef XSCOPE_DEBUG_MIDI
                xscope_int(XSCOPE_MIDI_RX_BYTE,datum);
#endif
        if (midi_data_collected_from_device < MIDI_USB_BUFFER_TO_HOST_SIZE)
        {
            /* There is room in the collecting buffer for the data */
            xc_ptr p = midi_to_host_buffer_being_collected + midi_data_collected_from_device;
            // Add data to the buffer
            write_via_xc_ptr(p, datum);
            midi_data_collected_from_device += 4;
        }
        else
        {
            // Too many events from device - drop
        }

        // If we are not sending data to the host then initiate it
        if (!midi_waiting_on_send_to_host)
        {
            swap(midi_to_host_buffer_being_collected, midi_to_host_buffer_being_sent);

            // Signal other side to swap
            XUD_SetReady_InPtr(ep_midi_to_host, midi_to_host_buffer_being_sent, midi_data_collected_from_device);
            midi_data_collected_from_device = 0;
            midi_waiting_on_send_to_host = 1;
        }

                break;
#endif



        /* MIDI IN to host */
        case XUD_SetData_Select(c_midi_to_host, ep_midi_to_host, result):

            /* The buffer has been sent to the host, so we can ack the midi thread */
            if (midi_data_collected_from_device != 0)
            {
                /* Swap the collecting and sending buffer */
                swap(midi_to_host_buffer_being_collected, midi_to_host_buffer_being_sent);

                /* Request to send packet */
                XUD_SetReady_InPtr(ep_midi_to_host, midi_to_host_buffer_being_sent, midi_data_collected_from_device);

                /* Mark as waiting for host to poll us */
                midi_waiting_on_send_to_host = 1;
                /* Reset the collected data count */
                midi_data_collected_from_device = 0;
            }
            else
            {
                midi_waiting_on_send_to_host = 0;
            }
          break;
#endif

#ifdef IAP
        /* IAP OUT from host. Datalength writen to tmp */
        case XUD_GetData_Select(c_iap_from_host, ep_iap_from_host, length, result):

            if((result == XUD_RES_OKAY) && (length > 0))
            {
                iap_data_remaining_to_device = length;

                if(iap_data_remaining_to_device)
                {
                    // Send length first so iAP thread knows how much data to expect
                    // Don't expect ack from this to make it simpler
                    outuint(c_iap, iap_data_remaining_to_device);

                    /* Send out first byte in buffer */
                    datum_iap = iap_from_host_buffer[0];
                    outuint(c_iap, datum_iap);

                    /* Set read ptr to next byte in buffer */
                    iap_from_host_rdptr = 1;
                    iap_data_remaining_to_device -= 1;
                }
            }
            break;

        /* IAP IN to host */
        case XUD_SetData_Select(c_iap_to_host, ep_iap_to_host, result):

            if(result == XUD_RES_RST)
            {
                XUD_ResetEndpoint(ep_iap_to_host, null);
#ifdef IAP_INT_EP
                XUD_ResetEndpoint(ep_iap_to_host_int, null);
#endif
                iap_send_reset(c_iap);
                iap_draining_chan = 1; // Drain c_iap until a reset is sent back
                iap_data_collected_from_device = 0;
                iap_data_remaining_to_device = -1;
                iap_expected_data_length = 0;
                iap_from_host_rdptr = 0;
            }
            else
            {
                /* Send out an iAP packet to host, ACK last msg from iAP to let it know we can move on..*/
                iap_send_ack(c_iap);
            }
            break;  /* IAP IN to host */

#ifdef IAP_INT_EP
        case XUD_SetData_Select(c_iap_to_host_int, ep_iap_to_host_int, result):

            /* Do nothing.. */
            /* Note, could get a reset notification here, but deal with it in the case above */
            break;
#endif
#endif

#ifdef HID_CONTROLS
            /* HID Report Data */
            case XUD_SetData_Select(c_hid, ep_hid, result):
            {
                g_hidData[0]=0;
                UserReadHIDButtons(g_hidData);
                XUD_SetReady_In(ep_hid, g_hidData, 1);
            }
            break;
#endif

#ifdef MIDI
#ifndef KMI
            /* Received word from MIDI thread - Check for ACK or Data */
            case midi_get_ack_or_data(c_midi, is_ack, datum):
                if (is_ack)
                {
                    /* An ack from the midi/uart thread means it has accepted some data we sent it
                     * we are okay to send another word */
                    if (midi_data_remaining_to_device <= 0)
                    {
                        /* We have read an entire packet - Mark ready to receive another */
                        int reset = XUD_SetReady_OutPtr(ep_midi_from_host, midi_from_host_buffer);

                    }
                    else
                    {
                        /* Read another word from the fifo and output it to MIDI thread */
                        read_via_xc_ptr(datum, midi_from_host_rdptr);
                        outuint(c_midi, datum);
                        midi_from_host_rdptr += 4;
                        midi_data_remaining_to_device -= 4;
                    }
                }
                else
                {
                    /* The midi/uart thread has sent us some data - handshake back */
                    midi_send_ack(c_midi);
                    if (midi_data_collected_from_device < MIDI_USB_BUFFER_TO_HOST_SIZE)
                    {
                        /* There is room in the collecting buffer for the data */
                        xc_ptr p = midi_to_host_buffer_being_collected + midi_data_collected_from_device;
                        // Add data to the buffer
                        write_via_xc_ptr(p, datum);
                        midi_data_collected_from_device += 4;
                    }
                    else
                    {
                        // Too many events from device - drop
                    }

                    // If we are not sending data to the host then initiate it
                    if (!midi_waiting_on_send_to_host)
                    {
                        swap(midi_to_host_buffer_being_collected, midi_to_host_buffer_being_sent);

                        // Signal other side to swap
                        XUD_SetReady_InPtr(ep_midi_to_host, midi_to_host_buffer_being_sent, midi_data_collected_from_device);
                        midi_data_collected_from_device = 0;
                        midi_waiting_on_send_to_host = 1;
                    }
                }
                break;
#endif // kmi
#endif  /* ifdef MIDI */

#ifdef IAP
            /* Received word from iap thread - Check for ACK or Data */
            case iap_get_ack_or_reset_or_data(c_iap, is_ack_iap, is_reset, datum_iap):

                if (iap_draining_chan)
                {
                    /* As we're draining the iAP channel now, ignore ACKs and data */
                    if (is_reset)
                    {
                        // The iAP core has returned a reset token, so we can stop draining the iAP channel now
                        iap_draining_chan = 0;
                    }
                }
                else
                {
                    if (is_ack_iap)
                    {
                        /* An ack from the iap/uart thread means it has accepted some data we sent it
                         * we are okay to send another word */
                        if (iap_data_remaining_to_device == 0)
                        {
                            /* We have read an entire packet - Mark ready to receive another */
                            XUD_SetReady_Out(ep_iap_from_host, iap_from_host_buffer);
                        }
                        else
                        {
                            /* Read another byte from the fifo and output it to iap thread */
                            datum_iap = iap_from_host_buffer[iap_from_host_rdptr];
                            outuint(c_iap, datum_iap);
                            iap_from_host_rdptr += 1;
                            iap_data_remaining_to_device -= 1;
                        }
                    }
                    else if (!is_reset)
                    {
                        if (iap_expected_data_length == 0)
                        {
                            /* Expect a length from iAP core */
                            iap_send_ack(c_iap);
                            iap_expected_data_length = datum_iap;
                        }
                        else
                        {
                            if (iap_data_collected_from_device < IAP_MAX_PACKET_SIZE)
                            {
                                /* There is room in the collecting buffer for the data..  */
                                iap_to_host_buffer[iap_data_collected_from_device] = datum_iap;
                                iap_data_collected_from_device += 1;
                            }
                            else
                            {
                               // Too many events from device - drop
                            }

                            /* Once we have the whole message, sent it to host */
                            /* Note we don't ack the last byte yet... */
                            if (iap_data_collected_from_device == iap_expected_data_length)
                            {
                                XUD_Result_t result1 = XUD_RES_OKAY, result2;
#ifdef IAP_INT_EP
                                result1 = XUD_SetReady_In(ep_iap_to_host_int, gc_zero_buffer, 0);
#endif
                                result2 = XUD_SetReady_In(ep_iap_to_host, iap_to_host_buffer, iap_data_collected_from_device);

                                if((result1 == XUD_RES_RST) || (result2 == XUD_RES_RST))
                                {
#ifdef IAP_INT_EP
                                    XUD_ResetEndpoint(ep_iap_to_host_int, null);
#endif
                                    XUD_ResetEndpoint(ep_iap_to_host, null);
                                    iap_send_reset(c_iap);
                                    iap_draining_chan = 1; // Drain c_iap until a reset is sent back
                                    iap_data_remaining_to_device = -1;
                                    iap_from_host_rdptr = 0;
                                }

                                iap_data_collected_from_device = 0;
                                iap_expected_data_length = 0;
                            }
                            else
                            {
                                /* The iap/uart thread has sent us some data - handshake back */
                                iap_send_ack(c_iap);
                            }
                        }
                    }
                }
                break;
#endif


        }

    }
    } // ordered
}
