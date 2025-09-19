#include <xs1.h>
#include <platform.h>
#include <flashlib.h>
#include "xs1_su_registers.h"

#include "xud.h"

#define XS1_SU_PERIPH_USB_ID 0x1

#define FL_DEVICE_MICRON_N25Q128A \
{\
    139,            /*MICRON_N25Q128A*/\
    256,            /* x page size was 256 */\
    8192,          /* x num pages was 65536 */\
    3,              /* x address size */\
    2,              /* x log2 clock divider was 3 */\
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

fl_PortHolderStruct spi = { PORT_SPI_MISO, PORT_SPI_SS, PORT_SPI_CLK, PORT_SPI_MOSI, XS1_CLKBLK_2};
static const fl_DeviceSpec fl_deviceSpecs[] = {FL_DEVICE_MICRON_N25Q128A};

int flash_connect() {
  int res;
  res = fl_connect(spi);
//  res = fl_connectToDevice(spi,fl_deviceSpecs,1);
  if( res != 0 ) {
    return(0);
  }
  return 1;
}

void reboot()
{
    unsigned data[] = {4};
    write_periph_32(usb_tile, XS1_SU_PERIPH_USB_ID, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 1, data);

/* Ideally we would reset SU1 here but then we loose power to the xcore and therefore the DFU flag */
/* Disable USB and issue reset to xcore only - not analogue chip */
    write_node_config_reg(usb_tile, XS1_SU_CFG_RST_MISC_NUM,0b10);

}
