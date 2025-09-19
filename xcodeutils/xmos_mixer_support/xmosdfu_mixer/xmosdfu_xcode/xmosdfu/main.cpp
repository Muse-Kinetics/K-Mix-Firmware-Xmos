#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libusb.h"

/* the device's vendor and product id */
#define XMOS_VID 0x1f38
#define XMOS_L1_AUDIO2_PID 0x0023
#define XMOS_L1_AUDIO1_PID 0x0023
#define XMOS_L2_AUDIO2_PID 0x0023
#define XMOS_SU1_AUDIO2_PID 0x0023

unsigned int XMOS_DFU_IF = 0;

#define DFU_REQUEST_TO_DEV 0x21
#define DFU_REQUEST_FROM_DEV 0xa1

// Standard DFU requests
#define DFU_DETACH 0
#define DFU_DNLOAD 1
#define DFU_UPLOAD 2
#define DFU_GETSTATUS 3
#define DFU_CLRSTATUS 4
#define DFU_GETSTATE 5
#define DFU_ABORT 6

// XMOS alternate setting requests
#define XMOS_DFU_RESETDEVICE 		0xf0
#define XMOS_DFU_REVERTFACTORY 		0xf1
#define XMOS_DFU_RESETINTODFU	 	0xf2
#define XMOS_DFU_RESETFROMDFU 		0xf3
#define XMOS_DFU_SAVESTATE   		0xf5
#define XMOS_DFU_RESTORESTATE   	0xf6
#define XMOS_DFU_DNLOAD_DATA        0xf7
#define XMOS_DFU_READ_FLASH_ENTRY   0xf8
#define XMOS_DFU_READ_FLASH_FORMAT  0xf9

enum {TYPE_SHARC,TYPE_8051,TYPE_XMOS,TYPE_VERSION,TYPE_END=0xff};

const char *type_names[4];



static libusb_device_handle *devh = NULL;

static int find_xmos_device(unsigned int id)
{
    libusb_device *dev;
    libusb_device **devs;
    int i = 0;
    int found = 0;
    
    libusb_get_device_list(NULL, &devs);
    
    while ((dev = devs[i++]) != NULL)
    {
        struct libusb_device_descriptor desc;
        libusb_get_device_descriptor(dev, &desc);
        printf("VID = 0x%x, PID = 0x%x\n", desc.idVendor, desc.idProduct);
        if (desc.idVendor == XMOS_VID &&
            ((desc.idProduct == XMOS_L1_AUDIO1_PID) ||
             (desc.idProduct == XMOS_L1_AUDIO2_PID) ||
             (desc.idProduct == XMOS_SU1_AUDIO2_PID) ||
             (desc.idProduct == XMOS_L2_AUDIO2_PID)))
        {
            if (found == id)
            {
                if (libusb_open(dev, &devh) < 0)
                {
                    return -1;
                }
                else
                {
                    libusb_config_descriptor *config_desc = NULL;
                    libusb_get_active_config_descriptor(dev, &config_desc);
                    if (config_desc != NULL)
                    {
                        for (int j = 0; j < config_desc->bNumInterfaces; j++)
                        {
                            const libusb_interface_descriptor *inter_desc = ((libusb_interface *)&config_desc->interface[j])->altsetting;
                            if (inter_desc->bInterfaceClass == 0xFE && inter_desc->bInterfaceSubClass == 0x1)
                            {
                                XMOS_DFU_IF = j;
                            }
                        }
                    }
                    else
                    {
                        XMOS_DFU_IF = 0;
                    }
                }
                break;
            }
            found++;
        }
    }
    
    libusb_free_device_list(devs, 1);
    
    return devh ? 0 : -1;
}

int xmos_dfu_resetdevice(void) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, XMOS_DFU_RESETDEVICE, 0, 0, NULL, 0, 0); return 0;
}

int xmos_dfu_revertfactory(void) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, XMOS_DFU_REVERTFACTORY, 0, 0, NULL, 0, 0); return 0;
}

int xmos_dfu_resetintodfu(unsigned int interface) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, XMOS_DFU_RESETINTODFU, 0, interface, NULL, 0, 0); return 0;
}

int xmos_dfu_resetfromdfu(unsigned int interface) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, XMOS_DFU_RESETFROMDFU, 0, interface, NULL, 0, 0); return 0;
}

int dfu_detach(unsigned int interface, unsigned int timeout) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, DFU_DETACH, timeout, interface, NULL, 0, 0); return 0;
    return 0;
}

