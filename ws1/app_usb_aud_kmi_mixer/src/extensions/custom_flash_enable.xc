
extern out port p_gpio;

#include "p_gpio.h"
#include "p_gpio_defines.h"

#include "customdefines.h"

void stop_here();

/* Any code required to enable SPI flash access */
void DFUCustomFlashEnable()
{
#ifdef KMI
    stop_here();
#else
//#ifndef KMI
    int x;

    x = p_gpio_peek();
    x &= (~P_GPIO_SS_EN_CTRL);
    p_gpio_out(x);
#endif
}

/* Any code required to disable SPI flash access */
void DFUCustomFlashDisable()
{
#ifndef KMI
    int x;

    x = p_gpio_peek();
    x |= P_GPIO_SS_EN_CTRL;
    p_gpio_out(x);
#endif
}
