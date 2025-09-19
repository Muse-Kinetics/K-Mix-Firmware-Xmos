// ====================================================================================================================
// XStream I2C Driver Implementation
// ====================================================================================================================

#include <xs1.h>
#include <platform.h>
#include <xclib.h>
#include <stdio.h>
#include <print.h>

#include "i2c.h"

// --------------------------------------------------------------------------------------------------------------------
// Clock and Port Resources
// --------------------------------------------------------------------------------------------------------------------

on tile[I2C_MASTER__TILE_NUMBER] : port _i2c_master__port_scl = I2C_MASTER__SCL_PORT;
on tile[I2C_MASTER__TILE_NUMBER] : port _i2c_master__port_sda = I2C_MASTER__SDA_PORT;

static timer _i2c_master__timer;
static int   _i2c_master__time;

static int   _i2c_master__state;
static int   _i2c_master__shift;
static xbyte _i2c_master__data;
static xbyte _i2c_master__ackflag;

#define _I2C_MASTER__TIME_BASE ((400000 / I2C_MASTER__BIT_RATE) * 62)

// --------------------------------------------------------------------------------------------------------------------
//  SCL and SDA Port Control Functions
// --------------------------------------------------------------------------------------------------------------------

static inline xbyte _i2c_master__read_scl( void )
{
    unsigned char bit=0;
    #if I2C_MASTER__ACTIVE_HIGH == TRUE
    _i2c_master__port_scl <: 1;
    #else
    _i2c_master__port_scl :> bit;
    #endif
    return bit;
}

static inline xbyte _i2c_master__read_sda( void )
{
    unsigned char bit=0;
    #if I2C_MASTER__ACTIVE_HIGH == TRUE
    _i2c_master__port_sda <: 1;
    #else
    _i2c_master__port_sda :> bit;
    #endif
    return bit;
}

static inline void  _i2c_master__clear_scl( void ) {_i2c_master__port_scl <: 0;}
static inline void  _i2c_master__clear_sda( void ) {_i2c_master__port_sda <: 0;}

xbyte i2c_master__get_data( void ) {return _i2c_master__data;}
xbyte i2c_master__get_ack ( void ) {return _i2c_master__ackflag;}

// ====================================================================================================================
// XStream I2C Driver Implementation - Master Mode
// ====================================================================================================================

void i2c_master__initialize( void )
{
    _i2c_master__read_scl();
    _i2c_master__read_sda();
    _i2c_master__timer :> _i2c_master__time;
    _i2c_master__timer when timerafter( _i2c_master__time + 10 * _I2C_MASTER__TIME_BASE ) :> void;
}

int i2c_master__start_begin( void )
{
    _i2c_master__state = 1;
    _i2c_master__timer :> _i2c_master__time;
    return I2C__STATUS__TRANSFER_BUSY;
}

int i2c_master__write_begin( xbyte data )
{
    _i2c_master__data = data;
    _i2c_master__state = 4;
    _i2c_master__shift = 7;
    _i2c_master__timer :> _i2c_master__time;
    return I2C__STATUS__TRANSFER_BUSY;
}

int i2c_master__read_begin( void )
{
    _i2c_master__state = 11;
    _i2c_master__shift = 7;
    _i2c_master__timer :> _i2c_master__time;
    return I2C__STATUS__TRANSFER_BUSY;
}

int i2c_master__ack_begin( xbool ack_flag )
{
    _i2c_master__ackflag = ack_flag != 0;
    _i2c_master__state = 16;
    _i2c_master__timer :> _i2c_master__time;
    return I2C__STATUS__TRANSFER_BUSY;
}

int i2c_master__stop_begin( void )
{
    _i2c_master__state = 20;
    _i2c_master__timer :> _i2c_master__time;
    return I2C__STATUS__TRANSFER_BUSY;
}

