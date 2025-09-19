#ifndef XSCOPE_USER_H_
#define XSCOPE_USER_H_

#ifdef XSCOPE

#include "xscope.h"

//#define XSCOPE_DEBUG_I2C
//#define XSCOPE_DEBUG_MIDI
//#define XSCOPE_DEBUG_DFU
//#define XSCOPE_DEBUG_POWER
//#define XSCOPE_DEBUG_FEEDBACK
//#define XSCOPE_MODE_1_BUG

#ifdef XSCOPE_MODE_1_BUG

enum {XSCOPE_MODE_1_COMMAND,XSCOPE_MODE_1_AUDIO,XSCOPE_COUNT};
//enum {XSCOPE_MODE_1_AUDIO,XSCOPE_COUNT};

#define XSCOPE_REGISTER \
    XSCOPE_COUNT, \
    XSCOPE_DISCRETE, "commands",XSCOPE_UINT, "units", \
    XSCOPE_CONTINUOUS, "audio",XSCOPE_UINT, "units"

#endif


#ifdef XSCOPE_DEBUG_FEEDBACK

enum { XSCOPE_FEEDBACK_CLOCK,XSCOPE_FEEDBACK_SR,XSCOPE_ENDPOINT,XSCOPE_COUNT};

#define XSCOPE_REGISTER \
    XSCOPE_COUNT, \
    XSCOPE_CONTINUOUS, "clock",XSCOPE_UINT, "units", \
    XSCOPE_CONTINUOUS, "sr",XSCOPE_UINT, "units", \
    XSCOPE_CONTINUOUS, "endpoint",XSCOPE_UINT, "units"

#endif

#ifdef XSCOPE_DEBUG_POWER

#define XSCOPE_POWER            0
#define XSCOPE_POWER_DFU_TO     1
#define XSCOPE_POWER_DFU_FROM   2
#define XSCOPE_POWER_I2C_RX_LOW 3
#define XSCOPE_POWER_I2C_TX_HI  4
#define XSCOPE_POWER_SAMPFREQ   5
#define XSCOPE_POWER_DFU_READ   6

#define XSCOPE_REGISTER \
    7, \
    XSCOPE_CONTINUOUS, "power", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "dfu_to", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "dfu_from", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "i2c_rx_low",XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "i2c_rx_hi",XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "sampFreq",XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "dfu_read",XSCOPE_UINT, "units"

#endif

#ifdef XSCOPE_DEBUG_I2C

#define XSCOPE_USER_I2C_ADDRESS     0
#define XSCOPE_USER_I2C_ADDRESS_TX  1
#define XSCOPE_USER_DATA            2
#define XSCOPE_USER_TIME1           3
#define XSCOPE_USER_TIME2           4
#define XSCOPE_USER_PROGRESS        5
#define XSCOPE_USER_TX_COUNT        6


#define XSCOPE_REGISTER \
    7, \
    XSCOPE_CONTINUOUS, "i2c_address", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "i2c_address_tx", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "i2c_data", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "led_time1", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "led_time2", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "progress", XSCOPE_UINT, "units", \
    XSCOPE_CONTINUOUS, "tx_count", XSCOPE_UINT, "units"

#endif //XSCOPE_DEBUG_I2C


#ifdef XSCOPE_DEBUG_MIDI

#define XSCOPE_MIDI_LENGTH                  0
#define XSCOPE_MIDI_TX_BYTE                 1
#define XSCOPE_MIDI_RX_BYTE                 2
#define XSCOPE_MIDI_REMAINING_TO_DEVICE     3
#define XSCOPE_SERVE_MIDI_FROM_HOST         4
#define XSCOPE_REGISTER \
    5, \
    XSCOPE_CONTINUOUS, "midi_length", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "midi_tx_byte", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "midi_rx_byte", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "midi_remaining_to_device", XSCOPE_UINT, "units", \
    XSCOPE_CONTINUOUS, "serve_midi_from_host",XSCOPE_UINT, "units"

#endif //XSCOPE_DEBUG_MIDI

#ifdef XSCOPE_DEBUG_DFU

#define XSCOPE_DFU_SR_CHANGE               0
#define XSCOPE_DFU_PROGRESS                1

#define XSCOPE_REGISTER \
    1, \
    XSCOPE_CONTINUOUS, "dfu_sr_change", XSCOPE_UINT, "units",\
    XSCOPE_CONTINUOUS, "dfu_progress", XSCOPE_UINT, "units"

#endif //XSCOPE_DEBUG_MIDI



#endif  // XSCOPE



#endif /* XSCOPE_USER_H_ */
