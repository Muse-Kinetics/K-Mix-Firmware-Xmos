
#ifndef OSCILLATOR_H_
#define OSCILLATOR_H_

void internal_oscillator_shut_off(void);
void internal_oscillator_switch_to(void);
int oscillator_source(void);
void external_oscillator_switch_to();


#define DEFAULT_OSC_REGS    clock_config_enable_all_96
//#define DEFAULT_OSC_REGS    clock_config_enable_all_882
//#define DEFAULT_OSC_REGS    clock_config_enable_all_48
//#define DEFAULT_OSC_REGS    clock_config_enable_all_441

extern unsigned char clock_config_enable_all_96[];
extern unsigned char clock_config_enable_all_882[];
extern unsigned char clock_config_enable_all_48[];
extern unsigned char clock_config_enable_all_441[];
extern unsigned char clock_44p1_diff[];
extern unsigned char clock_48_diff[];
extern unsigned char clock_88p2_diff[];
extern unsigned char clock_96_diff[];



#endif /* OSCILLATOR_H_ */
