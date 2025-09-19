// ====================================================================================================================
// XStream I2C Driver Implementation
// ====================================================================================================================

#include <xs1.h>
#include <platform.h>
#include <print.h>

#include "i2c.h"

//out port led1 = XS1_PORT_1G;
//out port led2 = XS1_PORT_1H;
//out port led3 = XS1_PORT_1I;
//out port led4 = XS1_PORT_1J;

//#define DEBUG_GPIO__START_EVENT          debug <: 0b0001; debug <: 0b0000
//#define DEBUG_GPIO__STOP_EVENT           debug <: 0b0010; debug <: 0b0000
//#define DEBUG_GPIO__READ_EVENT           debug <: 0b0100; debug <: 0b0000
//#define DEBUG_GPIO__WRITE_EVENT          debug <: 0b1000; debug <: 0b0000
//#define DEBUG_GPIO__SCL_STRETCH_HOLD     sig <: 1
//#define DEBUG_GPIO__SCL_STRETCH_RELEASE  sig <: 0

#define DEBUG_GPIO__START_EVENT
#define DEBUG_GPIO__STOP_EVENT
#define DEBUG_GPIO__READ_EVENT
#define DEBUG_GPIO__WRITE_EVENT
#define DEBUG_GPIO__SCL_STRETCH_HOLD
#define DEBUG_GPIO__SCL_STRETCH_RELEASE

// --------------------------------------------------------------------------------------------------------------------
// Clock and Port Resources
// --------------------------------------------------------------------------------------------------------------------

#if I2C_SLAVE__SCL_PORT != I2C_SLAVE__SDA_PORT

    on tile[I2C_SLAVE__TILE_NUMBER] : port _i2c_slave__port_scl = I2C_SLAVE__SCL_PORT;
    on tile[I2C_SLAVE__TILE_NUMBER] : port _i2c_slave__port_sda = I2C_SLAVE__SDA_PORT;

#else

    on tile[I2C_SLAVE__TILE_NUMBER] : port _i2c_slave__port = I2C_SLAVE__SCL_PORT;
    #define _i2c_slave__port_codec_reset I2C_SLAVE__SCL_PORT

    static xbyte _i2c_slave__shadow = 0;

#endif

static xbyte _i2c_slave__scl;
static xbyte _i2c_slave__sda;
static xbyte _i2c_slave__pins;

static int   _i2c_slave__state;
static int   _i2c_slave__shift;
static xbyte _i2c_slave__data;
static xbyte _i2c_slave__ackflag;

// <TODO> Calulate based on current system clock frequency
#define _I2C_SLAVE__TIME_BASE ((400000 / I2C_SLAVE__BIT_RATE) * 62)

// --------------------------------------------------------------------------------------------------------------------
//  SCL and SDA Port Control Functions
// --------------------------------------------------------------------------------------------------------------------

//out port debug = XS1_PORT_4C;
//out port sig = XS1_PORT_1P;

#if I2C_SLAVE__SCL_PORT != I2C_SLAVE__SDA_PORT

    static inline xbyte _i2c_slave__read_scl( void )
    {
        unsigned char bit=0;
        DEBUG_GPIO__SCL_STRETCH_RELEASE;
        #if I2C_SLAVE__ACTIVE_HIGH == TRUE
        _i2c_slave__port_scl <: 1;
        #else
        _i2c_slave__port_scl :> bit;
        #endif
        return bit;
    }

    static inline xbyte _i2c_slave__read_sda( void )
    {
        unsigned char bit=0;
        #if I2C_SLAVE__ACTIVE_HIGH == TRUE
        _i2c_slave__port_sda <: 1;
        #else
        _i2c_slave__port_sda :> bit;
        #endif
        return bit;
    }

    static inline xbyte  _i2c_slave__clear_scl( void ) {DEBUG_GPIO__SCL_STRETCH_HOLD; return 0;}
    static inline xbyte  _i2c_slave__clear_sda( void ) {return 0;}

#else

    xbyte _i2c_slave__read_scl( void )
    {
        _i2c_slave__shadow |= (1 << I2C_SLAVE__SCL_BIT_POS);
        _i2c_slave__port <: _i2c_slave__shadow;
        return 0;
    }

    xbyte _i2c_slave__read_sda( void )
    {
        _i2c_slave__shadow |= (1 << I2C_SLAVE__SDA_BIT_POS);
        _i2c_slave__port <: _i2c_slave__shadow;
        return 0;
    }

    void  _i2c_slave__clear_scl( void )
    {
        _i2c_slave__shadow &= ~(1 << I2C_SLAVE__SCL_BIT_POS);
        _i2c_slave__port <: _i2c_slave__shadow;
    }

    void  _i2c_slave__clear_sda( void )
    {
        _i2c_slave__shadow &= ~(1 << I2C_SLAVE__SDA_BIT_POS);
        _i2c_slave__port <: _i2c_slave__shadow;
    }

#endif

xbyte i2c_slave__get_data( void ) {return _i2c_slave__data;}
xbyte i2c_slave__get_ack ( void ) {return _i2c_slave__ackflag;}

