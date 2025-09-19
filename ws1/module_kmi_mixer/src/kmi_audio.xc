#include <print.h>
#include <xscope.h>
#include "customdefines.h"
#include "kmi_mixer.h"
#include "kmi_audio.h"
#include "i2c_msi.h"
#include "utils.h"
#include "ports.h"
#include "AK4612.h"
#include "LM49450.h"
#include "cutils.h"
#include "commands.h"
#include "oscillator.h"
#include "xscope_user.h"

#define ENABLE_CODECS
int sine_table_1p0[] = {
    0x0,
    0xddd130,
    0x111f18,
    0x63e4a4,
    0xd6df0c,
    0xf26a3c,
    0xce38e2,
    0x92cc8a,
    0xf815a,
    0xee8f46,
    0x88b656,
    0x72470e,
    0xfc826e,
    0x953e5e,0xb851be,0xc846fe,
    0xfffffe,0xfa46fe,0x2d51be,0xd1be5e,0x96426e,0x3dc70e,0x837656,0x26cf46,0x68215a,0x45ac8a,0x5f78e2,0x3f1a3c,0x9c7f0c,0x7554a4,0x41df18,0x37130,
    0x90c000,0xd2eecf,0x4e50e7,0x44db5b,0xc6e0f3,0xfa35c3,0xc8671d,0x8f375,0x6c01a5,0x6e08b9,0x7929a9,0x84f8f1,0x57fd91,0x1c21a1,0xde6e41,0x5c7901,
    0x1,0xaab901,0x2d2e41,0xc981a1,0x763d91,0x6b58f1,0xf1f1a9,0xf550b9,0xa39ea5,0x601375,0x17b1d,0x6a25c3,0x9f7f73,0x564b5b,0xc180e7,0x5c76cf
};

int sine_table_p5[] = {
    0x0,0xbba260,0x223e30,0xc7c948,0xadbe18,0xe4d478,0x9c71c4,0x259914,0x1f02b4,0xdd1e8c,0x116cac,0xe48e1c,0xf904dc,0x2a7cbc,0x70a37c,0x908dfc,
    0x2,0xf48dfc,0x5aa37c,0xa37cbc,0x2c84dc,0x7b8e1c,0x6ecac,0x4d9e8c,0xd042b4,0x8b5914,0xbef1c4,0x7e3478,0x38fe18,0xeaa948,0x83be30,0x6e260,
    0x218000,0x65dd9f,0x9ca1cf,0x89b6b7,0x4dc1e7,0xc6b87,0x50ce3b,0x11e6eb,0xd8034b,0xdc1173,0xf25353,0x89f1e3,0xaffb23,0x384343,0x7cdc83,0xb8f203,
    0x3,0xd57203,0x5a5c83,0x530343,0xec7b23,0xd6b1e3,0x13e353,0x1aa173,0xc73d4b,0xc026eb,0x2f63b,0xd44b87,0xbefee7,0xac96b7,0x4301cf,0xb8ed9f
};
int sine_table_p25[] = {
    0x0,0x7744c0,0x447c60,0x8f9290,0x5b7c30,0xc9a8f0,0x38e388,0x4b3228,0x3e0568,0xba3d18,0x22d958,0xc91c38,0xf209b8,0x54f978,0xe146f8,0x211bf8,
    0x4,0xe91bf8,0xb546f8,0x46f978,0x5909b8,0xf71c38,0xdd958,0x9b3d18,0xa08568,0x16b228,0x7de388,0xfc68f0,0x71fc30,0xd55290,0x77c60,0xdc4c0,
    0x430000,0xcbbb3f,0xb9439f,0x936d6f,0x9b83cf,0x18d70f,0xa19c77,0x23cdd7,0x700697,0x7822e7,0x14a6a7,0x93e3c7,0xdff647,0x708687,0xf9b907,0xf1e407,
    0x7,0x6ae407,0xb4b907,0xa60687,0x38f647,0x6d63c7,0x27c6a7,0x3542e7,0x4e7a97,0x404dd7,0x5ec77,0x68970f,0xfdfdcf,0xd92d6f,0x86039f,0xf1db3f
};

int sine_table_p1[] = {  // .1
        0x0,0x348280,0x2fe40,0xb4edc0,0x8fa720,0x851060,0x8e38e0,0x5d7810,0x7f3090,0x4f2790,0x812550,0x2b92d0,0xcacbd0,0x55fc30,0xf3b130,0x80bd30,
            0x333330,0x90bd30,0x7bb130,0x83fc30,0xecbd0,0x9f92d0,0x352550,0xc4a790,0xacb090,0x6f7810,0x4d38e0,0x671060,0x1c6720,0xeeedc0,0xb1fe40,0x9e8280,
            0xb20000,0x44fd7f,0x3081bf,0xb8923f,0xea58df,0xc5ef9f,0xf3c71f,0x4187ef,0x9ccf6f,0xfcd86f,0x55daaf,0x8a6d2f,0xd3342f,0x3603cf,0x24ecf,0x60c2cf,
            0x2ccccf,0xf742cf,0x484ecf,0x9403cf,0x4e342f,0xc7ad2f,0x14daaf,0x35586f,0x294f6f,0x7307ef,0xb0c71f,0x6b6f9f,0x198df,0x7c123f,0xe401bf,0x9c7d7f
};


int sine_table_pz1[] = {  // .01
    0x0,0x780400,0x37fc00,0x78fa00,0x26be00,0x6e5900,0xd06d00,0xfbf300,0xcde700,0xd2bf00,0xce0880,0xdf0480,0xdd7480,0x899c80,0x868280,0x986280,
    0x75e280,0x586280,0xc68280,0xc99c80,0x7d7480,0xff0480,0xee0880,0xabf00,0x1de700,0xa7f300,0x886d00,0xbe5900,0x36be00,0xa4fa00,0x2ffc00,0xa40400,
    0xe00000,0x57fbff,0xd803ff,0x5705ff,0xc541ff,0x89a6ff,0x3f92ff,0xe40cff,0xca18ff,0x5d40ff,0x89f77f,0x90fb7f,0x128b7f,0x4e637f,0x57d7f,0xe79d7f,
    0x4a1d7f,0xa79d7f,0x397d7f,0xd6637f,0xfc8b7f,0x7f7b7f,0x21f77f,0xd540ff,0x4218ff,0xa80cff,0x1792ff,0x3ea6ff,0xb141ff,0xcb05ff,0x2003ff,0xcbfbff
};

#define RELOAD_SHARC    47



void dfu_debug_put_c(int val);

#define SINE_TABLE sine_table_p1

#define SAMP_IN_SIZE    10
unsigned int samp_in[SAMP_IN_SIZE];

#define setc(a,b) {__asm__  __volatile__("setc res[%0], %1": : "r" (a) , "r" (b));}

