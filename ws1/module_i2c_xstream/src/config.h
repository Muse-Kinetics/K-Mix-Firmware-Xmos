#ifndef XCONFIG
#define XCONFIG

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE (!FALSE)
#endif

#define I2C_MASTER__TILE_NUMBER       0
#define I2C_MASTER__BUS_MASTER        TRUE
#define I2C_MASTER__BIT_RATE          100000
#define I2C_MASTER__ACTIVE_HIGH       FALSE
#define I2C_MASTER__RESTARTS          FALSE
#define I2C_MASTER__CLOCK_STRETCHING  FALSE
#define I2C_MASTER__COLLISION_DET     FALSE
#define I2C_MASTER__SCL_BIT_POS       0             // Non-negative integer
#define I2C_MASTER__SDA_BIT_POS       0             // Non-negative integer
//#define I2C_MASTER__SCL_PORT          XS1_PORT_1E   // XS1 port identifier
//#define I2C_MASTER__SDA_PORT          XS1_PORT_1F   // XS1 port identifier
#define I2C_MASTER__SCL_PORT          XS1_PORT_1L   // XS1 port identifier
#define I2C_MASTER__SDA_PORT          XS1_PORT_1I   // XS1 port identifier

#define I2C_SLAVE__TILE_NUMBER        0
#define I2C_SLAVE__BUS_MASTER         FALSE
#define I2C_SLAVE__BIT_RATE           100000
#define I2C_SLAVE__ACTIVE_HIGH        FALSE
#define I2C_SLAVE__RESTARTS           FALSE
#define I2C_SLAVE__CLOCK_STRETCHING   FALSE
#define I2C_SLAVE__COLLISION_DET      FALSE
#define I2C_SLAVE__SCL_BIT_POS        0             // Non-negative integer
#define I2C_SLAVE__SDA_BIT_POS        0             // Non-negative integer
//#define I2C_SLAVE__SCL_PORT           XS1_PORT_1G   // XS1 port identifier
//#define I2C_SLAVE__SDA_PORT           XS1_PORT_1H   // XS1 port identifier
#define I2C_SLAVE__SCL_PORT           XS1_PORT_1L   // XS1 port identifier
#define I2C_SLAVE__SDA_PORT           XS1_PORT_1I   // XS1 port identifier

#endif
