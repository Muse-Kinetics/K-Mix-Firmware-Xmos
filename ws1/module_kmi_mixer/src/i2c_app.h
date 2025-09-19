
#ifndef I2C_H_
#define I2C_H_

#include "kmi_mixer.h"
#include "i2c_msi.h"


#define I2C_ADDRESS_CODEC   (0x13<<1)
#define I2C_ADDRESS_SHARC   (0x1c<<1)
#define I2C_ADDRESS_8051U   (0x42<<1)
#define I2C_ADDRESS_8051L   (0x43<<1)
#define I2C_ADDRESS_XMOS    (0x44<<1)
#define I2C_ADDRESS_CLOCK   (0x60<<1)
#define I2C_ADDRESS_DAC     (0x7d<<1)

/*
 * Midi to 8051:    5 b1 b2 b3 b4
 * Midi from 8051:  6 b1 b2 b3 b4    b1-b4 are the standard usb packet protocol
 *
 *
 *
 */

#define I2C_MSG_TYPE_MIDI_TO_8051       5
#define I2C_MSG_TYPE_8051_TO_MIDI       6
#define I2C_MSG_TYPE_BUILDNUM_REQUEST       0x30
#define I2C_MSG_TYPE_BUILDNUM               0x31
#define I2C_MSG_TYPE_QUERY_FINISHED         0x32   // used to be QUERY_FINISHED
#define I2C_MSG_TYPE_CHUNK_REQUEST          0x33
#define I2C_MSG_TYPE_CHUNK_HEADER           0x34
#define I2C_MSG_TYPE_READY                  0x35   // new
#define I2C_MSG_TYPE_REBOOT                 0x36   // new
#define I2C_MSG_TYPE_SHARC_BOOT             0x37


#define I2C_MSG_TYPE_POWER_LOW              0x40
#define I2C_MSG_TYPE_POWER_HIGH             0x41
#define I2C_MSG_TYPE_POWER_OFF              0x42
#define	I2C_MSG_TYPE_MIDI_DEBUG_ON			0x45
#define	I2C_MSG_TYPE_MIDI_DEBUG_OFF			0x46









#define I2C_MIDI_DESTINATION    I2C_ADDRESS_8051U
//#define I2C_MIDI_DESTINATION    I2C_ADDRESS_CODEC
//#define I2C_MIDI_DESTINATION    I2C_ADDRESS_XMOS


//extern r_i2c r_i2c_if;


#define BLOCK_ENTRY_COUNT(var) sizeof(var)/sizeof(i2c_block_entry)

typedef struct  {unsigned char reg,single_val_array[1];} i2c_block_entry;
int block_init(int bus_address,i2c_block_entry block[],int count,client interface kmi_background_if i);
void test_i2c_lines(void);
void init_i2c();
int i2c_app_write_reg(unsigned char bus_address,unsigned char reg,unsigned char val,client interface i2c_msi_tx_if i);

int init_clock(unsigned char * unsafe vals,int start_reg,int end_reg,client interface kmi_background_if i);

#endif /* I2C_H_ */
