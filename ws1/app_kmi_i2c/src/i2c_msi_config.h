#ifndef KMI_I2C
#define KMI_I2C

#define I2C__TILE_NUMBER       0

#define I2C_RX_INTERFACE_COUNT  1
#define I2C_TX_INTERFACE_COUNT  2

#define I2C_SLAVE_MAX_RX    20
#define I2C_SLAVE_MAX_TX    20

#define USE_I2C_MS_DATA_IO
#define ACK_LOW_EVENTS_ONLY

#define I2C__SCL_PORT          XS1_PORT_1E
#define I2C__SDA_PORT          XS1_PORT_1F

#define I2C_ADDRESS_A   0x40    // local startkit
#define I2C_ADDRESS_B   0x42    // remote startkit
#define I2C_ADDRESS_C   0x46    // the 8051


//#define DO_NOTHING
//#define I2C_TEST_SIMULTANEOUS_TX
typedef struct I2C_TESTING_ADDRESS {int local,remote,remote_8051;} I2C_TESTING_ADDRESS;

extern I2C_TESTING_ADDRESS i2c_address; // for testing with two startkits connected

#define SCL_DATA_HALF_PERIOD    1000      // 20 = 562k 40=474k 100=321k 200=200k  400=118k

#define SCL_LOW_TIME_DELAY  SCL_DATA_HALF_PERIOD         // 194 = 200khz  445 = 100khz
#define SCL_HIGH_TIME_DELAY  SCL_DATA_HALF_PERIOD

#define SCL_LOW_ACK_TIME    (SCL_DATA_HALF_PERIOD)
#define SCL_HIGH_ACK_TIME   SCL_LOW_ACK_TIME // high time before data transfer

//#define MIN_SCL_LOW_TIME    50
#define SCL_HIGH_START_TIME 200  // how long to drop scl after start

#define EVENTS_MIN_SCL_HIGH_TIME   150  // 250
#define EVENTS_SCL_LOW_EXTEND_TIME 150  // how long to hold scl low after work done // 250

#define SCL_LOW_TO_SDA_CHANGE_TIME  SCL_DATA_HALF_PERIOD/10

#define SCL_HIGH_AFTER_STOP_TIME    5*1E2  // 1E2 is 1 microsecond

#define USE_I2C_MSI_BIT

#endif
