#include <xs1.h>
#include "customdefines.h"
#include "audio.h"
//#include "spi_master.h"

//extern spi_master_interface spi_if;

extern port p_tdm_in;
#define P_TDM_IN    p_tdm_in

#ifdef CODEC_LOOPBACK
#define P_TDM_OUT_LOOPBACK  p_tdm_out_loopback
#else
extern port p_tdm_out;
#define P_TDM_OUT p_tdm_out
#endif


extern in port p_for_mclk_count;
extern clock clk_audio_mclk;

#define P_TDM_BCLK  p_for_mclk_count
#define CLK_TDM_BCLK    clk_audio_mclk

extern port p_i2s_bclk_spi_cs;
extern port p_i2s_out_spi_mosi;
extern port p_i2s_in_spi_sck;
#define P_I2S_BCLK  p_i2s_bclk_spi_cs
#define P_I2S_OUT   p_i2s_out_spi_mosi
#define P_I2S_IN    p_i2s_in_spi_sck

extern clock clk_i2s_bclk;
#define CLK_I2S_BCLK    clk_i2s_bclk   // xxx should use clk_audio_bclk  no don't use clk_audio_bclk  clk_audio_bclk does not have to be declared
//extern clock clk_audio_mclk;
//#define CLK_I2S_BCLK    clk_audio_mclk   // xxx

#ifdef  MASTER_XMOS

//extern out buffered port:32 p_i2sx;
extern port p_i2sx;//xxx

#define P_I2SX p_i2sx

#else

#define P_SYNC p_sync

extern port p_sync;
extern in port p_sync2;

#endif

extern port p_spi_miso;

extern port p_spi_misc;


#define P_SPI_SS p_i2s_bclk_spi_cs
#define P_SPI_MOSI    p_i2s_out_spi_mosi
#define P_SPI_SCK   p_i2s_in_spi_sck
#define P_SPI_MISO  p_spi_miso

extern out port  p_32a;

extern clock clk_spi1;
extern clock clk_audio_mclk;
//#define CLK_SPI2    clk_audio_mclk

void config_audio_ports();
void config_spi_ports();
void set_port_a32(unsigned int mask,unsigned int orval);
void reset_spi_clock_pin(void);


#ifdef HW2
#define CODEC_MS            (1<<0)
#define SPI_PATH_1          (0)
#else
#define CODEC_MS            (0)
#define SPI_PATH_1          (1<<0)
#endif
#define SPI_PATH_2          (1<<1)
#define SPI_PATH_3          (1<<2)
#define SH_SPI_CS           (1<<3)
#define ADC_CKS0            (1<<4)
#define ADC_CKS1            (1<<5)
#define ADC_CKS2            (1<<6)
//#define CODEC_PDN           (1<<7)
#define SHARC_RESET         (1<<8)
#define I2S_SYNC            (1<<9)
#define CODEC_PATH          (1<<10)
#define LED1                (1<<11)
#define LED2                (1<<12)
#define TEST_POINT1         (1<<17)
#define TEST_POINT2         (1<<18)
#define SHARC_ENABLED_LED   LED2

#ifdef PDN2
#define ADC_PDN             (1<<7)
#define CODEC_PDN           (1<<9)
#define CODEC_ADC_PDN       (CODEC_PDN | ADC_PDN)
#else
#define CODEC_PDN           (1<<7)
#define CODEC_ADC_PDN       (CODEC_PDN)
#endif

#define settw(a,b) {__asm__ __volatile__("settw res[%0], %1": : "r" (a) , "r" (b));}
#define setc(a,b) {__asm__  __volatile__("setc res[%0], %1": : "r" (a) , "r" (b));}
#define setclk(a,b) {__asm__ __volatile__("setclk res[%0], %1": : "r" (a) , "r" (b));}
#define portin(a,b) {__asm__  __volatile__("in %0, res[%1]": "=r" (b) : "r" (a));}
#define portout(a,b) {__asm__  __volatile__("out res[%0], %1": : "r" (a) , "r" (b));}


