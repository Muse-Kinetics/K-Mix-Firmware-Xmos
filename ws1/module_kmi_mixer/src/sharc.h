#include "kmi_mixer.h"

void sharc_master_boot(client interface kmi_background_if i);
void sharc_master_boot_debug();
void sharc_boot_wait(unsigned binlength);
unsigned sharc_boot_start(unsigned samplerate);