int init_codecs(int sample_freq,client interface kmi_background_if i)
{
#ifdef FIXED_MCLK

    switch(sample_freq)
    {
    case 44100:
    case 48000:
#ifdef TDM_512_ENABLE
        if (!block_init(I2C_ADDRESS_CODEC,init_ak4612_48k_tdm512_vals,INIT_AK4612_48K_COUNT,i))
            return 0;
#else
        if (!block_init(I2C_ADDRESS_CODEC,init_ak4612_48k_vals,INIT_AK4612_48K_COUNT,i))
            return 0;
#endif
        if (!block_init(I2C_ADDRESS_DAC,init_lm49450_48k_vals,8,i))
            return 0;
        break;

    case 88200:
    case 96000:
        if (!block_init(I2C_ADDRESS_CODEC,init_ak4612_96k_vals,INIT_AK4612_96K_COUNT,i))
            return 0;
        if (!block_init(I2C_ADDRESS_DAC,init_lm49450_96k_vals,8,i))
            return 0;
        break;
    }
#else
    if (!block_init(I2C_ADDRESS_CODEC,init_ak4612_96k_vals,INIT_AK4612_96K_COUNT,i))
        return 0;
    if (!block_init(I2C_ADDRESS_DAC,init_lm49450_96k_vals,8,i))
        return 0;
#endif

    return 1;

}

void reset_codecs(client interface kmi_background_if i)
{
    timer t;int time;
    t :> time;
    t when timerafter(time+10000000) :> void;
    block_init(I2C_ADDRESS_CODEC,reset_ak4612_a,1,i);
    t :> time;
    t when timerafter(time+10000000) :> void;
    block_init(I2C_ADDRESS_CODEC,reset_ak4612_b,1,i);

}

void config_tdm_ports(void)
{
    set_clock_on(CLK_TDM_BCLK);
    stop_clock( CLK_TDM_BCLK );

 #if 1
         c_config_tdm_ports();
#else
     configure_clock_src (CLK_TDM_BCLK , P_TDM_BCLK );  // main does this to setup up feedback
     configure_in_port (P_TDM_IN , CLK_TDM_BCLK );
#ifndef    CODEC_LOOPBACK
    configure_out_port (P_TDM_OUT , CLK_TDM_BCLK , 0);
#endif
#endif

//    setc(P_TDM_IN, XS1_SETC_SDELAY_SDELAY);  // set to sample on rising edge
}

void config_i2s_ports(void)
{
    P_I2S_BCLK :> int _; // make sure it is an input port.  Master boot causes it to be output

    set_clock_on(CLK_I2S_BCLK);
    stop_clock( CLK_I2S_BCLK );

#ifdef MASTER_XMOS
    configure_clock_src (CLK_I2S_BCLK , P_I2S_BCLK );

    setc(P_I2SX, XS1_SETC_INUSE_OFF);
    setc(P_I2SX, XS1_SETC_INUSE_ON);
    setc(P_I2SX, XS1_SETC_BUF_BUFFERS);
    settw(P_I2SX, 32);

    configure_out_port(P_I2SX,CLK_TDM_BCLK,0xf);


#else
    configure_clock_src (clk_i2s_bclk , P_I2S_BCLK );
#endif


    configure_in_port (P_I2S_IN , CLK_I2S_BCLK );
    configure_out_port (P_I2S_OUT , CLK_I2S_BCLK , 0);

//    setc(P_I2S_IN, XS1_SETC_SDELAY_SDELAY);  // set to sample on rising edge

}



void tdm_i2s_reset()
{


    // do this sequence to stop a clock that may hang if stopped
//    set_clock_off(CLK_I2S_BCLK);
//    set_clock_on(CLK_I2S_BCLK);
    stop_clock( CLK_I2S_BCLK );

    // do this sequence to stop a clock that may hang if stopped
//    set_clock_off(CLK_TDM_BCLK);
//    set_clock_on(CLK_TDM_BCLK);
    stop_clock( CLK_TDM_BCLK );


    clearbuf( P_TDM_IN );
#ifndef CODEC_LOOPBACK
    clearbuf( P_TDM_OUT );
#endif
    clearbuf( P_I2S_IN );
    clearbuf( P_I2S_OUT );
}
void tdm_i2s_shift(int tdm_ticks,int i2s_ticks)
{
#ifdef TDM_ENABLE
#ifndef CODEC_LOOPBACK
    P_TDM_OUT @ tdm_ticks <: 0x0;
#endif
        asm("setpt res[%0], %1"::"r"(P_TDM_IN),"r"(tdm_ticks-1));
#endif

#ifdef I2S_ENABLE

#define I2S_TICKS_OUT2   28
        P_I2S_OUT @ 2 <: 0x0;
        asm("setpt res[%0], %1"::"r"(P_I2S_IN),"r"(1));

#endif

}
int last_val;

#ifndef MASTER_XMOS

#define    STATE_COUNT 10

#ifdef HW2
#define AUDIO_SYNC_MASK 8
#else
#define AUDIO_SYNC_MASK 4
#endif

void synchronize_i2s_tdm(int tdm_bit_ticks,int tdm_sys_ticks, int i2s_ticks)
{
        int state_new,state_old;
        int state_count = STATE_COUNT;
        int timer_val;
        timer t;


        for(;;)
        {
            stop_clock( CLK_TDM_BCLK );
            stop_clock( CLK_I2S_BCLK );

            clearbuf( P_TDM_IN );
            clearbuf( P_TDM_OUT );
//            clearbuf( p_i2sx );
            clearbuf( P_I2S_IN );
            clearbuf( P_I2S_OUT );

             p_tdm_out @ tdm_bit_ticks <: 0x0;
            asm("setpt res[%0], %1"::"r"(p_tdm_in),"r"(tdm_bit_ticks-1));

            P_I2S_OUT @ i2s_ticks <: 0x0;
            asm("setpt res[%0], %1"::"r"(P_I2S_IN),"r"(i2s_ticks-1));


            p_sync2 :> state_old;

            select {
                case p_sync2 when pinsneq(state_old) :> state_new:
                    if ( (state_old ^ state_new) & AUDIO_SYNC_MASK)   // did our bit transition
                    {
                        if (state_new & AUDIO_SYNC_MASK)  // is our bit high
                        {
                            if (!--state_count)
                            {
                                t :> timer_val;
                                t when timerafter(timer_val + tdm_sys_ticks) :> void;
                                return;
                            }
                        }
                    } else
                        state_count = STATE_COUNT;

                    break;
            }
        }

}

#else

void synchronize_i2s_tdm(int tdm_ticks,int i2s_ticks)
{
    P_I2SX @ 20 <: I2S_STATE_0;

    P_TDM_OUT @ 28 <: 0x0;
    asm("setpt res[%0], %1"::"r"(P_TDM_IN),"r"(28));  //27
    P_I2S_OUT @ 3 <: 0x0;
    asm("setpt res[%0], %1"::"r"(P_I2S_IN),"r"(2));
}
#endif
#ifdef MASTER_XMOS

#define SLOT_RX_0   0
#define SLOT_RX_1   1
#define SLOT_RX_2   2
#define SLOT_RX_3   3
#define SLOT_RX_4   4
#define SLOT_RX_5   5
#define SLOT_RX_6   6
#define SLOT_RX_7   7
//#define SLOT_RX_8   8
//#define SLOT_RX_9   9

#define SLOT_TX_0   0
#define SLOT_TX_1   1
#define SLOT_TX_2   2
#define SLOT_TX_3   3
#define SLOT_TX_4   4
#define SLOT_TX_5   5
#define SLOT_TX_6   6
#define SLOT_TX_7   7
#define SLOT_TX_8   8
#define SLOT_TX_9   9

#else

