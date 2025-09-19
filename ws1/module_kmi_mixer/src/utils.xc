#include "xs1.h"

void delay(int count)
{
    timer t;
    unsigned time;
    t :> time;

    time += count;
    t when timerafter(time) :> int _;
}

