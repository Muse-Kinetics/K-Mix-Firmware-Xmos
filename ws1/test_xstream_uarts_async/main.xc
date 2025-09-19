#include <xs1.h>
#include <xclib.h>
#include <platform.h>
#include <print.h>
#include <xscope.h>
#include <stdio.h>

#include "i2c.h"

// ====================================================================================================================
// Create a master "Write Register" macro operation using multiple I2C master start/write/read/stop operations
// ====================================================================================================================

#define SLAVE_API__BLOCKING_IO    1
#define SLAVE_API__NONBLOCKING_IO 2
#define SLAVE_API__CALLBACKS      3

//#define SLAVE_API__METHOD         SLAVE_API__BLOCKING_IO
#define SLAVE_API__METHOD         SLAVE_API__NONBLOCKING_IO
//#define SLAVE_API__METHOD         SLAVE_API__CALLBACKS

#define I2C__STATUS__ERROR_ADDRESS_NACK  (I2C__STATUS__ERROR_USER - 1)  // Slave device address NACK
#define I2C__STATUS__ERROR_REGISTER_NACK (I2C__STATUS__ERROR_USER - 2)  // Slave regsiter number write NACK
#define I2C__STATUS__ERROR_VALUE_NACK    (I2C__STATUS__ERROR_USER - 3)  // Slave register value write NACK

int i2c_master__write_register( xbyte device_address, xbyte reg_number, xbyte reg_value )
{
    int status = 0; xbyte ack_flag;

    // Assert a start condition
    if( (status = i2c_master__start()) < 0 ) return status;

    // Write first byte of transaction - the 7-bit address and read/write flag
    if( (status = i2c_master__write( (device_address << 1) + 0, ack_flag )) < 0 ) return status;
    //if( ack_flag == I2C__ACK_VALUE ) {
    //    printstrln( "I2C Master: Slave device address NACK" );
    //    return I2C__STATUS_ADDRESS_NACK;
    //}

    // Write first byte of transaction - the 8-bit register number to write data to
    if( (status = i2c_master__write( reg_number, ack_flag )) < 0 ) return status;
    //if( ack_flag == I2C__ACK_VALUE ) {
    //    printstrln( "I2C Master: Slave register number write NACK" );
    //    return I2C__STATUS_REGISTER_NACK;
    //}

    // Write first byte of transaction - the 8-bit data for the current register to write to
    if( (status = i2c_master__write( reg_value, ack_flag )) < 0 ) return status;
    //if( ack_flag == I2C__ACK_VALUE ) {
    //    printstrln( "I2C Master: Slave register value write NACK" );
    //    return I2C__STATUS_VALUE_NACK;
    //}

    // Assert a stop condition
    if( (status = i2c_master__stop()) < 0 ) return status;

    return 0;
}

// ====================================================================================================================
// Create a slave "Write Register" macro operation using multiple I2C slave start/write/read/stop operations
// ====================================================================================================================

#if SLAVE_API__METHOD == SLAVE_API__NONBLOCKING_IO

// --------------------------------------------------------------------------------------------------------------------
// Implement the slave "Write Register" handler using non-blocking functions within a single handler function that's
// called after a select statement (see 'main' function below).
//
// Not that the I2C slave functions drive SCL low (will result in clock stretching) to give the application time
// to invoke the next I2C slave function.
// --------------------------------------------------------------------------------------------------------------------

int _i2c_slave__write_register__state = 0;
int _i2c_slave__write_register__device;
int _i2c_slave__write_register__number;
int _i2c_slave__write_register__value;

