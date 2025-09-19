
#ifndef LM49450_H_
#define LM49450_H_
#include "i2c_app.h"
//#include "audio.h"

#define REG_MODE_CONTROL        0x00
#define REG_CLOCK               0x01
#define REG_CP_DIV              0x02
#define REG_I2S_MODE            0x03
#define REG_I2S_CLOCK           0x04
#define REG_HEADPHONE_VOL       0x07
#define REG_LOUDSPEAKER_VOL     0x08

#define MCLOCK_DIVIDER_1    (1<<0)
#define MCLOCK_DIVIDER_2    (3<<0)

#define DAC_MODE_01         (1<<5)
#define DAC_MODE_10         (2<<5)
#define DEVICE_ENABLE       (1<<0)
#define DEVICE_DISABLE      (0<<0)

#define LMI_IS_SLAVE           (0<<0)
#define LMI_IS_MASTER          (3<<0)

#define I2S_LEFT_JUSTIFIED  (1<<0)

#define HEADPHONE_VOL_32    (31<<0)
#define LOUDSPEAKER_VOL_32  (31<<0)

#define CP_DIV_96KHZ        (75<<0)


extern i2c_block_entry init_lm49450_96k_vals[];
extern i2c_block_entry init_lm49450_48k_vals[];

#endif /* LM49450_H_ */