#define SLOT_RX_0   0
#define SLOT_RX_1   1
#define SLOT_RX_2   2
#define SLOT_RX_3   3
#define SLOT_RX_4   4
#define SLOT_RX_5   5
#define SLOT_RX_6   6
#define SLOT_RX_7   7
//#define SLOT_RX_8   8
//#define SLOT_RX_9   9

#define SLOT_TX_0   0
#define SLOT_TX_1   1
#define SLOT_TX_2   2
#define SLOT_TX_3   3
#define SLOT_TX_4   4
#define SLOT_TX_5   5
#define SLOT_TX_6   6
#define SLOT_TX_7   7
#define SLOT_TX_8   8
#define SLOT_TX_9   9

#endif

struct {int tdm_bit,tdm_sys,i2s;} sync_delay;

//#define LOOP_COUNT_EXIT 100000

#ifdef LOOP_COUNT_EXIT
int loop_count = 0;

#endif


unsigned i2s_enabled=1;





unsigned deliver_tdm(chanend c_out)
{
    register int sample;
    register unsigned int dac_buffer_address;
    register unsigned int adc_buffer_address;


#ifdef UNUSED

#ifdef MASTER_XMOS
    synchronize_i2s_tdm(2,4);
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#else
    synchronize_i2s_tdm(sync_delay.tdm_bit,sync_delay.tdm_sys,sync_delay.i2s);
    asm("nop;nop;");
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#endif
#endif


    for(;;)
    {
        outuint(c_out, 0);
        if(testct(c_out))
        {
            unsigned command = inct(c_out);
        // Set clocks low
#ifdef MASTER_XMOS
            P_I2SX <: 0;
#endif
            return command;
        }


#ifdef ECHO_AUDIO
        inuint( c_out );
        inuint( c_out);
#else
        dac_buffer_address = inuint( c_out );
        adc_buffer_address = inuint( c_out);
#endif

        TDM_I(SLOT_RX_5)
        TDM_OZ(SLOT_TX_5,0)

        TDM_I(SLOT_RX_6)
        TDM_OZ(SLOT_TX_6,0)

        TDM_I(SLOT_RX_7)
        TDM_OZ(SLOT_TX_7,0)


        TDM_I_IGNORE // blank?
        TDM_OZ(SLOT_TX_0,0)


        TDM_I_IGNORE  // blank?
        TDM_OZ(SLOT_TX_1,0)

        TDM_I(SLOT_RX_2)
        TDM_OZ(SLOT_TX_2,0)

        TDM_I(SLOT_RX_3)
        TDM_OZ(SLOT_TX_3,0x0)


        TDM_I(SLOT_RX_4)
        TDM_OZ(SLOT_TX_4,0)
    }

    return 0;

}

#ifdef SINE_OUT
unsigned sindex = 0;
#endif

unsigned deliver_tdm_512(chanend c_out)
{
    register int sample;
    register unsigned int dac_buffer_address;
    register unsigned int adc_buffer_address;

//    sync_feedback_c();

#ifdef UNUSED

#ifdef MASTER_XMOS
    synchronize_i2s_tdm(2,4);
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#else
    synchronize_i2s_tdm(sync_delay.tdm_bit,sync_delay.tdm_sys,sync_delay.i2s);
    asm("nop;nop;");
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#endif
#endif



    for(;;)
    {
        TDM_I_IGNORE
        TDM_O_IGNORE

        TDM_I_IGNORE
        TDM_O_IGNORE

        TDM_I_IGNORE
        TDM_O_IGNORE

        TDM_I_IGNORE
        TDM_O_IGNORE

        TDM_I_IGNORE
        TDM_O_IGNORE

        TDM_I_IGNORE
        TDM_O_IGNORE

        TDM_I_IGNORE
        TDM_O_IGNORE

    outuint(c_out, 0);
    if(testct(c_out))
    {
        unsigned command = inct(c_out);
        // Set clocks low
#ifdef MASTER_XMOS
        P_I2SX <: 0;
#endif
        return command;
    }


#ifdef ECHO_AUDIO
    inuint( c_out );
    inuint( c_out);
#else
    dac_buffer_address = inuint( c_out );
    adc_buffer_address = inuint( c_out);
#endif


    TDM_I_IGNORE
    TDM_O_IGNORE

    TDM_I_IGNORE
    TDM_O_IGNORE

    TDM_I_IGNORE
    TDM_O_IGNORE

    TDM_I_IGNORE
    TDM_O_IGNORE

    TDM_I_IGNORE
    TDM_O_IGNORE

    TDM_I_IGNORE
    TDM_O_IGNORE

    TDM_I_IGNORE
    TDM_O_IGNORE

    TDM_I_IGNORE
    TDM_O_IGNORE

    TDM_I_IGNORE
    TDM_O_IGNORE

    }

    return 0;

}



