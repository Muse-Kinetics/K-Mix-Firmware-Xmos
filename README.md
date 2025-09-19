# K-Mix XMOS Firmware

This repository contains the XMOS firmware for the K-Mix audio mixer hardware. The firmware implements a USB Audio Class 2.0 compliant device with comprehensive mixing capabilities, I2C communication with other system components, and MIDI support.

## Project Overview

The K-Mix XMOS firmware was originally developed by Chuck Gatzke with minimal documentation. This README documents the structure and functionality based on code analysis and reverse engineering.

### Hardware Platform
- **Target**: XMOS XS1-SU01A-FB96 (Single-tile XS1-L1A processor + USB peripheral)
- **Architecture**: Single-core system with dedicated USB tile
- **Flash**: Micron N25Q128A SPI flash (128Mb)
- **External Interfaces**: I2C, I2S, TDM, SPI, GPIO, USB 2.0

### XMOS Tools Version
- **xTIMEcomposer**: Version 13.2
- **Toolchain**: XTC 13.x series

### USB Device Identity
The firmware properly identifies itself to USB hosts as:
- **Vendor**: "Keith McMillen Instruments" 
- **Product**: "K-Mix"
- **Device Version**: 0x0103

## Project Structure

### Workspace Layout
```
ws1/                          # Main XMOS workspace
├── app_usb_aud_kmi_mixer/    # Primary K-Mix application
├── app_kmi_i2c/              # I2C interface application 
├── app_factory_image_programmer/ # Factory programming utility
├── module_kmi_mixer/         # Core K-Mix functionality
├── module_usb_audio/         # USB Audio Class 2.0 implementation
├── [various other modules]   # Standard XMOS modules
└── Documentation/            # Module documentation

xcodeutils/                   # macOS development utilities
├── xmos_mixer_support/       # DFU and flash programming tools
├── debug_log_comment/        # Debug utilities
└── sinedata/                 # Audio test generation
```

## Main Applications

### 1. app_usb_aud_kmi_mixer (Primary Application)
- **Purpose**: Main K-Mix USB audio device firmware
- **Target File**: `src/core/kmi_mixer.xn`
- **Entry Point**: `main.xc` in `module_usb_audio`
- **Key Features**:
  - USB Audio Class 2.0 compliant (8 in, 10 out channels)
  - Sample rates: 44.1kHz to 96kHz
  - Real-time audio mixing and processing
  - I2C communication with SHARC DSP and other components
  - MIDI interface (3 virtual jacks)
  - DFU (Device Firmware Update) support
  - GPIO control and monitoring

### 2. app_kmi_i2c
- **Purpose**: Standalone I2C interface application
- **Entry Point**: `app_kmi_i2c.xc`
- **Function**: Dedicated I2C communication handler

### 3. app_factory_image_programmer
- **Purpose**: Factory programming and initialization
- **Function**: Flash programming and device setup utilities

## Key Modules

### module_kmi_mixer
- **Core Functionality**: K-Mix specific audio processing and control
- **Key Files**:
  - `kmi_mixer.h/xc`: Main mixer interface and background tasks
  - `kmi_audio.h/xc`: Audio processing pipeline
  - `sharc.h/xc`: SHARC DSP communication
  - `ports.h/xc`: Hardware port management
  - `AK4612.h/xc`: Codec interface (AKM AK4612)
  - `LM49450.h/xc`: Headphone amplifier control
  - `flash_data.h/xc`: Flash memory management

### module_usb_audio
- **Purpose**: USB Audio Class 2.0 implementation
- **Key Components**:
  - Audio buffering and streaming
  - Endpoint management
  - Clock domain crossing
  - Feedback generation
  - MIDI over USB

## Hardware Configuration

### Port Assignments (from kmi_mixer.xn)
```
XS1_PORT_1A  - SPI_MISO
XS1_PORT_1B  - SPI_SS / I2S_BCLK
XS1_PORT_1C  - SPI_CLK / I2S_ADC
XS1_PORT_1D  - SPI_MOSI / I2S_DAC
XS1_PORT_1E  - TDM_BCLK / MCLK_COUNT
XS1_PORT_1F  - TDM_IN
XS1_PORT_1G  - TDM_OUT
XS1_PORT_1L  - I2C_SCL
XS1_PORT_1I  - I2C_SDA
XS1_PORT_32A - GPIO
```

