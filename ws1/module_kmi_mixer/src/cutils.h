
enum {POWER_STATE_LOW,POWER_STATE_HIGH,POWER_STATE_OFF};




void c_config_tdm_ports(void);
void sync_i2s_c(void);


void configure_spi_c();
void set_i2sx_input_port_c();
void set_i2s_enabled_c(unsigned state);
void set_i2s_enabled_wait_c(unsigned state);
int get_i2s_enabled_c();
void slave_select_c();
void slave_deselect_c();
void slave_select_debug_c();
void config_spi_ports_c();
void port_gpio_c(unsigned and_val,unsigned or_val);
unsigned sharc_boot_start_c(unsigned sampleRate);
void sharc_boot_wait_c(unsigned binlength);
void power_state_set(int state);
int power_state_get(void);
void sync_feedback_c();
void dfu_debug_put_c(int val);
unsigned int DFU_mode_active_c();
unsigned flash_map_entry_flags_c(void);
void init_debug_count_stop_c();