unsafe{
unsigned static deliver_tdm_i2s_512(chanend c_out,volatile unsigned * unsafe ptr)
{
    register int sample;
    register unsigned int dac_buffer_address;
    register unsigned int adc_buffer_address;


     outuint(c_out, 0);
    if(testct(c_out))
    {
        unsigned command = inct(c_out);
        // Set clocks low
#ifdef MASTER_XMOS
        P_I2SX <: 0;
#endif
        return command;
    }


#ifdef ECHO_AUDIO
    inuint( c_out );
    adc_buffer_address = dac_buffer_address = inuint( c_out);
#else
    dac_buffer_address = inuint( c_out );
    adc_buffer_address = inuint( c_out);
#endif


#ifdef LOOP_COUNT_EXIT
    loop_count = LOOP_COUNT_EXIT;
#endif




//    for(;;)
//        P_I2SX <: 0x00001111;


    while(1)
    {

        config_audio_ports();
        config_tdm_ports();
         config_i2s_ports();

//         sync_feedback_c();


#ifdef MASTER_XMOS
synchronize_i2s_tdm(2,4);
start_clock( CLK_TDM_BCLK );
start_clock( CLK_I2S_BCLK );
#else
synchronize_i2s_tdm(sync_delay.tdm_bit,sync_delay.tdm_sys,sync_delay.i2s);
asm("nop;nop;");
start_clock( CLK_TDM_BCLK );
start_clock( CLK_I2S_BCLK );
#endif


            do
            {



#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
#endif

                                            TDM_I_IGNORE
                                            TDM_O(SLOT_TX_1,0)

        #ifdef LOOP_COUNT_EXIT
            if (!--loop_count)
                return 100;
        #endif

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
#endif



                                            TDM_I(SLOT_RX_2)
                                            TDM_O(SLOT_TX_2,0)

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
#endif


                                            TDM_I(SLOT_RX_3)
                                            TDM_O(SLOT_TX_3,0)


#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
#endif
                                            TDM_I(SLOT_RX_4)
                                            TDM_O(SLOT_TX_4,0)


#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
#endif

                                            TDM_I(SLOT_RX_5)
                                            TDM_O(SLOT_TX_5,0)


#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
#endif

                                            TDM_I(SLOT_RX_6)
                                            TDM_O(SLOT_TX_6,0)
#ifdef SINE_OUT
sindex++;
#endif

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
                                    P_I2SX <: I2S_512_LRHI;
#endif


                                            TDM_I(SLOT_RX_7)
                                            TDM_O(SLOT_TX_7,0)
            outuint(c_out, 0);
            if(testct(c_out))
            {
                unsigned command = inct(c_out);
                // Set clocks low
        #ifdef MASTER_XMOS
                P_I2SX <: 0;
        #endif
                return command;
            }


        #ifdef ECHO_AUDIO
            inuint( c_out );
            inuint( c_out);
        #else
            dac_buffer_address = inuint( c_out );
            adc_buffer_address = inuint( c_out);
        #endif

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_512_LRHI;
                                            P_I2SX <: I2S_512_LRHI;
                                            P_I2SX <: I2S_512_LRHI;
                                            P_I2SX <: I2S_512_LRHI;
        #endif
            TDM_I_IGNORE
            TDM_O_IGNORE

            I2S_I(SLOT_RX_1)
            I2S_O(SLOT_TX_9,1)

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
#endif
                                    TDM_I_IGNORE
                                    TDM_O_IGNORE
#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
#endif

                                    TDM_I_IGNORE
                                    TDM_O_IGNORE

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
#endif
                                    TDM_I_IGNORE
                                    TDM_O_IGNORE


#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
#endif

                                    TDM_I_IGNORE
                                    TDM_O_IGNORE

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
#endif

              TDM_I_IGNORE
              TDM_O_IGNORE

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
#endif

               TDM_I_IGNORE
               TDM_O_IGNORE

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
#endif

                TDM_I_IGNORE
                TDM_O_IGNORE

#ifdef MASTER_XMOS
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
                                    P_I2SX <: I2S_512_LRLO;
#endif

                 TDM_I_IGNORE
                 TDM_O(SLOT_TX_0,0)

                 I2S_I(SLOT_RX_0)
                 I2S_O(SLOT_TX_8,1)

            }
            while (*ptr);


            P_I2SX :> void; // make an input port

            do
            {
                                            TDM_I_IGNORE
                                            TDM_O(SLOT_TX_1,0)

                                            TDM_I_Z(SLOT_RX_2)
                                            TDM_O(SLOT_TX_2,0)

                                            TDM_I_Z(SLOT_RX_3)
                                            TDM_O(SLOT_TX_3,0)

                                            TDM_I_Z(SLOT_RX_4)
                                            TDM_O(SLOT_TX_4,0)

                                            TDM_I_Z(SLOT_RX_5)
                                            TDM_O(SLOT_TX_5,0)

                                            TDM_I_Z(SLOT_RX_6)
                                            TDM_O(SLOT_TX_6,0)

                                            TDM_I_Z(SLOT_RX_7)
                                            TDM_O(SLOT_TX_7,0)
            outuint(c_out, 0);
            if(testct(c_out))
            {
                unsigned command = inct(c_out);
                // Set clocks low
        #ifdef MASTER_XMOS
                P_I2SX <: 0;
        #endif
                return command;
            }


        #ifdef ECHO_AUDIO
            inuint( c_out );
            inuint( c_out);
        #else
            dac_buffer_address = inuint( c_out );
            adc_buffer_address = inuint( c_out);
        #endif


            TDM_I_IGNORE
            TDM_O_IGNORE

//            I2S_I(SLOT_RX_1)
//            I2S_O(SLOT_TX_9,1)

                                    TDM_I_IGNORE
                                    TDM_O_IGNORE

                                    TDM_I_IGNORE
                                    TDM_O_IGNORE

                                    TDM_I_IGNORE
                                    TDM_O_IGNORE

                                    TDM_I_IGNORE
                                    TDM_O_IGNORE

              TDM_I_IGNORE
              TDM_O_IGNORE

               TDM_I_IGNORE
               TDM_O_IGNORE

                TDM_I_IGNORE
                TDM_O_IGNORE

                 TDM_I_IGNORE
                             TDM_O(SLOT_TX_0,0)

//                 I2S_I(SLOT_RX_0)
//                 I2S_O(SLOT_TX_8,1)

            }
            while (!*ptr);

    }

    return 0;
}
} // unsafe


#if 1
unsafe{
unsigned  deliver_tdm_i2s(chanend c_out,volatile unsigned * unsafe ptr)
{
    register int sample;
    register unsigned int dac_buffer_address;
    register unsigned int adc_buffer_address;


     outuint(c_out, 0);
    if(testct(c_out))
    {
        unsigned command = inct(c_out);
        // Set clocks low
#ifdef MASTER_XMOS
        P_I2SX <: 0;
#endif
        return command;
    }


#ifdef ECHO_AUDIO
    inuint( c_out );
    adc_buffer_address = dac_buffer_address = inuint( c_out);
#else
    dac_buffer_address = inuint( c_out );
    adc_buffer_address = inuint( c_out);
#endif

//    return;


#ifdef LOOP_COUNT_EXIT
    loop_count = LOOP_COUNT_EXIT;
#endif




//    for(;;)
//        P_I2SX <: 0x00001111;


    while(1)
    {

                    config_audio_ports();
                    config_tdm_ports();
                     config_i2s_ports();

//                     sync_feedback_c();


#ifdef MASTER_XMOS
    synchronize_i2s_tdm(2,4);
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#else
    synchronize_i2s_tdm(sync_delay.tdm_bit,sync_delay.tdm_sys,sync_delay.i2s);
    asm("nop;nop;");
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#endif

            do
            {



        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_16;
                                            P_I2SX <: I2S_STATE_17;
                                            P_I2SX <: I2S_STATE_18;
                                            P_I2SX <: I2S_STATE_19;
        #endif

            TDM_I(SLOT_RX_5)
            TDM_O(SLOT_TX_5,0)

        #ifdef LOOP_COUNT_EXIT
            if (!--loop_count)
                return 100;
        #endif

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_20;
                                            P_I2SX <: I2S_STATE_21;
                                            P_I2SX <: I2S_STATE_22;
                                            P_I2SX <: I2S_STATE_23;
        #endif



            TDM_I(SLOT_RX_6)
            TDM_O(SLOT_TX_6,0)

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_24;
                                            P_I2SX <: I2S_STATE_25;
                                            P_I2SX <: I2S_STATE_26;
                                            P_I2SX <: I2S_STATE_27;
        #endif

            TDM_I(SLOT_RX_7)
            TDM_O(SLOT_TX_7,0)




        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_28;
                                            P_I2SX <: I2S_STATE_29;
                                            P_I2SX <: I2S_STATE_30;
                                            P_I2SX <: I2S_STATE_31;
        #endif

            TDM_I_IGNORE // blank?

            I2S_I(SLOT_RX_0)
            I2S_O(SLOT_TX_8,1)

            TDM_O(SLOT_TX_0,0)

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_0;
                                            P_I2SX <: I2S_STATE_1;
                                            P_I2SX <: I2S_STATE_2;
                                            P_I2SX <: I2S_STATE_3;
        #endif


#ifdef SINE_OUT
sindex++;
#endif

            TDM_I_IGNORE  // blank?
            TDM_O(SLOT_TX_1,0)

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_4;
                                            P_I2SX <: I2S_STATE_5;
                                            P_I2SX <: I2S_STATE_6;
                                            P_I2SX <: I2S_STATE_7;
        #endif
            TDM_I(SLOT_RX_2)
             TDM_O(SLOT_TX_2,0)


        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_8;
                                            P_I2SX <: I2S_STATE_9;
                                            P_I2SX <: I2S_STATE_10;
                                            P_I2SX <: I2S_STATE_11;
        #endif

            TDM_I(SLOT_RX_3)
            TDM_O(SLOT_TX_3,0x0)

            outuint(c_out, 0);
            if(testct(c_out))
            {
                unsigned command = inct(c_out);
                // Set clocks low
        #ifdef MASTER_XMOS
                P_I2SX <: 0;
        #endif
                return command;
            }


        #ifdef ECHO_AUDIO
            inuint( c_out );
            inuint( c_out);
        #else
            dac_buffer_address = inuint( c_out );
            adc_buffer_address = inuint( c_out);
        #endif



        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_12;
                                            P_I2SX <: I2S_STATE_13;
                                            P_I2SX <: I2S_STATE_14;
                                            P_I2SX <: I2S_STATE_15;
        #endif

            TDM_I(SLOT_RX_4)

            I2S_I(SLOT_RX_1)
            I2S_O(SLOT_TX_9,1)

            TDM_O(SLOT_TX_4,0)


            }
//            while (1);
            while (*ptr);


            P_I2SX :> void; // make an input port

            do
            {

                TDM_I(SLOT_RX_5)
                TDM_O(SLOT_TX_5,0)

                TDM_I(SLOT_RX_6)
                TDM_O(SLOT_TX_6,0)

                TDM_I(SLOT_RX_7)
                TDM_O(SLOT_TX_7,0)


                TDM_I_IGNORE // blank?
                TDM_O(SLOT_TX_0,0)


                TDM_I_IGNORE  // blank?
                TDM_O(SLOT_TX_1,0)

                TDM_I(SLOT_RX_2)
                TDM_O(SLOT_TX_2,0)

                TDM_I(SLOT_RX_3)
                TDM_O(SLOT_TX_3,0x0)

                outuint(c_out, 0);
                if(testct(c_out))
                {
                    unsigned command = inct(c_out);
                // Set clocks low
        #ifdef MASTER_XMOS
                    P_I2SX <: 0;
        #endif
                    return command;
                }


        #ifdef ECHO_AUDIO
                inuint( c_out );
                inuint( c_out);
        #else
                dac_buffer_address = inuint( c_out );
                adc_buffer_address = inuint( c_out);
        #endif

                TDM_I(SLOT_RX_4)
                TDM_O(SLOT_TX_4,0)
            }
            while(!*ptr);

//            config_audio_ports();
//            config_tdm_ports();
//             config_i2s_ports();

    }

    return 0;
}
} // unsafe