### Clock Configuration
- **Master Clock**: 24MHz crystal oscillator
- **System Frequency**: 500MHz
- **Reference Frequency**: 100MHz
- **Audio Master Clocks**: 
  - 44.1kHz family: 11.2896MHz (256 × 44.1kHz)
  - 48kHz family: 12.288MHz (256 × 48kHz)


### Compiler Flags (from Makefile)
```
-DFLASH_MAX_UPGRADE_SIZE=64*1024
-DKMI -DMIDI -DIAPx
-DSPDIF=0
-DHKW2 -DFIXED_MCLK -DSHARC_ENABLED
-DMASTER_XMOS -DTDM_512_ENABLE
```

### Key Defines (from customdefines.h)
- `KMI`: Enable K-Mix specific functionality and USB branding
- `HW2`: Hardware revision 2
- `FIXED_MCLK`: Fixed master clock mode
- `SHARC_ENABLED`: Enable SHARC DSP communication
- `MASTER_XMOS`: XMOS is I2S master
- `TDM_512_ENABLE`: Enable 512-slot TDM mode
- `BUILD_NUM 0x103`: Firmware build number

## XMOS Architecture Explained

### How XMOS Works
XMOS is **NOT** a traditional multi-core processor. Instead, it uses:

- **Single Physical Core** with **hardware multithreading**
- **Cooperative multitasking** - threads yield control voluntarily  
- **Deterministic timing** - perfect for real-time audio
- **Communicating Sequential Processes (CSP)** - threads communicate via channels

### This Project's Application Model
**There is only ONE application**: `app_usb_aud_kmi_mixer`

The other "apps" in the workspace are:
- `app_kmi_i2c` - **Separate standalone utility** (not used in main firmware)  
- `app_factory_image_programmer` - **Development/factory tool** (not part of runtime)

When you build `app_usb_aud_kmi_mixer`, you get **one executable** (`.xe` file) that contains **multiple threads** running concurrently.

### Threading Architecture (All in One Application)
The `main.xc` file creates these concurrent threads using XC's `par` statements:

```xc
par {
    // Thread 1: USB Device Layer
    XUD_Manager(...);           
    
    // Thread 2: USB Audio Buffering  
    buffer(...);                
    
    // Thread 3: USB Endpoint 0 (Control)
    Endpoint0(...);             
    
    // Thread 4: Audio Decoupling
    decouple(...);              
    
    // Thread 5: KMI Background Tasks
    kmi_background(...);        
    
    // Thread 6: KMI Audio Processing  
    kmi_audio(...);             
    
    // Thread 7: I2C Communication
    // (embedded in kmi_background)
}
```

### Audio Signal Flow
1. **USB Host** ↔ **USB Audio Module** (10 channels out, 8 channels in)
2. **USB Audio** ↔ **KMI Audio Processing** (mixing, effects, routing)
3. **KMI Audio** ↔ **I2S Codecs** (AK4612 stereo codec)
4. **KMI Audio** ↔ **TDM Interface** (communication with SHARC DSP)
5. **I2C Bus** → **System Control** (codec config, GPIO, SHARC control)

### Build Output
Building `app_usb_aud_kmi_mixer` produces:
- **Single `.xe` executable** containing all threads
- **One binary** that runs on the XMOS chip
- **All functionality** integrated into one application

## Multi-Processor Architecture

### The Complete K-Mix System
K-Mix is **NOT** just an XMOS device - it's a **4-processor system**:

1. **XMOS XS1-SU01A-FB96** (This firmware) - Main audio processing and USB interface
2. **SHARC ADSP-21489** - High-performance DSP for audio effects and mixing
3. **C8051F380 (0908)** - Control board microcontroller (MIDI, UI, system control)
4. **C8051F380 (0909)** - Audio board microcontroller (preamp gain, zero-cross detection)

### Processor Communication
- **XMOS ↔ SHARC**: TDM audio interface + I2C control
- **XMOS ↔ 8051s**: I2C bus (system control and status)
- **Host ↔ XMOS**: USB Audio Class 2.0
- **User ↔ 8051 (0908)**: MIDI, physical controls

### Firmware Distribution System

#### Flash Data Structure (flashdata.txt)
The K-Mix uses a sophisticated firmware distribution system managed by the XMOS:

