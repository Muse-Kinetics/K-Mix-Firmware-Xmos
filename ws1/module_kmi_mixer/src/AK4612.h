#ifndef AK4612_H_
#define AK4612_H_

#include "i2c_app.h"

#define REG_PM_1         0x00
#define REG_CONTROL_1   0x03
#define REG_CONTROL_2   0x04

#define TDM_MODE_0_STEREO   (0<<6)
#define TDM_MODE_1_TDM512   (1<<6)
#define TDM_MODE_2_TDM256   (2<<6)
#define TDM_MODE_3_TDM128   (3<<6)

#define LRCK_RISE   (0<<5)
#define LRCK_FALL   (1<<5)

#define O_24L_I_16R   (0 << 3)
#define O_24L_I_20R   (1 << 3)
#define O_24L_I_24R   (2 << 3)
#define O_24L_I_24L   (3 << 3)

#define DIGITAL_ATTENUATOR_TRANSITION_4096  (0 << 1)
#define DIGITAL_ATTENUATOR_TRANSITION_2048  (1 << 1)
#define DIGITAL_ATTENUATOR_TRANSITION_512   (2 << 1)
#define DIGITAL_ATTENUATOR_TRANSITION_256   (3 << 1)

#define SOFT_MUTE_DAC_FALSE 0
#define SOFT_MUTE_DAC_TRUE  1

#define SAMPLE_NORMAL_SPEED_MODE    (0 << 2)
#define SAMPLE_DOUBLE_SPEED_MODE    (1 << 2)
#define SAMPLE_QUAD_SPEED_MODE      (2 << 2)

#define DFS_0   (0<<2)
#define DFS_1   (1<<2)
#define DFS_2   (2<<2)
#define DFS_3   (3<<2)

#define CK_256_256_128  (0 << 4)
#define CK_384_256_128  (1 << 4)
#define CK_512_256_128  (2 << 4)

#define MCKO_ENABLE_FALSE   (0 << 6)
#define MCKO_ENABLE_TRUE    (1 << 6)

#define ACKS_DISABLE    (0 << 1)
#define ACKS_ENABLE     (1 << 1)

#define RSTN_LOW    (0 << 0)
#define RSTN_HIGH   (1 << 0)

#define DIV_1   (0)
#define DIV_2   (1)

#define MODE_23     (TDM_MODE_2_TDM256 | LRCK_RISE | O_24L_I_24L)
#define MODE_13     (TDM_MODE_1_TDM512 | LRCK_RISE | O_24L_I_24L)


extern i2c_block_entry init_ak4612_48k_vals[];
extern i2c_block_entry init_ak4612_96k_vals[];
extern i2c_block_entry init_ak4612_48k_tdm512_vals [];

extern i2c_block_entry reset_ak4612_a[];
extern i2c_block_entry reset_ak4612_b[];

#ifdef DEV_VERSION

#define INIT_AK4612_48K_COUNT   4
#define INIT_AK4612_96K_COUNT   4

#else

#define INIT_AK4612_48K_COUNT   3
#define INIT_AK4612_96K_COUNT   3

#endif



#endif /* AK4612_H_ */