#else
unsafe{
unsigned static deliver_tdm_i2s(chanend c_out,volatile int * unsafe ptr)
{
    register int sample;
    register unsigned int dac_buffer_address;
    register unsigned int adc_buffer_address;


     outuint(c_out, 0);
    if(testct(c_out))
    {
        unsigned command = inct(c_out);
        // Set clocks low
#ifdef MASTER_XMOS
        P_I2SX <: 0;
#endif
        return command;
    }


#ifdef ECHO_AUDIO
    inuint( c_out );
    adc_buffer_address = dac_buffer_address = inuint( c_out);
#else
    dac_buffer_address = inuint( c_out );
    adc_buffer_address = inuint( c_out);
#endif

//    return;


#ifdef LOOP_COUNT_EXIT
    loop_count = LOOP_COUNT_EXIT;
#endif




//    for(;;)
//        P_I2SX <: 0x00001111;


    while(1)
    {

                    config_audio_ports();
                    config_tdm_ports();
                     config_i2s_ports();

//                     sync_feedback_c();


#ifdef MASTER_XMOS
    synchronize_i2s_tdm(2,4);
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#else
    synchronize_i2s_tdm(sync_delay.tdm_bit,sync_delay.tdm_sys,sync_delay.i2s);
    asm("nop;nop;");
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#endif

            do
            {



        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_16;
                                            P_I2SX <: I2S_STATE_17;
                                            P_I2SX <: I2S_STATE_18;
                                            P_I2SX <: I2S_STATE_19;
        #endif

            TDM_I(SLOT_RX_5)
            TDM_O(SLOT_TX_5,0)

        #ifdef LOOP_COUNT_EXIT
            if (!--loop_count)
                return 100;
        #endif

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_20;
                                            P_I2SX <: I2S_STATE_21;
                                            P_I2SX <: I2S_STATE_22;
                                            P_I2SX <: I2S_STATE_23;
        #endif



            TDM_I(SLOT_RX_6)
            TDM_O(SLOT_TX_6,0)

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_24;
                                            P_I2SX <: I2S_STATE_25;
                                            P_I2SX <: I2S_STATE_26;
                                            P_I2SX <: I2S_STATE_27;
        #endif

            TDM_I(SLOT_RX_7)
            TDM_O(SLOT_TX_7,0)




        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_28;
                                            P_I2SX <: I2S_STATE_29;
                                            P_I2SX <: I2S_STATE_30;
                                            P_I2SX <: I2S_STATE_31;
        #endif

            TDM_I_IGNORE // blank?

            I2S_I(SLOT_RX_0)
            I2S_O(SLOT_TX_8,1)

            TDM_O(SLOT_TX_0,0)

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_0;
                                            P_I2SX <: I2S_STATE_1;
                                            P_I2SX <: I2S_STATE_2;
                                            P_I2SX <: I2S_STATE_3;
        #endif


#ifdef SINE_OUT
sindex++;
#endif

            TDM_I_IGNORE  // blank?
            TDM_O(SLOT_TX_1,0)

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_4;
                                            P_I2SX <: I2S_STATE_5;
                                            P_I2SX <: I2S_STATE_6;
                                            P_I2SX <: I2S_STATE_7;
        #endif
            TDM_I(SLOT_RX_2)
             TDM_O(SLOT_TX_2,0)


        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_8;
                                            P_I2SX <: I2S_STATE_9;
                                            P_I2SX <: I2S_STATE_10;
                                            P_I2SX <: I2S_STATE_11;
        #endif

            TDM_I(SLOT_RX_3)
            TDM_O(SLOT_TX_3,0x0)

            outuint(c_out, 0);
            if(testct(c_out))
            {
                unsigned command = inct(c_out);
                // Set clocks low
        #ifdef MASTER_XMOS
                P_I2SX <: 0;
        #endif
                return command;
            }


        #ifdef ECHO_AUDIO
            inuint( c_out );
            inuint( c_out);
        #else
            dac_buffer_address = inuint( c_out );
            adc_buffer_address = inuint( c_out);
        #endif



        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_12;
                                            P_I2SX <: I2S_STATE_13;
                                            P_I2SX <: I2S_STATE_14;
                                            P_I2SX <: I2S_STATE_15;
        #endif

            TDM_I(SLOT_RX_4)

            I2S_I(SLOT_RX_1)
            I2S_O(SLOT_TX_9,1)

            TDM_O(SLOT_TX_4,0)




            }
            while(!*ptr);


            P_I2SX :> void; // make an input port

            do
            {

                TDM_I(SLOT_RX_5)
                TDM_O(SLOT_TX_5,0)

                TDM_I(SLOT_RX_6)
                TDM_O(SLOT_TX_6,0)

                TDM_I(SLOT_RX_7)
                TDM_O(SLOT_TX_7,0)


                TDM_I_IGNORE // blank?
                TDM_O(SLOT_TX_0,0)


                TDM_I_IGNORE  // blank?
                TDM_O(SLOT_TX_1,0)

                TDM_I(SLOT_RX_2)
                TDM_O(SLOT_TX_2,0)

                TDM_I(SLOT_RX_3)
                TDM_O(SLOT_TX_3,0x0)

                outuint(c_out, 0);
                if(testct(c_out))
                {
                    unsigned command = inct(c_out);
                // Set clocks low
        #ifdef MASTER_XMOS
                    P_I2SX <: 0;
        #endif
                    return command;
                }


        #ifdef ECHO_AUDIO
                inuint( c_out );
                inuint( c_out);
        #else
                dac_buffer_address = inuint( c_out );
                adc_buffer_address = inuint( c_out);
        #endif

                TDM_I(SLOT_RX_4)
                TDM_O(SLOT_TX_4,0)



            }
            while(!*ptr);

//            config_audio_ports();
//            config_tdm_ports();
//             config_i2s_ports();

    }

    return 0;
}
} // unsafe
#endif