```
# Type    Subtype     BuildNum    Flags    Filepath
# 0 = SHARC DSP firmware (sample rate specific)
# 1 = 8051 microcontroller firmware  
# 2 = XMOS version metadata
# 3 = Global version metadata

# SHARC DSP - Sample rate specific binaries
0    44100    0x010035    0    sharc_candidates/debug/wait/KMIX_21489_DSP_44p1KHz.ldr
0    48000    0x010035    0    sharc_candidates/debug/wait/KMIX_21489_DSP_48KHz.ldr
0    88200    0x010035    0    sharc_candidates/debug/wait/KMIX_21489_DSP_88p2KHz.ldr
0    96000    0x010035    0    sharc_candidates/debug/wait/KMIX_21489_DSP_96KHz.ldr

# 8051 Microcontrollers
1    0        0x20116     0    8051_candidates/0909_K_MIX_Firmware_v2.1.16.bin  # Audio board
1    1        0x20115     0    8051_candidates/0908_K-Mix_Firmware_v2.1.15.bin  # Control board
1    2        0           0    8051_candidates/flashdebug.bin                   # Debug utility

# Version metadata
2    0        0x0101      0    # XMOS firmware version
3    0        0x010000    0    # Global system version
```

#### Firmware Deployment Process
The `kmix_hw2_1_01.command` script orchestrates the complete system firmware update:

1. **Preparation Phase**:
   ```bash
   # Set XMOS tools environment
   source /applications/XMOS_SetEnv13.sh
   
   # Build flash data from flashdata.txt
   flashdata flashdata.txt  # → flashdata.bin (915KB multi-processor firmware bundle)
   ```

2. **XMOS Flash Image Generation**:
   ```bash
   # Create factory boot image
   xflash --factory kmix_hw2_1_01.xe --spi-spec MICRON_N25Q128A.spispec \
          --boot-partition-size 262144 -o flashboot.bin
   
   # Create upgrade image  
   xflash --upgrade 1 kmix_hw2_1_01.xe --spi-spec MICRON_N25Q128A.spispec \
          --boot-partition-size 262144 -o flashupgrade.bin --factory-version 13.2
   ```

3. **System Programming**:
   ```bash
   # Program factory image and all processor firmware
   xrun app_factory_image_programmer.xe  # Programs XMOS + distributes to other processors
   
   # Reboot system
   xrun app_factory_reboot.xe
   ```

#### Flash Memory Layout
The XMOS manages firmware for all processors in its SPI flash:

- **Boot Partition** (256KB): XMOS bootloader + main firmware
- **Data Partition** (915KB): Multi-processor firmware bundle containing:
  - 4× SHARC DSP binaries (sample rate specific, ~194KB each)
  - 2× 8051 firmware binaries (64KB each)
  - Debug utilities and version metadata

### Firmware Version Management
- **SHARC DSP**: v1.0.35 (separate binary per sample rate)
- **8051 Control Board (0908)**: v2.1.15 (MIDI, UI, system control)  
- **8051 Audio Board (0909)**: v2.1.16 (preamp gain, zero-cross detection)
- **XMOS**: v0x103 (main firmware build number)
- **Global System**: v1.0.0 (overall K-Mix firmware version)

## Development Notes

### Missing Documentation
- ⚠️ **No inline code comments** - contractors coding style
- ⚠️ **Minimal function documentation** - Reverse engineering required
- ⚠️ **No architectural diagrams** - Signal flow must be inferred
- ⚠️ **Build procedures undocumented** - Standard XMOS workflow assumed
- ⚠️ **8051 source code missing** - Only compiled binaries available
- ⚠️ **SHARC source code missing** - Only compiled .ldr files available

### Key Unknowns
- [ ] 8051 source code location and build process
- [ ] SHARC DSP source code and VisualDSP++ project
- [ ] Exact I2C protocol between processors
- [ ] Complete GPIO pin mapping and functions
- [ ] Power management sequences
- [ ] Factory calibration procedures
- [ ] Inter-processor firmware update protocol

## Getting Started

### Prerequisites
- XMOS xTIMEcomposer 13.2 or compatible 
- XMOS hardware debugger (XTAG)
- K-Mix hardware platform
- All processor firmware binaries (8051 and SHARC .ldr files)

### Build Instructions (XMOS Firmware Only)
1. Set up XMOS environment:
   ```bash
   source /Applications/XMOS_xTIMEcomposer_Community_13.2.3/SetEnv.sh
   ```
