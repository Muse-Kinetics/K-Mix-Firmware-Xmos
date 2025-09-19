//#include "xs1.h"
#include "platform.h"
#include "cutils.h"
#include "customdefines.h"


typedef struct __attribute__((packed)) {unsigned char message_type,requester_address;unsigned short bin_type,bin_subtype;} LIB_BUILD_NUM_REQUEST;
typedef struct __attribute__((packed)) {unsigned char message_type,requester_address;unsigned short bin_type,bin_subtype,block_size,block_number;} LIB_CHUNK_REQUEST;

typedef struct __attribute__((packed)) {unsigned char message_type; unsigned int buildnum,length;} LIB_BUILD_NUM;
typedef struct __attribute__((packed)) {unsigned char message_type; short block_size,block_number;} LIB_CHUNK_HEADER;


unsigned char  lib__message_type(void *ptr) { return ((LIB_BUILD_NUM_REQUEST *) ptr)->message_type;}
unsigned short lib_build_num_request__bin_type(void *ptr) { return ((LIB_BUILD_NUM_REQUEST *) ptr)->bin_type;}
unsigned short lib_build_num_request__bin_subtype(void *ptr) { return ((LIB_BUILD_NUM_REQUEST *) ptr)->bin_subtype;}
unsigned char  lib__requester_address(void *ptr) { return ((LIB_BUILD_NUM_REQUEST *) ptr)->requester_address;}
unsigned short lib_chunk_request__block_size(void *ptr) { return ((LIB_CHUNK_REQUEST *) ptr)->block_size;}
unsigned short lib_chunk_request__block_number(void *ptr) { return ((LIB_CHUNK_REQUEST *) ptr)->block_number;}
unsigned short lib_chunk_header__block_size(void *ptr) { return ((LIB_CHUNK_HEADER *) ptr)->block_size;}
unsigned short lib_chunk_header__block_number(void *ptr) { return ((LIB_CHUNK_HEADER *) ptr)->block_number;}
unsigned int lib_build_num__buildnum(void *ptr) { return ((LIB_BUILD_NUM *) ptr)->buildnum;}
unsigned int lib_build_num__length(void *ptr) { return ((LIB_BUILD_NUM *) ptr)->length;}



/******************************  SPI  ****************************/


extern void configure_clock_src(unsigned int,unsigned int);
extern void configure_in_port(unsigned int,unsigned int);
extern void configure_out_port(unsigned int,unsigned int,unsigned int);
extern void set_port_inv(unsigned int);


void c_config_tdm_ports(void)
{
//    set_port_inv(PORT_MCLK_COUNT);
    configure_clock_src(CLKBLK_TDM_BCLK, PORT_MCLK_COUNT);
    configure_in_port (PORT_TDM_IN , CLKBLK_TDM_BCLK );
    configure_out_port (XS1_PORT_1G , CLKBLK_TDM_BCLK , 0);
}

typedef struct spi_master_interface
{
    unsigned blk1;
    unsigned blk2;
    unsigned mosi;
    unsigned sclk;
    unsigned miso;
} spi_master_interface;

spi_master_interface spi_if =
{
        CLKBLK_SPI_1,
        CLKBLK_SPI_2,
        XS1_PORT_1D,  // MOSI
        XS1_PORT_1C,    // Clock
        XS1_PORT_1A     // MISO
};

extern void sync_i2s_xc();

void sync_i2s_c()
{
    sync_i2s_xc();
}

void slave_select();
void slave_deselect();

void slave_select_c()
{
    slave_select();
}
void slave_deselect_c()
{
    slave_deselect();
}

void reset_spi_clock_pin(void);
void reset_spi_clock_pin_c(void)
{
    reset_spi_clock_pin();
}



void reset_debug_count();
void reset_debug_count_c()
{
    reset_debug_count();
}

void set_i2sx_input_port();

void set_i2sx_input_port_c()
{
    set_i2sx_input_port();
}

void set_i2s_enabled(unsigned state);

void set_i2s_enabled_c(unsigned state)
{
    set_i2s_enabled(state);
}

void wait_xc(unsigned wait_time);

void set_i2s_enabled_wait_c(unsigned state)
{
    set_i2s_enabled(state);
    wait_xc(5000);
}
extern unsigned i2s_enabled;
int get_i2s_enabled_c()
{
    return i2s_enabled;
}

void slave_select_debug();
void slave_select_debug_c()
{
    slave_select_debug();
}

void set_port_a32(unsigned int mask,unsigned int orval);
void port_gpio_c(unsigned and_val,unsigned or_val)
{
    set_port_a32(and_val,or_val);
}

void config_spi_ports();
void config_spi_ports_c()
{
    config_spi_ports();
}

unsigned sharc_boot_start(unsigned sampleRate);
unsigned sharc_boot_start_c(unsigned sampleRate)
{
    return (sharc_boot_start(sampleRate));
}

void sharc_boot_wait(unsigned binlength);
void sharc_boot_wait_c(unsigned binlength)
{
    sharc_boot_wait(binlength);
}

#ifdef USE_SPI_MASTER
void configure_spi();
void configure_spi_c()
{
    configure_spi();
}
#endif

int power_state = POWER_STATE_LOW;

void power_state_set(int state)
{
    power_state = state;
}
int power_state_get(void)
{
    return power_state;
}

void sync_feedback();
void sync_feedback_c()
{
    sync_feedback();
}
void dfu_debug_put(int val);
void dfu_debug_put_c(int val)
{
    dfu_debug_put(val);
}

extern unsigned int DFU_mode_active;
unsigned int DFU_mode_active_c()
{
    return DFU_mode_active;
}

unsigned flash_map_entry_flags();
unsigned flash_map_entry_flags_c(void)
{
    return flash_map_entry_flags();
}
extern int debug_count_stop;
void init_debug_count_stop_c()
{

    debug_count_stop = 43;
}



