#include <xs1.h>

#include <print.h>
#include "i2c.h"
#include "i2c_app.h"
#include "utils.h"

//r_i2c r_i2c_if = {
//    XS1_PORT_1L,
//    XS1_PORT_1I,
//    1000
//};

void init_i2c()
{
}

int i2c_app_write_reg(unsigned char bus_address,unsigned char reg,unsigned char val,client interface i2c_msi_tx_if i)
{
    unsigned char single_val_array[1] = {val};

    i.i2c_master_write_reg_buffer(bus_address,reg,single_val_array,1,I2C_NOTIFY_COMPLETION_NO);

//    if (!i2c_master_write_reg(bus_address,reg, single_val_array, 1, r_i2c_if))
//        return 0;

    return 1;

}


int block_init(int bus_address,i2c_block_entry block[],int count,client interface kmi_background_if i)
{
    for (int x=0; x<count; x++)
    {
        i2c_msi_write_reg_buffer(bus_address,block[x].reg,block[x].single_val_array,1,-1);
        i.poke();
         while(!i2c_queue_empty());
    }

    return 1;

}
#if 1
int init_clock(unsigned char * unsafe vals,int start_reg,int end_reg,client interface kmi_background_if i)
{
#ifdef I2C_SQUARE_WAVE
    i.square_wave();
#endif

    i2c_msi_write_reg_buffer(I2C_ADDRESS_CLOCK,start_reg,vals + start_reg,end_reg - start_reg + 1,-1);

    i.poke();
    while(!i2c_queue_empty());


    return 1;
}
#endif

#if 0
int init_clock(unsigned char vals[],int start_reg,int end_reg,client interface kmi_background_if i)
{
    int x=0;

//    count *=2;

    for (;;x=x+2)
    {
        unsigned char array[1];
        unsigned char reg = vals[x];
        array[0] = vals[x+1];

        if (reg < start_reg)
            continue;


//        printuintln(reg);
//        printhexln(array[0]);

        if (!i2c_master_write_reg(0x60, reg, array, 1, r_i2c_if))
            return 0;

        if (reg >= end_reg)
            return 1;

    }

    return 1;

}

#endif

#if 0

int init_clock(unsigned char vals[],int reg_last,client interface kmi_background_if i)
{
    int x=0;

    for(;;)
    {
        unsigned char array[1];
        unsigned char reg = vals[x];
        array[0] = vals[x+1];


//        printhex(reg);
//        printhexln(array[0]);

        if (!i2c_master_write_reg(0x60, reg, array, 1, r_i2c_if))
            return 0;

        if (reg == reg_last)
            return 1;

        x = x + 2;

    }

    return 1;

}
#endif

void test_i2c_lines(void)
{

}
