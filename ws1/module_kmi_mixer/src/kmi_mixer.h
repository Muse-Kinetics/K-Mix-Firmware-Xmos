
#ifndef KMI_MIXER_H_
#define KMI_MIXER_H_

#include "customdefines.h"
#include "i2c_msi.h"
//#include "spi_master.h"



interface kmi_background_if {
  void port_gpio(int mask, int orval);
#ifdef DEBUG_SHARC_BOOT
  void boot_debug(void);
#endif
  void poke(void);
  void set_i2c_address(int address);

//  unsigned port_gpio_read(void);
#ifdef I2C_SQUARE_WAVE
  void square_wave();
#endif
};

enum {KS_TEST_LOW_START,KS_TEST_LOW_START2,KS_TEST_HIGH_START,KS_DFU_WAIT,KS_SHARC_BOOT_START,KS_SHARC_BOOT_WAIT,KS_SHARC_BOOT_FINISH,KS_TEST_FW_UPDATE,KS_ANNOUNCE_READY};

#define SEC 100000000

typedef struct {unsigned bootrequests,binlength,boot_time,bootcounts;} MISC;
extern MISC misc;


#define MAX_FLASH_MAP   20


void kmi_init(client interface kmi_background_if i,chanend chan_i2c_client);
void i2c_msi_set_address(int address);

void kmi_audio(chanend c_mix_out,client interface kmi_background_if i);


void kmi_background(server interface kmi_background_if i[2],chanend chan_i2c_client[NLINK],chanend chan_i2c_server[NLINK],unsigned NLINK,int i2c_address_slave);


unsigned short lib_build_num_request__bin_type(void *unsafe ptr);
unsigned short lib_build_num_request__bin_subtype(void *unsafe ptr);
unsigned char lib__message_type(void * unsafe ptr);
unsigned char lib__requester_address(void * unsafe ptr);
unsigned short lib_chunk_request__block_size(void * unsafe ptr);
unsigned short lib_chunk_request__block_number(void * unsafe ptr);
unsigned short lib_chunk_header__block_size(void * unsafe ptr);
unsigned short lib_chunk_header__block_number(void * unsafe ptr);
unsigned int lib_build_num__buildnum(void * unsafe ptr);
unsigned int lib_build_num__length(void * unsafe ptr);
void dfu_debug_msg(unsigned val1, unsigned val2);
void set_power_test_state(unsigned state,unsigned time);
void wait_xc(unsigned wait_time);




#ifdef I2C_SQUARE_WAVE
void i2c_square_wave(int khz);
#endif


#ifdef ADC_TRUTH_TABLE
FIXED_MCLK  MASTER/SLAVE  FS     CKS2    CKS1    CKS0
    0            S        48      0       0       0
    0            S        96      0       0       0
    0            M        48      0       1       0
    0            M        96      0       1       0
    1            S        48      0       0       0
    1            S        96      0       0       0
    1            M        48      0       1       1
    1            M        96      0       1       0
#endif



#define ADC_MASK_CKS2   ADC_CKS2    // CKS2 always 0
#define ADC_ORVAL_CKS2  0

#ifdef  MASTER_ADC
#define ADC_MASK_CKS1   0
#define ADC_ORVAL_CKS1  ADC_CKS1
#else
#define ADC_MASK_CKS1   ADC_CKS1
#define ADC_ORVAL_CKS1  0
#endif

#if defined(MASTER_ADC) && defined(FIXED_MCLK)
#define ADC_MASK_CKS0(sample_rate) (sample_rate>=88200 ? ADC_CKS0 : 0)
#define ADC_ORVAL_CKS0(sample_rate) (sample_rate>=88200 ? 0 : ADC_CKS0)
#else
#define ADC_MASK_CKS0(sample_rate)  ADC_CKS0
#define ADC_ORVAL_CKS0(sample_rate)  0
#endif

#define ADC_MASK(sample_rate) (ADC_MASK_CKS2 | ADC_MASK_CKS1 | ADC_MASK_CKS0(sample_rate))
#define ADC_ORVAL(sample_rate) (ADC_ORVAL_CKS2 | ADC_ORVAL_CKS1 | ADC_ORVAL_CKS0(sample_rate) )




#endif /* KMI_MIXER_H_ */