// ====================================================================================================================
// XStream I2C Driver Implementation - Slave Mode
// ====================================================================================================================

void i2c_slave__initialize( void )
{
    _i2c_slave__state = I2C__STATUS__TRANSFER_IDLE;
}

void i2c_slave__begin_start( void )
{
    while( TRUE )
    {
        _i2c_slave__scl = _i2c_slave__read_scl();
        _i2c_slave__sda = _i2c_slave__read_sda();
        if( _i2c_slave__scl && _i2c_slave__sda ) break;
    }
    _i2c_slave__pins = 0b1111;
    _i2c_slave__state = 1;
}

void i2c_slave__begin_stop( void )
{
    _i2c_slave__state = 1;
    _i2c_slave__read_sda(); // Release SDA - allow posbbile resulting SDA change while SCL is low
    _i2c_slave__read_scl(); // Release SCL
    _i2c_slave__sda = _i2c_slave__read_sda(); // Get current state
}

void i2c_slave__begin_write( xbyte data )
{
    _i2c_slave__data = data;
    _i2c_slave__shift = 6;
    _i2c_slave__state = 3;
    // Write first bit - SDA changes while SCL is low
    DEBUG_GPIO__WRITE_EVENT;
    if( (_i2c_slave__data >> 7) & 1 ) _i2c_slave__sda = _i2c_slave__read_sda();
    else _i2c_slave__sda = _i2c_slave__clear_sda();
    _i2c_slave__scl = _i2c_slave__read_scl(); // Release SCL, get current state
    _i2c_slave__sda = _i2c_slave__read_sda(); // Get current state
}

void i2c_slave__begin_read()
{
    _i2c_slave__state = 6;
    _i2c_slave__shift = 7;
    _i2c_slave__read_sda(); // Release SDA - allow posbbile resulting SDA change while SCL is low
    _i2c_slave__scl = _i2c_slave__read_scl(); // Release SCL, get current state
    _i2c_slave__sda = _i2c_slave__read_sda(); // Get current state
}

void i2c_slave__begin_ack( xbool ack_flag )
{
    _i2c_slave__data = ack_flag;
    _i2c_slave__state = 7;
    // Write bit - SDA changes while SCL is low
    DEBUG_GPIO__WRITE_EVENT;
    if( _i2c_slave__data ) _i2c_slave__sda = _i2c_slave__read_sda();
    else _i2c_slave__sda = _i2c_slave__clear_sda();
    _i2c_slave__scl = _i2c_slave__read_scl(); // Release SCL, get current state
    _i2c_slave__sda = _i2c_slave__read_sda(); // Get current state
}

void i2c_slave__end( void )
{
    _i2c_slave__scl = _i2c_slave__read_scl(); // Release SCL, get current state
    _i2c_slave__sda = _i2c_slave__read_sda(); // Get current state
    _i2c_slave__state = I2C__STATUS__TRANSFER_IDLE;
}

