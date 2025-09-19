#include <xs1.h>

#ifdef XSCOPE
#include <xscope.h>
#endif


#ifdef XSCOPE
void xscope_user_init()
{
    xscope_register(1, XSCOPE_CONTINUOUS, "audio", XSCOPE_UINT, "units");
     xscope_config_io(XSCOPE_IO_BASIC);
}
#endif


int main(void)
{

#ifdef XSCOPE
    xscope_user_init();
#endif


#ifdef XSCOPE
    for (int k=0;k<50;k++)
        xscope_int(0, k);
#endif

    return 0;

}