unsafe{
unsigned  deliver_tdm_i2s2(unsigned count)
{
    register int sample;


                    config_audio_ports();
                    config_tdm_ports();
                     config_i2s_ports();

//                     sync_feedback_c();


#ifdef MASTER_XMOS
    synchronize_i2s_tdm(2,4);
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#else
    synchronize_i2s_tdm(sync_delay.tdm_bit,sync_delay.tdm_sys,sync_delay.i2s);
    asm("nop;nop;");
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#endif

            do
            {



        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_16;
                                            P_I2SX <: I2S_STATE_17;
                                            P_I2SX <: I2S_STATE_18;
                                            P_I2SX <: I2S_STATE_19;
        #endif

            TDM_I_IGNORE
            TDM_O_IGNORE


        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_20;
                                            P_I2SX <: I2S_STATE_21;
                                            P_I2SX <: I2S_STATE_22;
                                            P_I2SX <: I2S_STATE_23;
        #endif



                                            TDM_I_IGNORE
                                            TDM_O_IGNORE

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_24;
                                            P_I2SX <: I2S_STATE_25;
                                            P_I2SX <: I2S_STATE_26;
                                            P_I2SX <: I2S_STATE_27;
        #endif

                                            TDM_I_IGNORE
                                            TDM_O_IGNORE




        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_28;
                                            P_I2SX <: I2S_STATE_29;
                                            P_I2SX <: I2S_STATE_30;
                                            P_I2SX <: I2S_STATE_31;
        #endif

            TDM_I_IGNORE // blank?

            I2S_I_IGNORE
            I2S_O_IGNORE

            TDM_O_IGNORE

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_0;
                                            P_I2SX <: I2S_STATE_1;
                                            P_I2SX <: I2S_STATE_2;
                                            P_I2SX <: I2S_STATE_3;
        #endif


#ifdef SINE_OUT
sindex++;
#endif

TDM_I_IGNORE
TDM_O_IGNORE

        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_4;
                                            P_I2SX <: I2S_STATE_5;
                                            P_I2SX <: I2S_STATE_6;
                                            P_I2SX <: I2S_STATE_7;
        #endif
                                            TDM_I_IGNORE
                                            TDM_O_IGNORE


        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_8;
                                            P_I2SX <: I2S_STATE_9;
                                            P_I2SX <: I2S_STATE_10;
                                            P_I2SX <: I2S_STATE_11;
        #endif

                                            TDM_I_IGNORE
                                            TDM_O_IGNORE





        #ifdef MASTER_XMOS
                                            P_I2SX <: I2S_STATE_12;
                                            P_I2SX <: I2S_STATE_13;
                                            P_I2SX <: I2S_STATE_14;
                                            P_I2SX <: I2S_STATE_15;
        #endif

            TDM_I_IGNORE

                                            I2S_I_IGNORE
                                            I2S_O_IGNORE

            TDM_O_IGNORE


            }
//            while (1);
            while (count--);


    return 0;
}
} // unsafe




#define ECHO_AUDIO


unsigned static deliver_echo(chanend c_out)
{
    register int sample;
    register unsigned int dac_buffer_address;
    register unsigned int adc_buffer_address;


    outuint(c_out, 0);
    if(testct(c_out))
    {
        unsigned command = inct(c_out);
        // Set clocks low
#ifdef MASTER_XMOS
        P_I2SX <: 0;
#endif
        return command;
    }


#ifdef ECHO_AUDIO
    inuint( c_out );
    adc_buffer_address = dac_buffer_address = inuint( c_out);
#else
    dac_buffer_address = inuint( c_out );
    adc_buffer_address = inuint( c_out);
#endif

#ifdef LOOP_COUNT_EXIT
    loop_count = LOOP_COUNT_EXIT;
#endif




    while(1)
    {
        config_audio_ports();
        config_tdm_ports();
         config_i2s_ports();


#ifdef MASTER_XMOS
    synchronize_i2s_tdm(2,4);
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#else
    synchronize_i2s_tdm(sync_delay.tdm_bit,sync_delay.tdm_sys,sync_delay.i2s);
    asm("nop;nop;");
    start_clock( CLK_TDM_BCLK );
    start_clock( CLK_I2S_BCLK );
#endif
        while(i2s_enabled)
        {

#ifdef MASTER_XMOS
                                        P_I2SX <: I2S_STATE_16;
                                        P_I2SX <: I2S_STATE_17;
                                        P_I2SX <: I2S_STATE_18;
                                        P_I2SX <: I2S_STATE_19;
#endif

        TDM_I(SLOT_RX_5)
        TDM_O(SLOT_TX_5,0)

#ifdef LOOP_COUNT_EXIT
        if (!--loop_count)
            return 100;
#endif

#ifdef MASTER_XMOS
                                        P_I2SX <: I2S_STATE_20;
                                        P_I2SX <: I2S_STATE_21;
                                        P_I2SX <: I2S_STATE_22;
                                        P_I2SX <: I2S_STATE_23;
#endif

        TDM_I(SLOT_RX_6)
        TDM_O(SLOT_TX_6,0)

#ifdef MASTER_XMOS
                                        P_I2SX <: I2S_STATE_24;
                                        P_I2SX <: I2S_STATE_25;
                                        P_I2SX <: I2S_STATE_26;
                                        P_I2SX <: I2S_STATE_27;
#endif

        TDM_I(SLOT_RX_7)
        TDM_O(SLOT_TX_7,0)

#ifdef MASTER_XMOS
                                        P_I2SX <: I2S_STATE_28;
                                        P_I2SX <: I2S_STATE_29;
                                        P_I2SX <: I2S_STATE_30;
                                        P_I2SX <: I2S_STATE_31;
#endif

        TDM_I_IGNORE // blank?
        I2S_I(SLOT_RX_0)
        I2S_O(SLOT_TX_8,1)
        TDM_O(SLOT_TX_0,0)

#ifdef MASTER_XMOS
                                        P_I2SX <: I2S_STATE_0;
                                        P_I2SX <: I2S_STATE_1;
                                        P_I2SX <: I2S_STATE_2;
                                        P_I2SX <: I2S_STATE_3;
#endif

        TDM_I_IGNORE  // blank?
        TDM_O(SLOT_TX_1,0)

#ifdef MASTER_XMOS
                                        P_I2SX <: I2S_STATE_4;
                                        P_I2SX <: I2S_STATE_5;
                                        P_I2SX <: I2S_STATE_6;
                                        P_I2SX <: I2S_STATE_7;
#endif
        TDM_I(SLOT_RX_2)
         TDM_O(SLOT_TX_2,0)

#ifdef MASTER_XMOS
                                        P_I2SX <: I2S_STATE_8;
                                        P_I2SX <: I2S_STATE_9;
                                        P_I2SX <: I2S_STATE_10;
                                        P_I2SX <: I2S_STATE_11;
#endif
        TDM_I(SLOT_RX_3)
        TDM_O(SLOT_TX_3,0x0)

        outuint(c_out, 0);
        if(testct(c_out))
        {
            unsigned command = inct(c_out);
            // Set clocks low
#ifdef MASTER_XMOS
            P_I2SX <: 0;
#endif
            return command;
        }


#ifdef ECHO_AUDIO
        inuint( c_out );
        inuint( c_out);
#else
        dac_buffer_address = inuint( c_out );
        adc_buffer_address = inuint( c_out);
#endif




#ifdef MASTER_XMOS
                                        P_I2SX <: I2S_STATE_12;
                                        P_I2SX <: I2S_STATE_13;
                                        P_I2SX <: I2S_STATE_14;
                                        P_I2SX <: I2S_STATE_15;
#endif

        TDM_I(SLOT_RX_4)

        I2S_I(SLOT_RX_1)
        I2S_O(SLOT_TX_9,1)

        TDM_O(SLOT_TX_4,0)
        }


        P_I2SX :> void; // make an input port

        do
        {

            TDM_I(SLOT_RX_5)
            TDM_O(SLOT_TX_5,0)

            TDM_I(SLOT_RX_6)
            TDM_O(SLOT_TX_6,0)

            TDM_I(SLOT_RX_7)
            TDM_O(SLOT_TX_7,0)


            TDM_I_IGNORE // blank?
            TDM_O(SLOT_TX_0,0)


            TDM_I_IGNORE  // blank?
            TDM_O(SLOT_TX_1,0)

            TDM_I(SLOT_RX_2)
            TDM_O(SLOT_TX_2,0)

            TDM_I(SLOT_RX_3)
            TDM_O(SLOT_TX_3,0x0)

            outuint(c_out, 0);
            if(testct(c_out))
            {
                unsigned command = inct(c_out);
            // Set clocks low
#ifdef MASTER_XMOS
                P_I2SX <: 0;
#endif
                return command;
            }


#ifdef ECHO_AUDIO
            inuint( c_out );
            inuint( c_out);
#else
            dac_buffer_address = inuint( c_out );
            adc_buffer_address = inuint( c_out);
#endif

            TDM_I(SLOT_RX_4)
            TDM_O(SLOT_TX_4,0)
        }
        while(!i2s_enabled);

        config_audio_ports();
        config_tdm_ports();
         config_i2s_ports();


    }

    return 0;
}