int dfu_getState(unsigned int interface, unsigned char *state) {
    libusb_control_transfer(devh, DFU_REQUEST_FROM_DEV, DFU_GETSTATE, 0, interface, state, 1, 0); return 0;
    return 0;
}

int dfu_getStatus(unsigned int interface, unsigned char *state, unsigned int *timeout,
                  unsigned char *nextState, unsigned char *strIndex) {
    unsigned int data[2];
    libusb_control_transfer(devh, DFU_REQUEST_FROM_DEV, DFU_GETSTATUS, 0, interface, (unsigned char *)data, 6, 0);
    
    *state = data[0] & 0xff;
    *timeout = (data[0] >> 8) & 0xffffff;
    *nextState = data[1] & 0xff;
    *strIndex = (data[1] >> 8) & 0xff;
    return 0;
}

int dfu_clrStatus(unsigned int interface) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, DFU_CLRSTATUS, 0, interface, NULL, 0, 0);
    return 0;
}

int dfu_abort(unsigned int interface) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, DFU_ABORT, 0, interface, NULL, 0, 0);
    return 0;
}


int xmos_dfu_save_state(unsigned int interface) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, XMOS_DFU_SAVESTATE, 0, interface, NULL, 0, 0);
    printf("Save state command sent\n");
    return 0;
}

int xmos_dfu_restore_state(unsigned int interface) {
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, XMOS_DFU_RESTORESTATE, 0, interface, NULL, 0, 0);
    printf("Restore state command sent\n");
    return 0;
}

typedef struct __attribute__((packed)) {uint32_t type,subtype,buildnum,flags,binlength,address;} DIR_ENTRY ;
typedef union { DIR_ENTRY d; unsigned char raw[sizeof(DIR_ENTRY)];} uDIR_ENTRY;

#define MAX_DIR_ENTRIES 20

int dir_entry_count = 0;

uint32_t flash_format;

uDIR_ENTRY dir_entry[MAX_DIR_ENTRIES];

void xmos_dfu_read_flash_directory(unsigned int interface)
{
    int i;
    
    libusb_control_transfer(devh, DFU_REQUEST_FROM_DEV, XMOS_DFU_READ_FLASH_FORMAT, i, interface, (unsigned char *) &flash_format,sizeof( flash_format), 0);

    
    for (i=0;i<MAX_DIR_ENTRIES;i++)
    {
        libusb_control_transfer(devh, DFU_REQUEST_FROM_DEV, XMOS_DFU_READ_FLASH_ENTRY, i, interface, (unsigned char *) &dir_entry[i],sizeof( uDIR_ENTRY), 0);
        
        if (dir_entry[i].d.type==TYPE_END)
        {
            dir_entry_count = i;
            return;
        }
    }

}


int dfu_download(unsigned int interface, unsigned int block_num, unsigned int size, unsigned char *data,unsigned int device_request) {
    //printf("... Downloading block number %d size %d\r", block_num, size);
    libusb_control_transfer(devh, DFU_REQUEST_TO_DEV, device_request, block_num, interface, data, size, 0);
    return 0;
}

int dfu_upload(unsigned int interface, unsigned int block_num, unsigned int size, unsigned char*data) {
    unsigned int numBytes = 0;
    numBytes = libusb_control_transfer(devh, DFU_REQUEST_FROM_DEV, DFU_UPLOAD, block_num, interface, (unsigned char *)data, size, 0);
    return numBytes;
}

int write_dfu_image(char *file,int device_request) {
    int i = 0;
    FILE* inFile = NULL;
    int image_size = 0;
    unsigned int num_blocks = 0;
    unsigned int block_size = 64;
    unsigned int remainder = 0;
    unsigned char block_data[256];
    
    unsigned char dfuState = 0;
    unsigned char nextDfuState = 0;
    unsigned int timeout = 0;
    unsigned char strIndex = 0;
    unsigned int dfuBlockCount = 0;
    
    inFile = fopen( file, "rb" );
    if( inFile == NULL ) {
        fprintf(stderr,"Error: Failed to open input data file %s.\n",file);
        return -1;
    }
    
    /* Discover the size of the image. */
    if( 0 != fseek( inFile, 0, SEEK_END ) ) {
        fprintf(stderr,"Error: Failed to discover input data file size.\n");
        return -1;
    }
    
    image_size = (int)ftell( inFile );
    
    if( 0 != fseek( inFile, 0, SEEK_SET ) ) {
        fprintf(stderr,"Error: Failed to input file pointer.\n");
        return -1;
    }
    
    num_blocks = image_size/block_size;
    remainder = image_size - (num_blocks * block_size);
    
    printf("... Downloading image (%s) to device\n", file);
    
    dfuBlockCount = 0;
    
    for (i = 0; i < num_blocks; i++) {
        printf("%d ",i);
        memset(block_data, 0x0, block_size);
        fread(block_data, 1, block_size, inFile);
        dfu_download(0, dfuBlockCount, block_size, block_data,device_request);
        dfu_getStatus(0, &dfuState, &timeout, &nextDfuState, &strIndex);
        dfuBlockCount++;
    }
    
    if (remainder) {
        memset(block_data, 0x0, block_size);
        fread(block_data, 1, remainder, inFile);
        dfu_download(0, dfuBlockCount, block_size, block_data,device_request);
        dfu_getStatus(0, &dfuState, &timeout, &nextDfuState, &strIndex);
    }
    
    // 0 length download terminates
    dfu_download(0, 0, 0, NULL,device_request);
    dfu_getStatus(0, &dfuState, &timeout, &nextDfuState, &strIndex);
    
    printf("\n... Download complete\n");
    
    return 0;
}