2. Build firmware:
   ```bash
   cd ws1/app_usb_aud_kmi_mixer
   make CONFIG=hw2
   ```
   Output: `bin/hw2/app_usb_aud_kmi_mixer_hw2.xe` (~1.2MB XMOS executable)

3. Alternative - Open xTIMEcomposer Studio:
   - Import workspace from `ws1/` directory
   - Select `app_usb_aud_kmi_mixer` as active project
   - Build target: `kmi_mixer.xn`

### Complete System Firmware Update
To update ALL processors (recommended production process):

1. **Prepare firmware bundle**:
   ```bash
   cd xcodeutils/xmos_mixer_support/xmosdfu_mixer/kmix_xmos_flash/xmos_images/kmix_hw2_1_01/
   ./kmix_hw2_1_01.command
   ```

2. **What this does**:
   - Sources XMOS tools environment
   - Builds `flashdata.bin` containing all processor firmware
   - Creates XMOS flash images (`flashboot.bin`, `flashupgrade.bin`)
   - Programs XMOS via factory programmer app
   - XMOS distributes firmware to 8051s and SHARC via I2C/SPI

### Debug Setup
- **XSCOPE**: Real-time debugging enabled
- **JTAG Chain**: Node 0 (XMOS) + Node 1 (USB peripheral)
- **Flash Programming**: SPI flash via embedded bootloader
- **Multi-Processor Debug**: XMOS firmware includes diagnostic tools for other processors

### Development Workflow

#### Modifying XMOS Firmware Only
1. Edit code in `ws1/app_usb_aud_kmi_mixer/` or `ws1/module_kmi_mixer/`
2. Build firmware: `make CONFIG=hw2` → generates `.xe` file in `bin/hw2/`
3. For complete system update: Copy `.xe` to `kmix_hw2_1_01/` directory and run `kmix_hw2_1_01.command`

## Related Files
- **Development Utilities**: `xcodeutils/` (macOS Xcode projects)
- **Flash Programming**: `xcodeutils/xmos_mixer_support/`
- **Documentation**: `ws1/Documentation [module_name]/`

### Custom DFU Tool (`xmosdfu_xcode/`)
A **custom XMOS DFU (Device Firmware Update) utility** in Xcode:

**Purpose**: Advanced firmware management for the complete K-Mix system
- **Language**: C++ with libusb-1.0 
- **Platform**: macOS native application
- **Capabilities**:
  - USB DFU protocol implementation
  - Multi-processor firmware validation
  - Flash directory reading/writing
  - Custom XMOS DFU extensions
  - Firmware version checking and mismatch detection

**Key Features**:
```cpp
// XMOS-specific DFU commands
#define XMOS_DFU_RESETDEVICE     0xf0  // Reset to application mode
#define XMOS_DFU_REVERTFACTORY   0xf1  // Revert to factory firmware  
#define XMOS_DFU_RESETINTODFU    0xf2  // Enter DFU mode
#define XMOS_DFU_RESETFROMDFU    0xf3  // Exit DFU mode
#define XMOS_DFU_SAVESTATE       0xf5  // Save custom state
#define XMOS_DFU_RESTORESTATE    0xf6  // Restore custom state
#define XMOS_DFU_DNLOAD_DATA     0xf7  // Download data partition
#define XMOS_DFU_READ_FLASH_ENTRY 0xf8 // Read flash directory entry
#define XMOS_DFU_READ_FLASH_FORMAT 0xf9 // Read flash format
```

**Command Line Usage**:
```bash
xmosdfu --downloadboot firmware.bin     # Update XMOS bootloader
xmosdfu --downloaddata flashdata.bin    # Update data partition (all processors)
xmosdfu --flashdata flashdata.txt       # Validate firmware versions
xmosdfu --revertfactory                 # Restore factory firmware
xmosdfu --savecustomstate               # Save current state
xmosdfu --restorecustomstate            # Restore saved state
```

**Error Codes**:
- `XMOSDFU_ERR_MISMATCH_FW`: XMOS firmware version mismatch
- `XMOSDFU_ERR_MISMATCH_DATA`: Data partition version mismatch  
- `XMOSDFU_ERR_MISMATCH_BOTH`: Both firmware and data mismatch
- `XMOSDFU_ERR_BUILD_MISMATCH`: Build number validation failure

This tool provides **much more sophisticated firmware management** than standard XMOS tools, specifically designed for the multi-processor K-Mix architecture.