static int _i2c_slave__continue( void )
{
    //led1 <: (_i2c_slave__state & 1) == 1;
    //led2 <: (_i2c_slave__state & 2) == 2;
    //led3 <: (_i2c_slave__state & 4) == 4;

    switch( _i2c_slave__state )
    {
        // Wait for start/stop Condition

        case 1:

        if( _i2c_slave__pins == 0b1110 ) { // scl=1 sda->0 --- START
            DEBUG_GPIO__START_EVENT;
            _i2c_slave__state = 2;
        }
        else if( _i2c_slave__pins == 0b1011 ) { // scl=1 sda->1 --- STOP
            DEBUG_GPIO__STOP_EVENT;
            _i2c_slave__state = 0;
            return I2C__STATUS__EVENT_STOP;
        }
        break;

        case 2:
        if( _i2c_slave__pins == 0b1101 || _i2c_slave__pins == 0b1000 ) { // scl->0 sda=X
            DEBUG_GPIO__START_EVENT;
            _i2c_slave__clear_scl(); // Hold SCL Low
            _i2c_slave__read_sda();  // Release SDA
            _i2c_slave__state = 0;
            return I2C__STATUS__EVENT_START;
        }
        break;

        // Write Bits 6-0

        case 3:
        if( _i2c_slave__pins == 0b1101 || _i2c_slave__pins == 0b1000 ) { // scl->0 sda=X
             DEBUG_GPIO__WRITE_EVENT;
            if( (_i2c_slave__data >> _i2c_slave__shift) & 1 ) _i2c_slave__sda = _i2c_slave__read_sda();
            else _i2c_slave__sda = _i2c_slave__clear_sda();
            if( --_i2c_slave__shift < 0 ) _i2c_slave__state = 4;
            else _i2c_slave__state = 3;
        }
        else if( _i2c_slave__pins == 0b1011 ) { // scl=1 sda->1 --- STOP
            DEBUG_GPIO__STOP_EVENT;
            _i2c_slave__state = 0;
            return I2C__STATUS__EVENT_STOP;
        }
        break;

         // Sense ACK/NACK

        case 4:
        if( _i2c_slave__pins == 0b1101 || _i2c_slave__pins == 0b1000 ) { // scl->0 sda=X
            DEBUG_GPIO__READ_EVENT;
            _i2c_slave__state = 5;
        }
        break;
        case 5:
        if( _i2c_slave__pins == 0b0111 || _i2c_slave__pins == 0b0010 ) { // scl->1 sda=X
            DEBUG_GPIO__READ_EVENT;
            _i2c_slave__ackflag = _i2c_slave__read_sda();
        }
        if( _i2c_slave__pins == 0b1101 || _i2c_slave__pins == 0b1000 ) { // scl->0 sda=X
            _i2c_slave__clear_scl(); // Hold SCL Low
            _i2c_slave__read_sda();  // Release SDA
            _i2c_slave__state = 0;
            return I2C__STATUS__EVENT_WRITE;
        }
        break;

        // Read Bits 7-0

        case 6:
        if( _i2c_slave__pins == 0b0111 || _i2c_slave__pins == 0b0010 ) { // scl->1 sda=X
            DEBUG_GPIO__READ_EVENT;
            _i2c_slave__data = (_i2c_slave__data << 1) + _i2c_slave__read_sda();
        }
        else if( _i2c_slave__pins == 0b1101 || _i2c_slave__pins == 0b1000 ) { // scl->0 sda=X
            DEBUG_GPIO__READ_EVENT;
            if( --_i2c_slave__shift >= 0 ) _i2c_slave__state = 6;
            else {
                _i2c_slave__clear_scl(); // Hold SCL Low
                _i2c_slave__read_sda();  // Release SDA
                _i2c_slave__state = 0;
                //printstr("READ: "); printhexln(_i2c_slave__data);
                return I2C__STATUS__EVENT_READ;
            }
        }
        else if( _i2c_slave__pins == 0b1011 ) { // scl=1 sda->1 --- STOP
            DEBUG_GPIO__STOP_EVENT;
            _i2c_slave__state = 0;
            return I2C__STATUS__EVENT_STOP;
        }
        break;

        // Assert ACK/NACK

        case 7:
        if( _i2c_slave__pins == 0b1101 || _i2c_slave__pins == 0b1000 ) { // scl->0 sda=X
            DEBUG_GPIO__WRITE_EVENT;
            _i2c_slave__clear_scl(); // Hold SCL Low
            _i2c_slave__read_sda();  // Release SDA
            _i2c_slave__state = 0;
            return I2C__STATUS__EVENT_ACK;
        }
        else if( _i2c_slave__pins == 0b1011 ) { // scl=1 sda->1 --- STOP
            DEBUG_GPIO__STOP_EVENT;
            _i2c_slave__state = 0;
            return I2C__STATUS__EVENT_STOP;
        }
        break;
    }
    return I2C__STATUS__TRANSFER_BUSY;
}

select i2c_slave__io_status( int& status )
{
    case _i2c_slave__port_scl when pinseq(!_i2c_slave__scl) :> _i2c_slave__scl:

        //led1 <: 1; for(;;);
        _i2c_slave__pins = ((!_i2c_slave__scl)<<3) + (_i2c_slave__sda<<2) + (_i2c_slave__scl<<1) + _i2c_slave__sda;
        if( _i2c_slave__scl == 0 ) _i2c_slave__read_sda(); // release SDA on every SCL transition to low
        status = _i2c_slave__continue();
        break;

    case _i2c_slave__port_sda when pinseq(!_i2c_slave__sda) :> _i2c_slave__sda:

        //led2 <: 1; for(;;);
        _i2c_slave__pins = (_i2c_slave__scl<<3) + ((!_i2c_slave__sda)<<2) + (_i2c_slave__scl<<1) + _i2c_slave__sda;
        status = _i2c_slave__continue();
        break;
}

int i2c_slave__start( void )
{
    int status;
    i2c_slave__begin_start();
    while( TRUE ) {
        select {case i2c_slave__io_status( status );}
        if( status != 0 ) break;
    }
    printintln( status );
    return status;
}

int i2c_slave__stop( void )
{
    int status;
    i2c_slave__begin_stop();
    while( TRUE ) {
        select {case i2c_slave__io_status( status );}
        if( status != 0 ) break;
    }
    return status;
}

int i2c_slave__write( xbyte data, xbyte& ack_flag )
{
    int status;
    i2c_slave__begin_write( data );
    while( TRUE ) {
        select {case i2c_slave__io_status( status );}
        if( status != 0 ) break;
    }
    ack_flag = _i2c_slave__ackflag;
    return status;
}

int i2c_slave__read( xbyte& data )
{
    int status;
    i2c_slave__begin_read();
    while( TRUE ) {
        select {case i2c_slave__io_status( status );}
        if( status != 0 ) break;
    }
    data = _i2c_slave__data;
    return status;
}

int i2c_slave__ack( xbyte ack_flag )
{
    int status;
    i2c_slave__begin_ack( ack_flag );
    while( TRUE ) {
        select {case i2c_slave__io_status( status );}
        if( status != 0 ) break;
    }
    return status;
}

// ====================================================================================================================
// ====================================================================================================================