int read_dfu_image(char *file) {
    FILE *outFile = NULL;
    unsigned int block_count = 0;
    unsigned int block_size = 64;
    unsigned char block_data[64];
    
    outFile = fopen( file, "wb" );
    if( outFile == NULL ) {
        fprintf(stderr,"Error: Failed to open output data file.\n");
        return -1;
    }
    
    printf("... Uploading image (%s) from device\n", file);
    
    while (1) {
        unsigned int numBytes = 0;
        numBytes = dfu_upload(0, block_count, 64, block_data);
        if (numBytes == 0)
            break;
        fwrite(block_data, 1, block_size, outFile);
        block_count++;
    }
    
    fclose(outFile);
    
    return 0;
}

unsigned parse_hex_decimal(char *str)
{
    unsigned rval;
    
    //    char *ptr = str;
    
    //    while(*ptr) { *ptr = touppr(*ptr); ptr++; }
    
    if (strchr(str,'X') || strchr(str,'x'))
        sscanf(str,"%X",&rval);
    else
        sscanf(str,"%d",&rval);
    
    return rval;
}


#define MAX_HEADERS 100

struct {uint32_t type,subtype,buildnum,flags,length;} header[MAX_HEADERS];

int header_count = 0;


#define MAX_TEXT_LINE   1000
void get_flash_data(char *file_name)
{
    FILE *fs = fopen(file_name,"r");
    char line[MAX_TEXT_LINE+1];
    
    if (!fs)
    {
        printf("Could not open flashdata.txt\n");
        return;
    }
    
    //    return make_debug_bin(fd);
    
    while(fgets(line,MAX_TEXT_LINE,fs))
    {
        int count;
        char filepath[1000];
        
        
        if (strlen(line) && line[0] != '\n' && line[0] != '#')
        {
            char *pch = strtok (line," \t");
            
            
            
            header[header_count].type = parse_hex_decimal(pch);
            pch = strtok (NULL, " \t");
            header[header_count].subtype = parse_hex_decimal(pch);
            pch = strtok (NULL, " \t");
            header[header_count].buildnum = parse_hex_decimal(pch);
            pch = strtok (NULL, " \t");
            header[header_count].flags = parse_hex_decimal(pch);

            switch(header[header_count].type)
            {
                case TYPE_8051:
                case TYPE_SHARC:
                    pch = strtok (NULL, " \t");
                    sscanf(pch,"%s",filepath);
                    header_count++;
                    break;
                case TYPE_XMOS:
                case TYPE_VERSION:
                    header_count++;
                    break;
                default:
                    break;
                    
            }
        }
        
    }
}

unsigned int get_build_num(int type,int subtype)
{
    int i;
    for (i=0;i<header_count;i++)
        if (header[i].type ==type && header[i].subtype == subtype)
            return header[i].buildnum;
    
    return 0;
}
void show_flash_contents()
{
    
    printf("Device flash Contents:\n\n");
    
    for (int i=0;i<dir_entry_count;i++)
    {
        printf("%2d %s %d %x(%d)\n",i+1,type_names[dir_entry[i].d.type],dir_entry[i].d.subtype,dir_entry[i].d.buildnum,dir_entry[i].d.buildnum);
        
    }
}
int flash_check(int type,int subtype,int buildnum)
{
    for (int i=0;i<dir_entry_count;i++)
    {
        if (dir_entry[i].d.type == type && dir_entry[i].d.subtype == subtype && dir_entry[i].d.buildnum == buildnum)
            return 1;
    }
    
    return 0;
    
}

