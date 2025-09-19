
#ifndef FLASH_DATA_H_
#define FLASH_DATA_H_

#include "spi_master.h"

#include "customdefines.h"

#include "kmi_mixer.h"

//#define TEST_FIRMWARE_UPDATE    // send requests to ourselves


typedef struct {unsigned type,subtype,buildnum,flags,binlength;}  FLASH_ENTRY;
typedef union { FLASH_ENTRY e;unsigned char raw[sizeof(FLASH_ENTRY)];} FLASH_ENTRY_RAW;
typedef struct {FLASH_ENTRY_RAW fe;unsigned address;} FLASH_MAP_ENTRY;



typedef struct {unsigned count,format;FLASH_MAP_ENTRY entry[MAX_FLASH_MAP];} FLASH_MAP;


extern FLASH_MAP_ENTRY flash_map_entry;
extern FLASH_MAP flash_map;

#ifdef USE_SPI_MASTER
void flash_create_map(spi_master_interface &spi_if);
void flash_set_address(unsigned int address,spi_master_interface &spi_if);
#else
void flash_create_map();
#endif



int flash_find_entry(unsigned int seek_type,unsigned int seek_subtype);
void serve_remote_firmware_update(client interface kmi_background_if i,chanend chan_i2c_client);
int flash_8051_serve(I2C_MSI_EVENT * unsafe event,client interface kmi_background_if i);
void serve_remote_firmware_test(client interface kmi_background_if i);
#endif /* FLASH_DATA_H_ */