#ifdef KMI


void reset_debug_count_c();

unsigned static dummy_deliver(chanend c_out,unsigned int sample_rate)
{
    unsigned int time,time_inc = 100000000/sample_rate;  // grossly approximate sample rate
    timer t;
    t :> time;

 //   int debug_count_1 = 5;

    reset_debug_count_c();

    if (sample_rate != 96000)
        for(;;);

    while(1)
    {
        t when timerafter(time) :> void;
        time += time_inc;


         outuint(c_out, 0);



        /* Check for sample freq change or new samples from mixer*/
        if(testct(c_out))
        {
            unsigned command = inct(c_out);
            return command;
        }
        inuint( c_out );

#ifdef XSCOPE_DEBUG_POWER // 16 dummy_deliver
         if (debug_count_1)
         {
             xscope_int(XSCOPE_POWER,16);
             debug_count_1--;
         }
#endif

        inuint( c_out);

    }

    return 0;
}

#else
unsigned static dummy_deliver(chanend c_out)
{
    while (1)
    {
        outuint(c_out, 0);

        /* Check for sample freq change or new samples from mixer*/
        if(testct(c_out))
        {
            unsigned command = inct(c_out);
            return command;
        }
        else
        {
            (void) inuint(c_out);
#pragma loop unroll
            for(int i = 0; i < NUM_USB_CHAN_IN; i++)
            {
                outuint(c_out, 0);
            }

#pragma loop unroll
            for(int i = 0; i < NUM_USB_CHAN_OUT; i++)
            {
                (void) inuint(c_out);
            }
        }
    }
    return 0;
}
#endif


#define ALL_START_REG   0
#define ALL_END_REG     187

#define PARTIAL_START_REG     34
#define PARTIAL_END_REG  49

void init_clock_vals(unsigned char vals[],int full_flag,client interface kmi_background_if i)
{
#ifdef FIXED_MCLK
        if (full_flag)
            init_clock(vals,ALL_START_REG,ALL_END_REG,i);
        else
            init_clock(vals,PARTIAL_START_REG,PARTIAL_END_REG,i);
#else
        if (full_flag)
            init_clock(vals,ALL_START_REG,ALL_END_REG,i);
        else
            init_clock(vals,PARTIAL_START_REG,PARTIAL_END_REG,i);
#endif

}

int debug_sample_rate_count = 0;

void change_sample_rate(unsigned int sample_freq,unsigned int full_flag,client interface kmi_background_if i)
{

    i.port_gpio(ADC_MASK(sample_freq),ADC_ORVAL(sample_freq));



    debug_sample_rate_count++;



#ifdef FIXED_MCLK
    init_codecs(sample_freq,i);
#endif

//    printuintln(sample_freq);



    switch (sample_freq)
    {
    case 44100:
        sync_delay.tdm_bit = 124;
        sync_delay.tdm_sys = 5; // 1,2,3,4,5,6,7,8 -- 9
        sync_delay.i2s = 31;
#ifdef FIXED_MCLK
        init_clock_vals(clock_config_enable_all_882,full_flag,i);
#else
        init_clock_vals(clock_config_enable_all_441,full_flag,i);
#endif
        break;
    case 48000:
        sync_delay.tdm_bit = 124;
        sync_delay.tdm_sys = 4; // 1,2,3,4,5,6 - 7
        sync_delay.i2s = 31;
#ifdef FIXED_MCLK
        init_clock_vals(clock_config_enable_all_96,full_flag,i);
#else
        init_clock_vals(clock_config_enable_all_48,full_flag,i);
#endif
        break;
    case 88200:
        sync_delay.tdm_bit = 121;
        sync_delay.tdm_sys = 3; // 1,2,3,4,5 -- 6
        sync_delay.i2s = 31;
        init_clock_vals(clock_config_enable_all_882,full_flag,i);

        break;
    case 96000:
        sync_delay.tdm_bit = 120;
        sync_delay.tdm_sys = 4;  // 3,4,5,6, -- 7.8,9,10 -- 11
        sync_delay.i2s = 30;
        init_clock_vals(clock_config_enable_all_96,full_flag,i);
        break;
    default:
        for(;;);
        break;
    }

//    reset_codecs(i);
}

void set_i2sx_input_port()
{
    setc(P_I2SX, XS1_SETC_INUSE_OFF);// turn PI2SX into input port
    setc(P_I2SX, XS1_SETC_INUSE_ON);
}

unsigned dsdMode = DSD_MODE_OFF;

struct {unsigned curSamFreq,curSamFreq2,audio_mode,command,echo_mode;} audio_state;

