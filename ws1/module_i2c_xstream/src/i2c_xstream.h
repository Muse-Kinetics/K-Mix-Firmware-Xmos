// ====================================================================================================================
// XStream Peripheral Library
// ====================================================================================================================

#ifndef I2C_0V1
#define I2C_0V1

typedef unsigned int   xbool;
typedef unsigned char  xbyte;
typedef unsigned int   xuint;
typedef   signed int   xsint;

typedef   signed char  xsint8;
typedef unsigned char  xuint8;
typedef   signed short xsint16;
typedef unsigned short xuint16;
typedef   signed int   xsint32;
typedef unsigned int   xuint32;

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE (!FALSE)
#endif

#include "config.h"

// ====================================================================================================================
// I2C Peripheral Interface
// ====================================================================================================================

// These must be defined in "xconfig.h" for each peripheral bus being used
//
// USES_UART_n               No value
//
// I2C_n__BUS_MASTER         TRUE or FALSE
// I2C_n__BIT_RATE           Non-zero, non-negative integer
// I2C_n__RESTARTS           TRUE or FALSE
// I2C_n__CLOCK_STRETCHING   TRUE or FALSE
// I2C_n__COLLISION_DET      TRUE or FALSE
// I2C_n__SCL_BIT_POS        Non-negative integer
// I2C_n__SDA_BIT_POS        Non-negative integer
// I2C_n__TILE_NUMBER        integer, XS1 tile number
// I2C_n__SCL_PORT           XS1 port identifier
// I2C_n__SDA_PORT           XS1 port identifier

#define I2C__STATUS__EVENT_USER    ( 10)  // Base value for user defined events
#define I2C__STATUS__EVENT_START   (  6)  // Start or restart condition encountered (slave mode only)
#define I2C__STATUS__EVENT_STOP    (  5)  // Stop condition encountered (slave mode only)
#define I2C__STATUS__EVENT_WRITE   (  4)  // Write operation completed, no start/stop condition encountered
#define I2C__STATUS__EVENT_READ    (  3)  // Read operation completed, no start/stop condition encountered
#define I2C__STATUS__EVENT_ACK     (  2)  // ACK operation completed, no start/stop condition encountered
#define I2C__STATUS__TRANSFER_IDLE (  1)  // No I/O is in progress and no error status is pending
#define I2C__STATUS__TRANSFER_BUSY (  0)  // I2C operation is still in progress (master)
#define I2C__STATUS__ERROR_TIMEOUT ( -1)  // Clock stretching (master mode) or wait for start/stop (slave) timeout
#define I2C__STATUS__ERROR_BUSERR  ( -2)  // Bus Error (invalid start/stop sequence)
#define I2C__STATUS__ERROR_ARBLOST ( -3)  // Bus arbitration failure (lost abitration)
#define I2C__STATUS__ERROR_USER    (-10)  // Base value for user defined errors

#define I2C__ACK_VALUE  0
#define I2C__NACK_VALUE 1

// --------------------------------------------------------------------------------------------------------------------
// Functions for I2C Master
// --------------------------------------------------------------------------------------------------------------------

void   i2c_master__initialize ( void );

// Blocking I/O Functions (for non-event driven I/O)

int    i2c_master__start      ( void );                        // Assert (master) or wait for (slave) START condition
int    i2c_master__stop       ( void );                        // Assert (master) or wait for (slave) STOP condition
int    i2c_master__write      ( xbyte data, xbyte& ack_flag ); // Write next byte (master or slave)
int    i2c_master__read       ( xbyte& data );                 // Read next byte (master or slave)
int    i2c_master__ack        ( xbyte ack_bit );               // Assert ACK (sda=0) after a READ (master or slave)
void   i2c_master__reset      ( void );                        // Reset state machine and release SCL

// Non-Blocking I/O Functions (for event driven I/O)

void   i2c_master__begin_start( void );           // Begin START condition
void   i2c_master__begin_stop ( void );           // Begin STOP condition
void   i2c_master__begin_write( xbyte data );     // Begin data write
void   i2c_master__begin_read ( void );           // Begin data read
void   i2c_master__begin_ack  ( xbool ack_flag ); // Begin ack flag write
select i2c_master__io_status  ( int& status  );   // Set pin states and check for I/O events per I2C state machine
xbyte  i2c_master__get_data   ( void );           // Data from last I/O Event
xbyte  i2c_master__get_ack    ( void );           // ACK flag from last I/O Event
void   i2c_master__end        ( void );           // End I/O sequences - reset state machine and release SCL

// --------------------------------------------------------------------------------------------------------------------
// Functions for I2C Slave
// --------------------------------------------------------------------------------------------------------------------

void   i2c_slave__initialize ( void );

// Blocking I/O Functions (for non-event driven I/O)
//
// Note: Start, Stop, Write, Read and Ack functions will hold SCL low to give the application time to process
//       The Reset function must be called if no other I/O operations are to follow

int    i2c_slave__start      ( void );                        // Assert (master) or wait for (slave) START condition
int    i2c_slave__stop       ( void );                        // Assert (master) or wait for (slave) STOP condition
int    i2c_slave__write      ( xbyte data, xbyte& ack_flag ); // Write next byte (master or slave)
int    i2c_slave__read       ( xbyte& data );                 // Read next byte (master or slave)
int    i2c_slave__ack        ( xbyte ack_bit );               // Assert ACK (sda=0) after a READ (master or slave)
void   i2c_slave__reset      ( void );                        // Reset state machine and release SCL

// Non-Blocking I/O Functions (for event driven I/O)
//
// Note: Start, Stop, Write, Read and Ack functions will hold SCL low to give the application time to process
//       The End function must be called if no other I/O operations are to follow

void   i2c_slave__begin_start( void );           // Begin START condition
void   i2c_slave__begin_stop ( void );           // Begin STOP condition
void   i2c_slave__begin_write( xbyte data );     // Begin data write
void   i2c_slave__begin_read ( void );           // Begin data read
void   i2c_slave__begin_ack  ( xbool ack_flag ); // Begin ack flag write
select i2c_slave__io_status ( int& status );    // Set pin states and check for I/O events per I2C state machine
xbyte  i2c_slave__get_data   ( void );           // Data or ACK flag from last I/O Event
xbyte  i2c_slave__get_ack    ( void );           // ACK flag from last I/O Event
void   i2c_slave__end        ( void );           // End I/O sequences - reset state machine and release SCL

// ====================================================================================================================
// ====================================================================================================================

#define SS_0    0
#define SS_1    1
#define SS_2    2
#define SS_3    3
#define SS_4    4
#define SS_5    5
#define SS_6    6
#define SS_7    7
#define SS_8    8

#if I2C_SLAVE__SCL_PORT != I2C_SLAVE__SDA_PORT

#include "i2c.h"

extern r_i2c r_i2c_if;


#define _i2c_slave__port_scl r_i2c_if.scl
#define _i2c_slave__port_sda r_i2c_if.sda

extern xbyte _i2c_slave__scl;
extern xbyte _i2c_slave__sda;
extern xbyte _i2c_slave__pins;

int _i2c_slave__continue( void );
inline xbyte _i2c_slave__read_sda( void );


#endif


#endif
