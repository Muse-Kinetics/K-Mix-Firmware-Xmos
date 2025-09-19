
#include <stdio.h>
#include <math.h>

#define TABLE_COUNT 64

#define SAMPLE_RATE 96000
#define SINE_FREQ   500
#define SINE_AMP    .1
#define BIT_REVERSE

#define SAMPLE_BITS 24
#define SLOT_BITS   32

int bitrev(unsigned int val)
{
    unsigned int rval = 0;
    unsigned int mask = pow(2,SLOT_BITS-1);
    
    for (int i=0;i<SLOT_BITS;i++)
    {
        rval >>= 1;
        
        if (val & mask)
            rval |= mask;
        
        val <<= 1;
        
    }
    return rval;
}

unsigned int ftohex_signed(float val)
{
    int rval;
    
    if (val>=1.0)
        val = nextafterf(val,0);

#ifdef BIT_REVERSE
    rval = bitrev((int) (val * pow(2,SAMPLE_BITS-1)) << (SLOT_BITS - SAMPLE_BITS));
#else
    rval = (int) (val * pow(2,SAMPLE_BITS-1)) << (SLOT_BITS - SAMPLE_BITS);
#endif
    
    return rval;
}

void generate_sin(void)
{
#ifdef TABLE_COUNT
    int table_count = TABLE_COUNT;
#else
    int table_count = SAMPLE_RATE/SINE_FREQ;
#endif
    int i;
    
    for (i=0;i<table_count;i++)
    {
        double sval =SINE_AMP * sin( 2.0 * 3.1415 * ((double) i/table_count));
        int fixed_val = (int) (sval * pow(2,24-1));
        
        printf("[%d]: %lf %x\n",i,sval,fixed_val );
        
    }
    
    printf("\nGenerating table for freq: %f\n",((float) SAMPLE_RATE)/table_count);
    
    printf("\n#define SINE_COUNT\t%d",table_count);
    
    printf("\nint sine_table[] = {");
    
    for (i=0;i<table_count;i++)
    {
        double sval = SINE_AMP * sin( 2.0 * 3.1415 * ((double) i/table_count));
        
        if (i)
            printf(",");
        
        if (!(i&15))
            printf("\n\t");
        
        printf("0x%x", ftohex_signed(sval));
        
    }
    
    printf("\n};\n");
    
}

#define DIVISIONS       256
#define DIVISIONS_LR    (DIVISIONS/2)
#define DIVISIONS_BK    (DIVISIONS_LR/64)
#define MASK_LR         2
#define MASK_BCLK       1

void generate_i2s(void)
{
    int phase_lr = 0;
    int phase_bk = 0;
    
    int lr_state = 0;
    int bk_state = 1;
    
    int i2s_state = 0;
    int i2s_seq = 0;
    
    for (int i=0;i<DIVISIONS;i++)
    {
        if ( !(phase_lr++ % DIVISIONS_LR) )
            lr_state ^= MASK_LR;
        
        if ( !(phase_bk++ % DIVISIONS_BK))
            bk_state ^= MASK_BCLK;
        
        
        i2s_seq = lr_state | bk_state;
        i2s_state &= 0xfffffff;
        i2s_state |= (i2s_seq<<28);
        
        if (!((i+1)%8))
        {
            printf("#define\tI2S_STATE_%d\t0x%08x\n",i/8,i2s_state & 0xffffffff);
        }
        i2s_state >>= 4;
    }
}

int main(int argc, const char * argv[])
{
    generate_sin();
    
    generate_i2s();
    return 0;
}