int i2c_slave__write_register__continue( int i2c_status )
{
    if( i2c_status <= 0 ) return i2c_status; // I2C operation error (<0) or I2C operation not finished (=0)

    switch( _i2c_slave__write_register__state )
    {
        // Received start condition, start reading slave address and read/write flag
        case 0:
        i2c_slave__begin_read();
        _i2c_slave__write_register__state = 1;
        break;

        // Received slave address from master, check it, start sending ACK/NACK
        case 1:
        _i2c_slave__write_register__device = i2c_slave__get_data();
        // if( _i2c_slave__write_register__device != MY_I2C_ADDRESS ) {
        //    i2c_slave__begin_ack(I2C__NACK_VALUE1 );
        //    return -99;
        //}
        i2c_slave__begin_ack( I2C__ACK_VALUE );
        _i2c_slave__write_register__state = 2;
        break;

        // Send ACK/NACK to master, start reading register number
        case 2:
        i2c_slave__begin_read();
        _i2c_slave__write_register__state = 3;
        break;

        // Received slave address from master, check it, start sending ACK/NACK
        case 3:
        _i2c_slave__write_register__number = i2c_slave__get_data();
        // if( _i2c_slave__write_register__device != VALID_REGISTER_NUMBER )
        //    i2c_slave__begin_ack(XSTREAM_I2C__NACK_VALUE1 );
        //    return -99;
        //}
        i2c_slave__begin_ack( I2C__ACK_VALUE );
        _i2c_slave__write_register__state = 4;
        break;

        // Send ACK/NACK to master, start reading register number
        case 4:
        i2c_slave__begin_read();
        _i2c_slave__write_register__state = 5;
        break;

        // Received slave address from master, check it, start sending ACK/NACK
        case 5:
        _i2c_slave__write_register__value = i2c_slave__get_data();
        // if( _i2c_slave__write_register__device != VALID_REGISTER_VALUE )
        //    i2c_slave__begin_ack(I2C__NACK_VALUE1 );
        //    return -99;
        //}
        i2c_slave__begin_ack( I2C__ACK_VALUE );
        _i2c_slave__write_register__state = 6;
        break;

        // Send ACK/NACK to master, start waiting for STOP condition
        case 6:
        i2c_slave__begin_stop();
        _i2c_slave__write_register__state = 7;
        break;

        // Received STOP condition
        case 7:
        printhexln( _i2c_slave__write_register__device );
        printhexln( _i2c_slave__write_register__number );
        printhexln( _i2c_slave__write_register__value );
        return I2C__STATUS__TRANSFER_IDLE;
    }
    return I2C__STATUS__TRANSFER_BUSY;
}

#endif

#if SLAVE_API__METHOD == SLAVE_API__CALLBACKS

// --------------------------------------------------------------------------------------------------------------------
// Implement the slave "Write Register" handler using non-blocking functions within a single handler function that
// calls various callback functions after a select statement (see 'main' function below).
//
// Not that the I2C slave functions drive SCL low (will result in clock stretching) to give the application time
// to invoke the next I2C slave function.
// --------------------------------------------------------------------------------------------------------------------

int _i2c_slave__write_register__state = 1;

void i2c_slave__write_register__start()
{
    if( _i2c_slave__write_register__state == 1 ) {
        i2c_slave__begin_read();
        _i2c_slave__write_register__state = 2;
    }
}

void i2c_slave__write_register__stop()
{
    if( _i2c_slave__write_register__state == 8 ) {
        i2c_slave__end();
        _i2c_slave__write_register__state = 0;
    }
}

void i2c_slave__write_register__read()
{
    xbyte data;
    switch( _i2c_slave__write_register__state )
    {
        case 2: data = i2c_slave__get_data();
                i2c_slave__begin_ack( 0 );
                _i2c_slave__write_register__state = 3;
                break;

        case 4: data = i2c_slave__get_data();
                i2c_slave__begin_ack( 0 );
                _i2c_slave__write_register__state = 5;
                break;

        case 6: data = i2c_slave__get_data();
                i2c_slave__begin_ack( 0 );
                _i2c_slave__write_register__state = 6;
                break;
    }
}

