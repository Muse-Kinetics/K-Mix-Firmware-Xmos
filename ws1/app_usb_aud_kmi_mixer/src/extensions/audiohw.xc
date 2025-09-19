#include <xs1.h>
#include <xs1.h>
#include <platform.h>

#include "devicedefines.h"
#include "i2c.h"
#include "p_gpio.h"
#include "p_gpio_defines.h"

//on tile[0] : out port p_gpio = XS1_PORT_4C;

//:codec_init
void AudioHwInit(chanend ?c_codec)
{
//    i2c_master_init(p_i2c);

}
//:

//:codec_config
/* Called on a sample frequency change */
void AudioHwConfig(unsigned samFreq, unsigned mClk, chanend ?c_codec, unsigned dsdMode,
    unsigned samRes_DAC, unsigned samRes_ADC)
{
}

//:
