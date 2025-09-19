#define TDM
#include <xclib.h>
#include "customdefines.h"


//#define ECHO_AUDIO
//#define TIMING_DATA
//#define SEND_SINE

//#define CODEC_LOOPBACK

#define I2S_ENABLE
#define TDM_ENABLE
#define ENABLE_CODECS


#define SINE_COUNT  64

#define I2S_STATE_0     0x33223322
#define I2S_STATE_1     0x33223322
#define I2S_STATE_2     0x33223322
#define I2S_STATE_3     0x33223322
#define I2S_STATE_4     0x33223322
#define I2S_STATE_5     0x33223322
#define I2S_STATE_6     0x33223322
#define I2S_STATE_7     0x33223322
#define I2S_STATE_8     0x33223322
#define I2S_STATE_9     0x33223322
#define I2S_STATE_10    0x33223322
#define I2S_STATE_11    0x33223322
#define I2S_STATE_12    0x33223322
#define I2S_STATE_13    0x33223322
#define I2S_STATE_14    0x33223322
#define I2S_STATE_15    0x33223322
#define I2S_STATE_16    0x11001100
#define I2S_STATE_17    0x11001100
#define I2S_STATE_18    0x11001100
#define I2S_STATE_19    0x11001100
#define I2S_STATE_20    0x11001100
#define I2S_STATE_21    0x11001100
#define I2S_STATE_22    0x11001100
#define I2S_STATE_23    0x11001100
#define I2S_STATE_24    0x11001100
#define I2S_STATE_25    0x11001100
#define I2S_STATE_26    0x11001100
#define I2S_STATE_27    0x11001100
#define I2S_STATE_28    0x11001100
#define I2S_STATE_29    0x11001100
#define I2S_STATE_30    0x11001100
#define I2S_STATE_31    0x11001100


#define I2S_512_LRHI    0x33332222
#define I2S_512_LRLO    0x11110000


#ifdef SYNC_CHECK
#define I2S_O(o,data) \
        asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
        P_I2S_OUT <: 1;
#else
#define I2S_O(o,data) \
        asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
        P_I2S_OUT <: sample;
#endif

#define I2S_I(i) \
        P_I2S_IN  :> sample;\
        asm("stw %0, %1[%2]"::"r"(sample),"r"(adc_buffer_address),"r"(i));



#define I2S_IO_D(i,o,data) \
        asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
        P_I2S_OUT <: sample;\
        P_I2S_IN  :> sample;\
        asm("stw %0, %1[%2]"::"r"(sample),"r"(adc_buffer_address),"r"(i));

#define I2S_IO_NONE(i,o,data) \
         P_I2S_OUT <: 0;\
        P_I2S_IN  :> sample;\

#define I2S_I_IGNORE P_I2S_IN :> sample;
#define I2S_O_IGNORE P_I2S_OUT <: 0;


#ifdef  I2S_ENABLE

#ifdef MASTER_XMOS
#define I2S_CLOCKS(val) \
        P_I2SX <: val;
#else
#define I2S_CLOCKS(val)
#endif




#else
#define I2S_LEFT(data)
#define I2S_RIGHT(data)
#define I2S_CLOCKS_HIGH1
#define I2S_CLOCKS_HIGH3
#define I2S_CLOCKS_HIGH4
#define I2S_CLOCKS_LOW4
#define I2S_CLOCKS(val)
#define I2S_IO(i,o,data)
#endif

#ifdef  TDM_ENABLE

//#define SINE_OUT

//unsigned int debug_sample;


#ifdef CODEC_LOOPBACK
#define TDM_OUT(data) p_tdm_out_loopback :> int _;
#else
#define TDM_OUT(data)\
     p_tdm_out <: data;
#endif

#ifdef SYNC_CHECK
#define TDM_O(o,data) \
        asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
        P_TDM_OUT <: 1;
#else

#ifdef SINE_OUT
#define TDM_O(o,data) \
        P_TDM_OUT <: SINE_TABLE[sindex & 63];

#else
#define TDM_O(o,data) \
        asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
        P_TDM_OUT <: sample;

#endif

//        P_TDM_OUT <: 1;

#define TDM_OZ(o,data) \
        P_TDM_OUT <: 0;


#endif

#define TDM_I(i) \
        P_TDM_IN :> sample; \
        asm("stw %0, %1[%2]"::"r"(sample),"r"(adc_buffer_address),"r"(i));

#define TDM_I_Z(i) \
        P_TDM_IN :> sample; \
        asm("stw %0, %1[%2]"::"r"(0),"r"(adc_buffer_address),"r"(i));


#define TDM_I_IGNORE \
        P_TDM_IN :> sample;

#define TDM_O_IGNORE \
        P_TDM_OUT <: 0;


#define TDM_IO_D(i,o,data) \
        P_TDM_IN :> sample; \
        asm("stw %0, %1[%2]"::"r"(sample),"r"(adc_buffer_address),"r"(i));\
        asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
        P_TDM_OUT <: sample;

#define TDM_O_D(i,o,data) \
        P_TDM_IN :> sample; \
        asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
        P_TDM_OUT <: sample;


#ifdef  ECHO_AUDIO

#define TDM_IO(i,o,data) \
        P_TDM_IN :> samp_in[i]; \
        P_TDM_OUT <: samp_in[o];

//            asm("ldw %0, %1[%2]":"=r"(dac_sample):"r"(dac_buffer_address),"r"(0));
//            asm("stw %0, %1[%2]"::"r"(adc_sample),"r"(adc_buffer_address),"r"(0));

 #endif


#ifdef  TIMING_DATA

#define TDM_IO(i,o,data) \
        P_TDM_IN :> samp_in[i]; \
        TDM_OUT(data)
#endif

#ifdef  SEND_SINE

#define TDM_IO(i,o,data) \
        P_TDM_IN :> samp_in[i]; \
        TDM_OUT(sample)

//       samp_in[i] = bitrev(samp_in[i]);

#endif

#define TDM_NULL \
        P_TDM_IN :> dummy_global; \
        TDM_OUT(0)



#else
#define TDM_IO(i,o,data)
#endif




//#ifdef  SEND_SINE

#define SINE1       unsigned int i=6,im;
#define SINE2       i++;
#define SINE3       im = i & (SINE_COUNT-1);
#define SINE4       samp_in[IN_SINE] = SINE_TABLE[im];

//#else

//#define SINE1
//#define SINE2
//#define SINE3
//#define SINE4
//#endif

#define I2S_BIT_PAT_HI  0x33223322
#define I2S_BIT_PAT_LO  0x11001100

#define I2S_TICKS_OUT   8
#define I2S_TICKS_IN    (I2S_TICKS_OUT-1)

#ifdef TDM
#define TICKS_OUT   26
#define TICKS_IN    29
#else
#define TICKS_OUT   33
#define TICKS_IN    32
#endif

#define IN_1    0
#define IN_2    1
#define IN_3    2
#define IN_4    3
#define IN_5    4
#define IN_6    5
#define IN_7    6
#define IN_8    7
#define IN_X    8
#define IN_SINE 9

#define OUT_1    0
#define OUT_2    1
#define OUT_3    2
#define OUT_4    3
#define OUT_5    4
#define OUT_6    5
#define OUT_7    6
#define OUT_8    7
#define OUT_9    8
#define OUT_10   9
#define OUT_SINE    9


unsigned  deliver_tdm_i2s2(unsigned count);
int init_codecs(int sample_freq,client interface kmi_background_if i);