void i2c_slave__write_register__ack()
{
    xbyte ack;
    switch( _i2c_slave__write_register__state )
    {
        case 3: ack = i2c_slave__get_data();
                i2c_slave__begin_read();
                _i2c_slave__write_register__state = 4;
                break;

        case 5: ack = i2c_slave__get_data();
                i2c_slave__begin_read();
                _i2c_slave__write_register__state = 6;
                break;

        case 6: ack = i2c_slave__get_data();
                i2c_slave__begin_stop();
                _i2c_slave__write_register__state = 8;
                break;
    }
}

void i2c_slave__write_register__write()
{
}

void i2c_slave__write_register__timeout()
{
}

#endif

// ====================================================================================================================
// Main Function
// ====================================================================================================================

int main( void )
{
    par
    {
        // ------------------------------------------------------------------------------------------------------------
        // Master Mode I2C - Write Register using the 'macro' I2C operation defined above
        // ------------------------------------------------------------------------------------------------------------
        {
            xbyte ack;
            i2c_master__initialize();
            printstrln( "Hello" );
            i2c_master__start();
            i2c_master__write_register( 0x30, 0x01, 0x02 );
            {timer t; int x; t :> x; t when timerafter(x+100000000) :> void;}
        }

        // ------------------------------------------------------------------------------------------------------------
        // Slave Mode I2C - Write Register using blocking I/O functions
        // ------------------------------------------------------------------------------------------------------------
        #if SLAVE_API__METHOD == SLAVE_API__BLOCKING_IO
        {
            int status; xbyte data;
            i2c_slave__initialize();
            status = i2c_slave__start();
            status = i2c_slave__read( data );
            status = i2c_slave__ack( I2C__ACK_VALUE );
            status = i2c_slave__read( data );
            status = i2c_slave__ack( I2C__ACK_VALUE );
            status = i2c_slave__read( data );
            status = i2c_slave__ack( I2C__ACK_VALUE );
            status = i2c_slave__stop();
        }
        #endif

        // ------------------------------------------------------------------------------------------------------------
        // Slave Mode I2C - Write Register using non-blocking I/O functions and a single handler that contains a
        //                  simple state machine
        // ------------------------------------------------------------------------------------------------------------
        #if SLAVE_API__METHOD == SLAVE_API__NONBLOCKING_IO
        {
            int i2c_slave__status;
            i2c_slave__initialize();
            i2c_slave__begin_start();
            while( TRUE )
            {
                select
                {
                    case i2c_slave__io_status( i2c_slave__status );
                }
                if( i2c_slave__write_register__continue(i2c_slave__status) != 0 ) break;
            }
            //{timer t; int x; t :> x; t when timerafter(x+100000000) :> void;}
        }
        #endif

        // ------------------------------------------------------------------------------------------------------------
        // Slave Mode I2C - Write Register using non-blocking I/O functions and a single multiple handlers as callback
        //                  functions - these implelemnt a simple state machine
        // ------------------------------------------------------------------------------------------------------------
        #if SLAVE_API__METHOD == SLAVE_API__CALLBACKS
        {
            int i2c_slave__status;
            i2c_slave__initialize();
            i2c_slave__begin_start();
            while( TRUE )
            {
                int i2c_status;
                select
                {
                    case i2c_slave__io_status( i2c_slave__status );
                }
                switch( i2c_slave__status )
                {
                    case I2C__STATUS__EVENT_START:   i2c_slave__write_register__start();   break;
                    case I2C__STATUS__EVENT_STOP:    i2c_slave__write_register__stop();    break;
                    case I2C__STATUS__EVENT_WRITE:   i2c_slave__write_register__write();   break;
                    case I2C__STATUS__EVENT_READ:    i2c_slave__write_register__read();    break;
                    case I2C__STATUS__EVENT_ACK:     i2c_slave__write_register__ack();     break;
                    case I2C__STATUS__ERROR_TIMEOUT: i2c_slave__write_register__timeout(); break;
                }
                if( i2c_slave__status == I2C__STATUS__EVENT_STOP || i2c_slave__status < 0 ) break;
            }
        }
        #endif
    }
    return 0;
}
