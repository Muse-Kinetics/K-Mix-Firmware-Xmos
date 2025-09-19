#include <xs1.h>
#include "ports.h"

#include "audio.h"
#include "spi_master.h"
#include "cutils.h"



port p_tdm_in = XS1_PORT_1F;

#ifdef CODEC_LOOPBACK
in port p_tdm_out_loopback = XS1_PORT_1G;
#else
port p_tdm_out = XS1_PORT_1G;
#endif

#ifdef USE_KMI_TDM_DEC
port p_tdm_bclk = XS1_PORT_1E;
clock clk_tdm_bclk = CLKBLK_TDM_BCLK;
#endif

port p_i2s_bclk_spi_cs = XS1_PORT_1B;
port p_i2s_in_spi_sck = XS1_PORT_1C;
port p_i2s_out_spi_mosi = XS1_PORT_1D;
clock clk_i2s_bclk = CLKBLK_SPI_2 ;

#ifdef  MASTER_XMOS
//out buffered port:32 p_i2sx = XS1_PORT_4C;// xxx changed to regular port from out buffe
port p_i2sx = XS1_PORT_4C;// xxx changed to regular port from out bufferred port
#else
port  p_sync = XS1_PORT_4C;
in port p_sync2 = XS1_PORT_4D;
#endif

port p_spi_miso = XS1_PORT_1A;
//clock clk_spi1 = XS1_CLKBLK_1;
//clock clk_spi2 = XS1_CLKBLK_2;

out port  p_32a                     = XS1_PORT_32A;

#ifdef MASTER_XMOS
port p_spi_misc = XS1_PORT_4D;
#endif



void config_buffered_port(port p,int width)
{
    setc(p, XS1_SETC_INUSE_OFF);
    setc(p, XS1_SETC_INUSE_ON);
    setc(p, XS1_SETC_BUF_BUFFERS);
    settw(p, width);

}
#if 1
void config_audio_ports()
{
    config_buffered_port(P_I2S_OUT,32);
    config_buffered_port(P_I2S_IN,32);
    config_buffered_port(P_TDM_IN,32);
    config_buffered_port(P_TDM_OUT,32);

}
#else
void config_audio_ports()
{
}
#endif
#if 1

void config_spi_ports()
{
    config_buffered_port(P_SPI_MOSI,8);
    config_buffered_port(P_SPI_SCK,8);
    config_buffered_port(P_SPI_MISO,8);
    set_i2sx_input_port_c();
//    P_I2SX :> void; // make an input port

}
#else
void config_spi_ports()
{
}
#endif

unsigned int a32_mirror = ~0;

extern spi_master_interface spi_if;


void set_port_a32(unsigned int mask,unsigned int orval)
{
    a32_mirror &= ~mask;
    a32_mirror |= orval;
    p_32a <: a32_mirror;
}

#ifdef USE_SPI_MASTER

void reset_spi_clock_pin(void)
{
    set_port_use_off(P_SPI_MISO);
    set_port_use_off(P_SPI_SCK);
    set_port_use_on(P_SPI_MISO);
    set_port_use_on(P_SPI_SCK);
//    return;

    // do this sequence to stop a clock that may hang if stopped
    set_clock_off(spi_if.blk2);
    set_clock_on(spi_if.blk2);
    stop_clock(spi_if.blk2);

//    return;

    config_buffered_port(P_SPI_MISO,32);


    configure_clock_src(spi_if.blk2, spi_if.sclk);
     configure_in_port(spi_if.miso, spi_if.blk2);
    clearbuf(spi_if.sclk);
    start_clock(spi_if.blk2);




//    for(;;);

}
#else
void reset_spi_clock_pin(void)
{

set_port_use_off(P_SPI_MISO);
set_port_use_off(P_SPI_SCK);
set_port_use_on(P_SPI_MISO);
set_port_use_on(P_SPI_SCK);

}

#endif

#ifdef UNUSED_FOR_NOW
void reset_spi_clock_pin(void)
{
//    setc(P_SPI_SCK, XS1_SETC_INUSE_OFF);
//    setc(P_SPI_MISO, XS1_SETC_INUSE_OFF);
//    setc(P_SPI_SCK, XS1_SETC_INUSE_ON);
//    setc(P_SPI_MISO, XS1_SETC_INUSE_ON);
    set_port_use_off(P_SPI_MISO);
    set_port_use_off(P_SPI_SCK);
    set_port_use_on(P_SPI_MISO);
    set_port_use_on(P_SPI_SCK);

    // do this sequence to stop a clock that may hang if stopped
    set_clock_off(clk_spi2);
    set_clock_on(clk_spi2);
    stop_clock(clk_spi2);

    config_buffered_port(P_SPI_MISO,32);

    configure_clock_src(clk_spi2, P_SPI_SCK);
    configure_in_port(P_SPI_MISO, clk_spi2);

    start_clock(clk_spi2);

//    for(;;);

}
#endif
