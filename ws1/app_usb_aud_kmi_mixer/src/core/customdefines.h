/**
 * @file       customdefines.h
 * @brief      Defines relating to device configuration and customisation.
 *             For SU1 USB Audio Reference Design
 * @author     Ross Owen, XMOS Limited
 */
#ifndef _CUSTOMDEFINES_H_
#define _CUSTOMDEFINES_H_

#ifndef KMI
#define KMI
#endif

#ifdef XSCOPE
//#undef XSCOPE
#endif

// COMMON_FLAGS = -DKMI -DMIN_FREQ=44100 -DMAX_FREQ=96000 -DSKIP_FREQ=0 -DKMI_VOLUME_IN_CODECx

#define MIN_FREQ    44100
#ifdef SAMPLE_RATE_4400_ONLY
#define MAX_FREQ    44100
#else
#define MAX_FREQ    96000
#endif
#define SKIP_FREQ   0
#define KMI_VOLUME_IN_CODECx

// -DHW2  -DFIXED_MCLK -DSHARC_ENABLED -DBOOT_SHARC -DMASTER_XMOS -DMASTER_ADCx

#define HW2
#define FIXED_MCLK
#define SHARC_ENABLED
#define MASTER_XMOS
#define MASTER_ADCx
#define TDM_512_ENABLE

#define USE_SPI_MASTER

//#define REPORT_WRONG_SAMPLE_RATE    22050

#define DO_FIRMWARE_CHECK_ON_STARTUP
//#define DEBUG_SHARC_BOOT   // sends the config command to the shark

#define BUILD_NUM   0x103

#define BUILD_STRING2(num) #num"C"
#define BUILD_STRING(num) BUILD_STRING2(num)

//XCC_FLAGS_hw2_pdn2 = $(BUILD_FLAGS)  -DSPDIF=0 -save-temps $(COMMON_FLAGS)  -DMIDI -DPDN2

#define PDN2

/*
 * Device configuration option defines.  Build can be customised but changing and adding defines here
 *
 * Note, we check if they are already defined in Makefile
 */

/* Enable/Disable MIDI - Default is MIDI off */
#ifndef MIDI
#define MIDI 		0
#endif

#ifdef KMI
#define NUM_MIDI_JACKS  3
#else
#define NUM_MIDI_JACKS  1
#endif

/* Enable/Disable SPDIF output - Default is S/PDIF on */
#ifndef SPDIF
#define SPDIF		1
#endif

/* Audio class version to run in - Default is 2.0 */
#ifndef AUDIO_CLASS
#define AUDIO_CLASS (2)
#endif

/* Enable/disable fall back to Audio Class 1.0 when connected to FS hub. */
#ifndef AUDIO_CLASS_FALLBACK
#define AUDIO_CLASS_FALLBACK 1
#endif

/* Defines relating to channel count and channel arrangement (Set to 0 for disable) */
//:audio_defs
/* Number of USB streaming channels - Default is 4 in 4 out */
#ifndef NUM_USB_CHAN_IN
#define NUM_USB_CHAN_IN   (8)         /* Device to Host */
#endif
#ifndef NUM_USB_CHAN_OUT
#define NUM_USB_CHAN_OUT  (10)         /* Host to Device */
#endif

/* Number of IS2 chans to DAC..*/
#ifndef I2S_CHANS_DAC
#//define I2S_CHANS_DAC     (4)
#endif

/* Number of I2S chans from ADC */
#ifndef I2S_CHANS_ADC
//#define I2S_CHANS_ADC     (4)
#endif

/* Run the CODEC as slave, Xcore as master
 * Changing this define will cause CODECs to setup appropriately and XCore to be I2S slave
 */
#define CODEC_MASTER      0

/* Enable DFU interface, Note, requires a driver for Windows */
#define DFU             1

#define MIDI_SHIFT_TX   7


/* Master clock defines (in Hz) */
#define MCLK_441          (256*44100)   /* 44.1, 88.2 etc */
#define MCLK_48           (256*48000)   /* 48, 96 etc */

/* Maximum frequency device runs at */
#ifndef MAX_FREQ
#ifdef SAMPLE_RATE_4400_ONLY
#define MAX_FREQ                    MIN_FREQ
#else
#define MAX_FREQ                    (96000)
#endif
#endif

/* Index of SPDIF TX channel (duplicated DAC channels 1/2) */
#define SPDIF_TX_INDEX              (0)

/* Default frequency device reports as running at */
/* Audio Class 1.0 friendly freq */

#ifndef DEFAULT_FREQ
#ifdef SAMPLE_RATE_4400_ONLY
#define DEFAULT_FREQ                MIN_FREQ
#else
#define DEFAULT_FREQ                MAX_FREQ
#endif
#endif
//:
/***** Defines relating to USB descriptors etc *****/
//:usb_defs
#ifdef KMI
#define VENDOR_ID   (0x1f38) /* XMOS VID */    /* also defined in devicedefines.h */
#define PID_AUDIO_2 (0x0023) /* SKC_SU1 USB Audio Reference Design PID */
#define PID_AUDIO_1 (0x0023) /* SKC_SU1 Audio Reference Design PID */
#else
#define VENDOR_ID   (0x20B1) /* XMOS VID */
#define PID_AUDIO_2 (0x0008) /* SKC_SU1 USB Audio Reference Design PID */
#define PID_AUDIO_1 (0x0009) /* SKC_SU1 Audio Reference Design PID */
#endif
//:

/* Enable/Disable example HID code */
#define HID_CONTROLS       0

/* Enable/Disable SU1 ADC */
#define SU1_ADC_ENABLE     0

/* Enable ADC based *EXAMPLE* volume control */
#define ADC_VOL_CONTROL    0

#define FL_DEVICE_MICRON_N25Q128A \
{\
    139,            /*MICRON_N25Q128A*/\
    256,            /* x page size was 256 */\
    8192,          /* x num pages was 65536 */\
    3,              /* x address size */\
    3,              /* x log2 clock divider */\
    0x9f,           /* x SPI_RDID */\
    0,              /* id dummy bytes */\
    3,              /* x id size in bytes */\
    0x20BA18,           /* x device id */\
    0xd8,           /* x SPI_SE */\
    0,              /* full sector erase */\
    0x06,           /* x SPI_WREN */\
    0x04,           /* x SPI_WRDI */\
    PROT_TYPE_SR,       /* SR protection */\
    {{0x1c,0x0},{0,0}},     /* no values */\
    0x02,           /* SPI_PP */\
    0x0b,           /* SPI_READFAST */\
    1,              /* 1 read dummy byte */\
    SECTOR_LAYOUT_REGULAR,  /* sane sectors */\
    {65536,{0,{0}}},        /* regular sector size */\
    0x05,           /* SPI_RDSR */\
    0x01,           /* no SPI_WRSR */\
    0x01,           /* SPI_WIP_BIT_MASK */\
}


/* Define to use custom flash part not in tools by default
 * Device is M25P40 */
//#define DFU_FLASH_DEVICE   FL_DEVICE_MICRON_M25P40
#define DFU_FLASH_DEVICE   FL_DEVICE_MICRON_N25Q128A

#define CLKBLK_TDM_BCLK     XS1_CLKBLK_1
#define CLKBLK_FLASH_LIB    XS1_CLKBLK_2
#define CLKBLK_SPI_1        XS1_CLKBLK_2
#define CLKBLK_SPI_2        XS1_CLKBLK_3


#endif
