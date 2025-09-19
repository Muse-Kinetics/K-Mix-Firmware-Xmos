# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = kmi_mixer.xn

APP_NAME =

# The flags passed to xcc when building the application
BUILD_FLAGS     = -DFLASH_MAX_UPGRADE_SIZE=64*1024 -fcomment-asm -Xmapper --map -Xmapper MAPFILE -Wall -O3 -report  -fsubword-select -save-temps -g -fxscope -DXSCOPEx -DSDA_HIGH=2 -DSCL_HIGH=1 -DXUD_SERIES_SUPPORT=1 -DVERBOSE=1
#BUILD_FLAGS     = -DFLASH_MAX_UPGRADE_SIZE=64*1024 -fcomment-asm -Xmapper --map -Xmapper MAPFILE -Wall -O3 -report -lflash -fsubword-select -save-temps -g  -DSDA_HIGH=2 -DSCL_HIGH=1 -DXUD_SERIES_SUPPORT=1

# Test build configs (Note these make use of the defaults in customdefines.h)



XCC_FLAGS_hw2 = $(BUILD_FLAGS)  -DSPDIF=0 -save-temps $(COMMON_FLAGS) -DKMI -DMIDI -DIAPx -DDEV_VERSIONx  -DDISPLAY_VERSIONx
 


# The USED_MODULES variable lists other module used by the application. These
# modules will extend the SOURCE_DIRS, INCLUDE_DIRS and LIB_DIRS variables. 
# Modules are expected to be in the directory above the BASE_DIR directory.
# USED_MODULES = module_usb_shared module_xud module_usb_audio module_spdif_tx module_spdif_rx module_usb_midi module_dfu module_i2c_single_port module_usb_device
USED_MODULES = module_usb_shared module_xud module_usb_audio  module_dfu module_i2c_master module_usb_device module_kmi_mixer   module_usb_midi module_i2c_msi module_locks module_flash2 module_spi_master # module_iap # module_i2c_xstream 

MODULE_LIBRARIES = xud_s


#=============================================================================
#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
ifneq ($(wildcard $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common),)
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
else
include ../module_xcommon/build/Makefile.common
endif