int _i2c_master__continue( void )
{
    switch( _i2c_master__state )
    {
        // Start Condition
        case 1:
        _i2c_master__clear_sda();
        _i2c_master__state = 2;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 2:
        _i2c_master__clear_scl();
        _i2c_master__state = 3;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 3:
        _i2c_master__state = 0;
        return I2C__STATUS__TRANSFER_IDLE;
        break;

        // Write Bits 7-0
        case 4:
        if( (_i2c_master__data >> _i2c_master__shift) & 1 ) _i2c_master__read_sda();
        else _i2c_master__clear_sda();
        _i2c_master__shift--;
        _i2c_master__state = 5;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 5:
        _i2c_master__read_scl();
        _i2c_master__state = 6;
        _i2c_master__time += 2 * _I2C_MASTER__TIME_BASE;
        break;
        case 6:
        _i2c_master__clear_scl();
        if( _i2c_master__shift < 0 ) {
            _i2c_master__state = 7;
            _i2c_master__time += 2 * _I2C_MASTER__TIME_BASE;
        }
        else {
            _i2c_master__state = 4;
            _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        }
        break;

         // Sense ACK/NACK
        case 7:
        _i2c_master__ackflag = _i2c_master__read_sda();
        _i2c_master__state = 8;
        break;
        case 8:
        _i2c_master__read_scl();
        _i2c_master__state = 9;
        _i2c_master__time += 2 * _I2C_MASTER__TIME_BASE;
        break;
        case 9:
        _i2c_master__clear_scl();
        _i2c_master__state = 10;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 10:
        _i2c_master__state = 0;
        return I2C__STATUS__TRANSFER_IDLE;
        break;

         // Read Bits 7-0
        case 11:
        _i2c_master__read_sda();
        _i2c_master__state = 12;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 12:
        _i2c_master__read_scl();
        _i2c_master__state = 13;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 13:
        (_i2c_master__data = _i2c_master__data >> 1) + _i2c_master__read_sda() << (_i2c_master__shift--);
        _i2c_master__state = 14;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE; break;
        case 14:
        _i2c_master__clear_scl();
        if( _i2c_master__shift < 0 ) _i2c_master__state = 15;
        else _i2c_master__state = 11;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 15:
        _i2c_master__state = 0;
        return I2C__STATUS__TRANSFER_IDLE;
        break;

        // Assert ACK/NACK
        case 16:
        if( _i2c_master__ackflag ) _i2c_master__read_sda();
        else _i2c_master__clear_sda();
        _i2c_master__state = 17;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 17: _i2c_master__read_scl();
        _i2c_master__state = 18;
        _i2c_master__time += 2 * _I2C_MASTER__TIME_BASE;
        break;
        case 18:
        _i2c_master__clear_scl();
        _i2c_master__state = 19;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 19:
        _i2c_master__state = 0;
        return I2C__STATUS__TRANSFER_IDLE;
        break;

        // Stop Condition
        case 20: _i2c_master__clear_sda();
        _i2c_master__state = 21;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 21: _i2c_master__read_scl();
        _i2c_master__state = 22;
        _i2c_master__time += 1 * _I2C_MASTER__TIME_BASE;
        break;
        case 22: _i2c_master__read_sda();
        _i2c_master__state = 23;
        _i2c_master__time += 2 * _I2C_MASTER__TIME_BASE;
        break;
        case 23:
        _i2c_master__state = 0;
        return I2C__STATUS__TRANSFER_IDLE;
        break;

    }
    return I2C__STATUS__TRANSFER_BUSY;
}

select i2c_master__io_status( int& status )
{
    case _i2c_master__timer when timerafter(_i2c_master__time) :> _i2c_master__time:

        status =  _i2c_master__continue();
        break;
}

#define _I2C_MASTER__RUN() \
    \
    while( TRUE ) { \
        _i2c_master__timer when timerafter(_i2c_master__time) :> _i2c_master__time; \
        status = _i2c_master__continue(); \
        if( status != 0 ) break; \
    }

int i2c_master__start( void )
{
    int status;
    i2c_master__start_begin();
    _I2C_MASTER__RUN();
    return status;
}

int i2c_master__write( xbyte data, xbyte& ack_flag )
{
    int status;
    i2c_master__write_begin( data );
    _I2C_MASTER__RUN();
    ack_flag = _i2c_master__ackflag;
    return status;
}

int i2c_master__read( xbyte& data )
{
    int status;
    i2c_master__read_begin();
    _I2C_MASTER__RUN();
    data = _i2c_master__data;
    return status;
}

int i2c_master__ack( xbyte ack_flag )
{
    int status;
    i2c_master__ack_begin( ack_flag );
    _I2C_MASTER__RUN();
    return status;
}

int i2c_master__stop( void )
{
    int status;
    i2c_master__stop_begin();
    _I2C_MASTER__RUN();
    return status;
}

// ====================================================================================================================
// ====================================================================================================================