#define XMOSDFU_ERR_NONE                0
#define XMOSDFU_ERR_MISMATCH_FW         1
#define XMOSDFU_ERR_MISMATCH_DATA       2
#define XMOSDFU_ERR_MISMATCH_BOTH       3
#define XMOSDFU_ERR_ARGUMENT            4
#define XMOSDFU_ERR_LIBUSB              5
#define XMOSDFU_ERR_DEVICE_OPEN         6
#define XMOSDFU_ERR_INTERFACE           7
#define XMOSDFU_ERR_BUILD_MISMATCH      8
#define XMOSDFU_ERR_DFU_OPEN            9


int main(int argc, char **argv) {
    int r = 1,argi=1;
    int rval = XMOSDFU_ERR_NONE;
    
//    unsigned char dfuState = 0;
//    unsigned char nextDfuState = 0;
//    unsigned int timeout = 0;
//    unsigned char strIndex = 0;
    
    unsigned int download_boot = 0;
    unsigned int download_data = 0;
    unsigned int flashdata = 0;
    unsigned int upload = 0;
    unsigned int revert = 0;
    unsigned int save = 0;
    unsigned int restore = 0;
    
    char *firmware_filename_boot = (char *) "upgrade.bin";
    char *firmware_filename_data = (char *) "upgrade.bin";
    char *flashdata_text_filename = (char *) "flashdata.txt";
    
    type_names[0] = "TYPE_SHARC";
    type_names[1] = "TYPE_8051";
    type_names[2] = "TYPE_XMOS";
    type_names[3] = "TYPE_VERSION";

    
    struct libusb_device_descriptor device_desc;
    
    
    system("pwd");
    
    if (argc < 2) {
        fprintf(stderr, "No options passed to dfu application\n");
        
//        download = 1;
//        fprintf(stderr, "using --download %s\n",firmware_filename);
        return -1;
    }
    
    argi = 1;
    
    while( argi < argc)
    {
        
        if (strcmp(argv[argi],"--flashdata") == 0)
        {
            if (argv[argi+1]) {
                flashdata_text_filename = argv[argi+1];
                argi += 2;
            } else {
                fprintf(stderr, "No filename specified for flashdata option\n");
                return XMOSDFU_ERR_ARGUMENT;
            }
            flashdata = 1;
            
        } else
        if (strcmp(argv[argi], "--downloadboot") == 0) {
            if (argv[argi+1]) {
                firmware_filename_boot = argv[argi+1];
                argi += 2;
            } else {
                fprintf(stderr, "No filename specified for download option\n");
                return XMOSDFU_ERR_ARGUMENT;
            }
            download_boot = 1;
        } else
            if (strcmp(argv[argi], "--downloaddata") == 0) {
                if (argv[argi+1]) {
                    firmware_filename_data = argv[argi+1];
                    argi += 2;
                } else {
                    fprintf(stderr, "No filename specified for download option\n");
                    return -1;
                }
                download_data = 1;
        
            
        } else if (strcmp(argv[argi], "--upload") == 0) {
            if (argv[argi]) {
                firmware_filename_boot = argv[argi+1];
                argi += 2;
            } else {
                fprintf(stderr, "No filename specified for upload option\n");
                return XMOSDFU_ERR_ARGUMENT;
            }
            upload = 1;
        } else if (strcmp(argv[argi], "--revertfactory") == 0) {
            revert = 1;
            argi += 1;
        }
        else if(strcmp(argv[argi], "--savecustomstate") == 0)
        {
            save = 1;
            argi += 1;
        }
        else if(strcmp(argv[argi], "--restorecustomstate") == 0)
        {
            restore = 1;
            argi += 1;
        }
        else {
            fprintf(stderr, "Invalid option[%s] passed to dfu application\n",argv[argi]);
            return XMOSDFU_ERR_ARGUMENT;
        }
    }

    
    
    r = libusb_init(NULL);
    if (r < 0) {
        fprintf(stderr, "failed to initialise libusb\n");
        return XMOSDFU_ERR_LIBUSB;
    }
    
    r = find_xmos_device(0);
    if (r < 0) {
        fprintf(stderr, "Could not find/open device\n");
        return XMOSDFU_ERR_DEVICE_OPEN;
    }
    
    r = libusb_claim_interface(devh, XMOS_DFU_IF);
    if (r < 0) {
        fprintf(stderr, "Error claiming interface %d %d\n", XMOS_DFU_IF, r);
        return XMOSDFU_ERR_INTERFACE;
    }
        
    printf("XMOS DFU application started - Interface %d claimed\n", XMOS_DFU_IF);
    
    int libusb_get_device_descriptor(libusb_device *dev,
                                     struct libusb_device_descriptor *desc);
    
    libusb_device *libusb_device = libusb_get_device(devh);
    
    libusb_get_device_descriptor(libusb_device,&device_desc);


    printf("Attached device version is: %08x\n\n",device_desc.bcdDevice);
    
    
    xmos_dfu_read_flash_directory(XMOS_DFU_IF);
    
    show_flash_contents();

    if (flashdata)
    {
        int boot_valid = 1,data_valid = 1;
        
        get_flash_data(flashdata_text_filename);
        printf("\n%s contents:\n\n",flashdata_text_filename);
        
        for (int i=0;i<header_count;i++)
        switch(header[i].type)
        {
            case TYPE_SHARC:
            case TYPE_8051:
                printf("%s %d %x(%d)\n",type_names[header[i].type],header[i].subtype,header[i].buildnum,header[i].buildnum);
                if (!flash_check(header[i].type,header[i].subtype,header[i].buildnum))
                    data_valid = 0;
                break;
            case TYPE_XMOS:
                printf("%s %d %x(%d)\n",type_names[header[i].type],header[i].subtype,header[i].buildnum,header[i].buildnum);
                if (header[i].buildnum != device_desc.bcdDevice)
                    boot_valid = 0;
                break;
            case TYPE_VERSION:
                printf("%s %d %x(%d)\n",type_names[header[i].type],header[i].subtype,header[i].buildnum,header[i].buildnum);
                break;
        }
        
        if (!boot_valid && !data_valid)
        {
            rval = XMOSDFU_ERR_MISMATCH_BOTH;
        } else
            if (!boot_valid)
                rval = XMOSDFU_ERR_MISMATCH_FW;
        else
            if (!data_valid)
                rval = XMOSDFU_ERR_MISMATCH_DATA;
        
    }
    
    
#if 0
    libusb_release_interface(devh, 0);
    libusb_close(devh);
    libusb_exit(NULL);
    
    return true;
#endif
    
    
    
    /* Dont go into DFU mode for save/restore */
    if(save)
    {
        xmos_dfu_save_state(XMOS_DFU_IF);
    }
    else if(restore)
    {
        xmos_dfu_restore_state(XMOS_DFU_IF);
    }
    else
    if (download_boot || download_data || upload || revert)
    {
        
        printf("Detaching device from application mode.\n");
        xmos_dfu_resetintodfu(XMOS_DFU_IF);
        
        libusb_release_interface(devh, XMOS_DFU_IF);
        libusb_close(devh);
        
        
        printf("Waiting for device to restart and enter DFU mode...\n");
        
        // Wait for device to enter dfu mode and restart
        system("sleep 10");
        
        // NOW IN DFU APPLICATION MODE
        
        r = find_xmos_device(0);
        if (r < 0) {
            fprintf(stderr, "Could not find/open device\n");
            return -1;
        }
        
        r = libusb_claim_interface(devh, 0);
        if (r != 0)
        {
            fprintf(stderr, "Error claiming interface 0\n");
            
            switch(r)
            {
                case LIBUSB_ERROR_NOT_FOUND:
                    printf("The requested interface does not exist'n");
                    break;
                case LIBUSB_ERROR_BUSY:
                    printf("Another program or driver has claimed the interface\n");
                    break;
                case LIBUSB_ERROR_NO_DEVICE:
                    printf("The device has been disconnected\n");
                    break;
                case LIBUSB_ERROR_ACCESS:
                    printf("Access denied\n");
                    break;
                default:
                    printf("Unknown error code:  %d\n", r);
                    break;
            }
            
            return r;
        }
        
        printf("... DFU firmware upgrade device opened\n");
        
        if (download_boot) {
            write_dfu_image(firmware_filename_boot,DFU_DNLOAD);
        }
        
        if (download_data) {
            write_dfu_image(firmware_filename_data,XMOS_DFU_DNLOAD_DATA);
        }
        
        if (upload) {
            read_dfu_image(firmware_filename_boot);
        } else if (revert) {
            printf("... Reverting device to factory image\n");
            xmos_dfu_revertfactory(); 
            // Give device time to revert firmware
            system("sleep 2");
        }
        
        xmos_dfu_resetfromdfu(XMOS_DFU_IF);
        
        printf("... Returning device to application mode\n");
    }
    // END OF DFU APPLICATION MODE
    
    libusb_release_interface(devh, 0);
    libusb_close(devh);
    libusb_exit(NULL);
    
    return rval;
}