void config_system_for_sample_rate(client interface kmi_background_if i)
{

    change_sample_rate(audio_state.curSamFreq,1,i);


    if (power_state_get() == POWER_STATE_HIGH)
    {
#ifdef SHARC_ENABLED
            unsigned binlength = sharc_boot_start_c(audio_state.curSamFreq);

            if (binlength)
            {
                sharc_boot_wait_c(binlength);
#ifdef DEBUG_SHARC_BOOT
                i.boot_debug();
#endif

                if (!DFU_mode_active_c())
                 {
//                    for(;;)
//                    {
                    i2c_msi_write_reg_word(I2C_ADDRESS_8051U,I2C_MSG_TYPE_SHARC_BOOT,audio_state.curSamFreq,-1);
                    i.poke();
//                    wait_xc(10000000);
//                    }
                 }

            }



#else
            port_gpio_c(SHARC_RESET | CODEC_PATH , 0);  // holts SHARC in reset, connect directly to codecs
#endif
    }


}

struct { unsigned count,changes[16];} sample_rate = {0};

extern int DFU_reset_override;


void kmi_audio(chanend c_mix_out,client interface kmi_background_if i)
{
    unsigned curSamRes_DAC = STREAM_FORMAT_OUTPUT_1_RESOLUTION_BITS; /* Default to something reasonable */
//    unsigned curSamRes_ADC = STREAM_FORMAT_INPUT_1_RESOLUTION_BITS; /* Default to something reasonable - note, currently this never changes*/



    #ifdef ENABLE_CODECS

        i.port_gpio(0,CODEC_ADC_PDN);

    #endif


    #ifdef SHARC_ENABLED
       i.port_gpio(CODEC_MS | CODEC_PATH | SHARC_ENABLED_LED ,SHARC_RESET);
    #else
       i.port_gpio(CODEC_MS | SHARC_RESET | SPI_PATH_3 | CODEC_PATH,  SHARC_ENABLED_LED);
     #endif



       power_state_set(POWER_STATE_HIGH);


       audio_state.audio_mode = DEFAULT_FREQ;
       audio_state.curSamFreq = DEFAULT_FREQ;


             timer t; unsigned time;
             t :> time;
             t when timerafter(time+10000000) :> void;

       change_sample_rate(audio_state.curSamFreq,1,i);


       if (DFU_reset_override != 0x11042011)  // qqq
        {
#ifndef DO_FIRMWARE_CHECK_ON_STARTUP
            i2c_msi_write_reg_word(I2C_ADDRESS_8051U, I2C_MSG_TYPE_READY,0,-1);
#endif
            i2c_msi_write_reg_word(I2C_ADDRESS_8051U,I2C_MSG_TYPE_SHARC_BOOT,audio_state.curSamFreq,-1);
            i.poke();
        }


    for(;;)
    {


        switch(power_state_get())
        {
        case POWER_STATE_LOW:
                port_gpio_c(SHARC_RESET | CODEC_PATH,0);  // holts SHARC in reset, connect directly to codecs
            break;
        case POWER_STATE_HIGH:
            port_gpio_c(CODEC_PATH,0);
            break;
        }





#ifdef XSCOPE_DEBUG_POWER
                xscope_int(XSCOPE_POWER_SAMPFREQ,0);
#endif

         switch(audio_state.audio_mode)
         {
             case AUDIO_STOP_FOR_DFU:

                 i.port_gpio(CODEC_PATH | SHARC_RESET ,SPI_PATH_2);

                 set_i2sx_input_port();

                 unsafe{

#ifdef TDM_512_ENABLE
                 switch (audio_state.curSamFreq)
                 {
                     case 44100:
                     case 48000:
                         audio_state.command = deliver_tdm_512(c_mix_out);
                         break;
                     case 88200:
                     case 96000:
                         audio_state.command = deliver_tdm(c_mix_out);
                         break;
                 }
#else
                 audio_state.command = deliver_tdm_i2s(c_mix_out,&i2s_enabled);
#endif
                 }

//                 set_i2sx_input_port();
//                 audio_state.command = dummy_deliver(c_mix_out,audio_state.curSamFreq);
                 break;

             default:
#ifdef XSCOPE_DEBUG_POWER
                xscope_int(XSCOPE_POWER_SAMPFREQ,1);
#endif
                 unsafe{

                    config_audio_ports();
                    config_tdm_ports();
                     config_i2s_ports();


#ifdef TDM_512_ENABLE
                 switch (audio_state.curSamFreq)
                 {
                     case 44100:
                     case 48000:
                         audio_state.command = deliver_tdm_i2s_512(c_mix_out,&i2s_enabled);
                         break;
                     case 88200:
                     case 96000:
                         audio_state.command = deliver_tdm_i2s(c_mix_out,&i2s_enabled);
                         break;
                 }
#else
                 audio_state.command = deliver_tdm_i2s(c_mix_out,&i2s_enabled);
#endif
                 }
                 break;
         }

//         dfu_debug_put_c(audio_state.command);

#ifdef XSCOPE_MODE_1_BUG
         xscope_int(XSCOPE_MODE_1_COMMAND,audio_state.command);
#endif


         if (audio_state.command == SET_SAMPLE_FREQ)
         {
             audio_state.curSamFreq2 = inuint(c_mix_out);
             switch (audio_state.curSamFreq2)
             {
                 case AUDIO_STOP_FOR_DFU:
#ifdef XSCOPE_DEBUG_POWER
                xscope_int(XSCOPE_POWER_SAMPFREQ,2);
#endif
                i.port_gpio(CODEC_PATH | SHARC_RESET ,SPI_PATH_2);
                set_i2sx_input_port();

                dfu_debug_put_c(35);
                     audio_state.audio_mode = AUDIO_STOP_FOR_DFU;
                     break;
                 case AUDIO_START_FROM_DFU:
#ifdef XSCOPE_DEBUG_POWER
                xscope_int(XSCOPE_POWER_SAMPFREQ,3);
#endif
                     audio_state.audio_mode = audio_state.curSamFreq;
                     break;
                 default:
#ifdef XSCOPE_DEBUG_POWER
                xscope_int(XSCOPE_POWER_SAMPFREQ,4);
#endif
#ifdef XSCOPE_DEBUG_POWER
                xscope_int(XSCOPE_POWER_SAMPFREQ,audio_state.curSamFreq2);
#endif

#ifdef XSCOPE_MODE_1_BUG
         xscope_int(XSCOPE_MODE_1_COMMAND,audio_state.curSamFreq2);
#endif

                audio_state.curSamFreq = audio_state.curSamFreq2;
                sample_rate.changes[sample_rate.count++ & 15] = audio_state.curSamFreq;

                config_system_for_sample_rate(i);

                wait_xc(500000);  // wait 5ms to make similer to initial boot
//                deliver_tdm_i2s2(100);
                     break;
             }
             inuint(c_mix_out);

             outct(c_mix_out, XS1_CT_END);
         }
         else if(audio_state.command == SET_STREAM_FORMAT_OUT)
         {
             /* Off = 0
              * DOP = 1
              * Native = 2
              */
             dsdMode = inuint(c_mix_out);
             curSamRes_DAC = inuint(c_mix_out);

             inuint(c_mix_out);

             outct(c_mix_out, XS1_CT_END);
         }

    }


}


