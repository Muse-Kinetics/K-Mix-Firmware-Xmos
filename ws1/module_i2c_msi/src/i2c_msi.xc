#include <xs1.h>
#include <print.h>
#include "i2c_msi_config.h"
#include "i2c_msi.h"
#include "i2c_msi_c.h"
#include "xscope_user_i2c.h"
#ifdef XSCOPE
#include "xscope.h"
#endif
#include "ports.h"



port _i2c__port_scl = I2C__SCL_PORT;
port _i2c__port_sda = I2C__SDA_PORT;

#ifdef STARTKIT_I2C_TESTER

#define DEBUG_PORT_MSI_DECLARATION  port _debug_port_msi = XS1_PORT_1H;
#define DEBUG_PORT_MSI_RELEASE  _debug_port_msi :> void;
#define DEBUG_PORT_MSI_LOW      _debug_port_msi <: 0;


#else
#define DEBUG_PORT_MSI_DECLARATION
#define DEBUG_PORT_MSI_RELEASE
#define DEBUG_PORT_MSI_LOW
#endif


DEBUG_PORT_MSI_DECLARATION


typedef unsigned char xbyte;

//void i2c_slave_read_prepare(SERVER_SLAVE);
void i2c_reset_sda();


xbyte _i2c__scl;
xbyte _i2c__sda;

xbyte ack_nak;

int tx_count;


void stop_here()
{

}


void debug_put_sync()
{
    DEBUG_PUT_STATE(DEBUG_SYNC);
}


timer t_i2c;
unsigned int scl_time,newtime;

#define RX_START_BIT (!_i2c__sda && _i2c__scl)
#define RX_STOP_BIT (_i2c__sda && _i2c__scl)
#define RISING_CLOCK    (_i2c__scl)

void scl_low(int source)
{
    _i2c__port_scl <: 0;
    _i2c__scl = 0;
//    set_port_a32(TEST_POINT2,0);
//    DEBUG_PORT_MSI_LOW

#ifdef RECORD_I2C_STATE
    xscope_int(XSCOPE_USER_I2C_SCL_STATE,0);
    xscope_int(XSCOPE_USER_I2C_SCL_STATE,source);
#endif
}
void scl_release()
{
    _i2c__port_scl :> void;
//    DEBUG_PORT_MSI_RELEASE
//    set_port_a32(0,TEST_POINT2);

#ifdef RECORD_I2C_STATE
    xscope_int(XSCOPE_USER_I2C_SCL_STATE,1);
#endif
}

#define SCL_LOW(x) \
                       {scl_low(x);}

#define SCL_RELEASE    scl_release()

void sda_release()
{
    _i2c__port_sda :> void;
    _i2c__sda = 1;
//    set_port_a32(0,TEST_POINT1);
#ifdef RECORD_I2C_STATE
    xscope_int(XSCOPE_USER_I2C_SDA_STATE,1);
#endif

}

int sda_low_count = 0;

void sda_low(int source)
{
    _i2c__port_sda <: 0;
    _i2c__sda = 0;
//    set_port_a32(TEST_POINT1,0);

#ifdef RECORD_I2C_STATE
    xscope_int(XSCOPE_USER_I2C_SDA_STATE,0);
    xscope_int(XSCOPE_USER_I2C_SDA_STATE,source);
#endif
}

#define SDA_LOW(source) \
                       {sda_low(source);}

#define SDA_LOW2 {sda_low2();}

#define SDA_RELEASE     {sda_release();}


#define SLAVE           (i2cx.slave_flag)
#define MASTER    (i2cx.master_flag)
#define MASTER_TX (i2cx.master_writer_flag)
#define SLAVE_TX (i2cx.slave_writer_flag)
#define READ   (i2cx.read_flag)
#define ACTIVE          (i2cx.active_flag)
#define BUS_BUSY        (i2cx.bus_busy_flag)
#define DATA_BIT        (i2cx.data_bit_flag)
#define SUSPENDED (i2cx.suspend_flag)
#define RESET_BIT_COUNT i2cx.bit_count = 8;

struct {
    int slave_address;
    int max_slave_bytes;  // max bytes this slave can receive
} i2c_config;


I2CX i2cx;

enum {I2C_STATE_NONE, I2C_STATE_ID, I2C_STATE_ACKNAK_ID, I2C_STATE_DATA, I2C_STATE_ACKNAK_DATA, I2C_STATE_TRANSITION, I2C_STATE_STOP1, I2C_STATE_STOP2, I2C_STATE_STOP3, I2C_STATE_START1, I2C_STATE_START2};

enum {MASTER_DISABLE, MASTER_ENABLE};


MASTER_EVENTS master_events[I2C_TX_INTERFACE_COUNT];
SLAVE_EVENTS slave_events;
SLAVE_RX_INFO_TYPE slave_rx_info;


#ifdef I2C_SQUARE_WAVE


void i2c_square_wave(int khz)
{
    unsigned int time,time_inc = 1E5/khz/2;

    t_i2c :> time;

    for(;;)
    {
        time += time_inc;
        t_i2c when timerafter(time) :> void;
        SCL_LOW(0)

        SDA_LOW(0)

        time += time_inc;
        t_i2c when timerafter(time) :> void;
        SCL_RELEASE;

        time += time_inc;
        t_i2c when timerafter(time) :> void;
        SCL_LOW(0)

        SDA_RELEASE;

        time += time_inc;
        t_i2c when timerafter(time) :> void;
        SCL_RELEASE;


    }

}
#endif


void i2c_msi_set_address(int address)
{
    i2c_config.slave_address = address;
}


void i2c_msi_init(int i2c_address_slave)
{



#ifdef DEBUG_PUT_USE_XSCOPE
#ifdef XSCOPE
    xscope_register(1,XSCOPE_CONTINUOUS, "debug_put", XSCOPE_UINT, "units");
#endif
#endif

    DEBUG_PORT_MSI_RELEASE

    _i2c__port_sda :> _i2c__sda;
    _i2c__port_scl :> _i2c__scl;


    MASTER = SLAVE = ACTIVE = 0;

    i2c_msi_set_address(i2c_address_slave);

//    i2c_config.slave_address = 0;
    i2c_config.max_slave_bytes = sizeof(slave_rx_info.buffer_rx);

    i2c_queue_init();

    for (int i=0;i<I2C_TX_INTERFACE_COUNT;i++)
    {
        master_events[i].count = 0;
        master_events[i].index_in = 0;
        master_events[i].index_out = 0;
    }

    i2c_init_lock();

//    set_port_a32(0,TEST_POINT1);
//    set_port_a32(0,TEST_POINT2);

}




void i2c_reset_sda()
{
    timer t;
    unsigned int time;

    for(;;)
    {
        if (peek(_i2c__port_sda))
            break;

        SCL_LOW(0)

        t :> time;
        time += 1E5;
        t when timerafter(time) :> time;

        SCL_RELEASE;
        t :> time;
        time += 1E5;
        t when timerafter(time) :> time;

    }
}




void master_event_buffer_push(int index,int event,char *unsafe buffer,int len,int user_id)
{
    DEBUG_PUT_VAL(DEBUG_MASTER_EVENT_PUSH,event);

   if ( master_events[index].count < MAX_MASTER_EVENTS )
    {
        master_events[index].events[master_events[index].index_in].type = event;
        master_events[index].events[master_events[index].index_in].buffer = buffer;
        master_events[index].events[master_events[index].index_in].count = len;
        master_events[index].events[master_events[index].index_in].user_id = user_id;
        master_events[index].events[master_events[index].index_in].ack_state = i2cx.ack_state;
        if (++master_events[index].index_in == MAX_MASTER_EVENTS)
            master_events[index].index_in = 0;
        master_events[index].count++;
    }
}
void slave_event_buffer_push(int event,char *unsafe buffer,int len)
{
    DEBUG_PUT_STATE(DEBUG_SLAVE_EVENT_PUSH);

    if ( slave_events.count < MAX_MASTER_EVENTS )
    {
        DEBUG_PUT_STATE(event);

        slave_events.events[slave_events.index_in].type = event;
        slave_events.events[slave_events.index_in].buffer = buffer;
        slave_events.events[slave_events.index_in].count = len;
        if (++slave_events.index_in == MAX_MASTER_EVENTS)
            slave_events.index_in = 0;
        slave_events.count++;
    }
}

void i2c_clear_state(void)
{
    MASTER = MASTER_TX = SLAVE = SLAVE_TX = ACTIVE = 0;

}

void initiate_start(chanend chan_client[NTX],chanend chan_server[NTX],unsigned int NTX);



void rx_start_bit_init(int master_flag)
{

    MASTER = master_flag;
    MASTER_TX = master_flag;
    SLAVE_TX = 0;
    SLAVE = 1;
    ACTIVE = 1;
    i2cx.state = I2C_STATE_ID;
    RESET_BIT_COUNT

    i2cx.transfer_count = 0;
    i2cx.bit_count = 0;
    i2cx.slot_index = 0;
    i2cx.tx_index = 0;
    i2cx.data_rx_count = 0;

    i2cx.nak_count = 0;

    if (master_flag)
    {
        READ = 0;
        i2cx.master_tx_count = 0;
        copy_tx_queue_front();
    } else
        READ = (i2cx.data_tx & 1);

    SUSPENDED = 0;



}


void i2c_msi_suspend_clear()
{
    SUSPENDED = 0;
}

extern void i2c_slave_rx(SERVER_SLAVE);
extern void i2c_master_rx(SERVER_SLAVE,int user_id);

void i2c_rx_check(chanend chan_client[NTX],unsigned int NTX)
{
    if (i2cx.data_rx_count)
    {
        if (SLAVE && !SLAVE_TX)
        {
            slave_rx_info.count = i2cx.data_rx_count;

            DEBUG_PUT_VAL(DEBUG_SLAVE_EVENT_RX,i2cx.data_rx_count);

            slave_event_buffer_push(SLAVE_EVENT_RX,slave_rx_info.buffer_rx,slave_rx_info.count);
            outct (chan_client[0], XS1_CT_END );
//            i_i2c_msi_rx.notify_slave_event();

//            i2c_slave_rx(SERVER_SLAVE_PASS);
        }
        i2cx.data_rx_count = 0;  // so we don't rx this data again.
    }
}

void i2c_execute_transaction_id(SERVER_SLAVE,server interface i2c_msi_tx_if i_i2c_tx[ntx],unsigned int ntx,chanend ?chan_error);
void rx_stop_bit(chanend ?chan_poke);

extern void signal_error(void);




void set_state_data()
{
    i2cx.state = I2C_STATE_DATA;
    RESET_BIT_COUNT

}


int start_count = 0;


#define SCL_RISE    0
#define SCL_FALL    1


void initiate_start(chanend chan_client[NTX],chanend chan_server[NTX],unsigned int NTX)
{
    start_count++;

    DEBUG_PUT_STATE(DEBUG_START_ASSERTED);

    t_i2c :> scl_time;

    select {
        case t_i2c when timerafter(scl_time+300) :> scl_time:  // enforce delay between stop and start here
            SDA_LOW(4)  // cause a start
            rx_start_bit_init(MASTER_ENABLE);
            break;

        case _i2c__port_sda when pinseq(0) :> _i2c__sda:  // while we were waiting, a start was detected
            rx_start_bit_init(MASTER_DISABLE);
            break;
    }
    i2c_msi_bit(SCL_FALL,chan_client,chan_server,NTX);
}







void i2c_tx_queue_check(chanend chan_client[NTX],chanend chan_server[NTX],unsigned int NTX)
{
    if (!ACTIVE)
    {
//        if (i2c_queue.count)
        while (!i2c_queue_empty())
        {
#ifdef XSCOPE_DEBUG_MIDI
                xscope_int(XSCOPE_SERVE_MIDI_FROM_HOST,13);
#endif
//            DEBUG_PUT_VAL(DEBUG_QUEUE_TX,i2c_queue.count*10000 + i2c_queue.back*100 + i2c_queue.front);
            initiate_start(chan_client,chan_server,NTX);
        }
    }
}

#ifdef UNUSED
asm("ldw %0,%1[%2]": "=r"(period): "r"(injection.Periodtime),"r"(i));
asm volatile ("stw %0, %1[9]"::"r"(0), "r"(two));

asm("ldw %0,%1[0]": "=r"(period): "r"(injection.Periodtime));

asm("ldw %0, %1[%2]":"=r"(sample):"r"(dac_buffer_address),"r"(o));\
asm("stw %0, %1[%2]"::"r"(sample),"r"(adc_buffer_address),"r"(i));

asm("mov %0, %1" : "=r"(id): "r"(c));

#define LDW(dest,source) asm("ldw %0,%1[0]": "=r"(dest): "r"(source));
#define MOV(dest,source) asm("mov %0, %1" : "=r"(dest): "r"(source));

#endif


unsafe{
int i2c_msi_write_reg_word(int dest_address, int dest_reg,unsigned int data,int interface_index)
{

    i2c_acquire_lock();

    DEBUG_PUT_STATE(DEBUG_MASTER_WRITE_REG_WORD);

    if (i2c_enqueue_common(dest_address,dest_reg,4,interface_index,0))
    {
        i2c_queue_set_data_address(data);
        advance_queue();
        i2c_release_lock();
        return 1;
    }
    else
        DEBUG_PUT_STATE(DEBUG_MASTER_WRITE_REG_WORD_FULL);

    i2c_release_lock();

    return 0;
}
}

int  i2c_msi_write_reg_buffer(int dest_address, int dest_reg,unsigned char * unsafe buffer, int len,int interface_index)
{
    int rval;

    i2c_acquire_lock();

    rval =  i2c_enqueue_buffer(dest_address,dest_reg,buffer,len,interface_index,0);

    i2c_release_lock();

    return rval;
}

int i2c_msi_read_buffer(int dest_address,unsigned char * unsafe buffer, int len,int interface_index,int read_id)
{
    int rval;

    i2c_acquire_lock();

    rval = i2c_enqueue_buffer( dest_address | 1,0,buffer,len,interface_index,read_id);

    i2c_release_lock();

    return rval;
}

int ms_event(int num)
{

#ifdef XSCOPE_DEBUG_I2C
//    xscope_int(XSCOPE_USER_I2C_ENTER_SELECT,num);
#endif
    return 1;
}



//#ifdef USE_I2C_MSI_BIT

int i2c_msi_bus_free()
{
    return !ACTIVE;
}

#define SCL_HIGH_TIME   1
#define SCL_LOW_TIME    1

void i2c_wait(int delay)
{
                        t_i2c :> scl_time;
                        scl_time += delay;
                        t_i2c when timerafter(scl_time) :> scl_time;

}

void stop_bit_sequence(int low_wait_time)
{
    if (low_wait_time)
    {
        i2c_wait(low_wait_time);

        SCL_RELEASE;
        select {case _i2c__port_scl when pinseq(1) :> _i2c__scl: break;}
    }


    i2c_wait(100);
    SCL_LOW(0);
    i2c_wait(100/2);
    SDA_LOW(0);
    i2c_wait(100/2);

    SCL_RELEASE;
    select {case _i2c__port_scl when pinseq(1) :> _i2c__scl: break;}

    i2c_wait(100);
    SDA_RELEASE

    MASTER = MASTER_TX = 0;
    ACTIVE = 0;

}

void restart_bit_sequence(void)
{
    i2c_wait(100);

    SCL_RELEASE;
    select {case _i2c__port_scl when pinseq(1) :> _i2c__scl: break;}

    i2c_wait(100);
    SCL_LOW(0);

    i2c_wait(100/2);
    SDA_RELEASE
    i2c_wait(100/2);

    SCL_RELEASE;
    select {case _i2c__port_scl when pinseq(1) :> _i2c__scl: break;}

}

void sequence_to_next_transfer(){

    advance_queue_front();

    if (!i2c_queue_empty())
        restart_bit_sequence();  // setup up for restart, and let i2c_queue_check start the next master action
    else
        stop_bit_sequence(SCL_LOW_TIME);
}

extern int debug_count_stop;

void push_master_event(int ack_state,int event,chanend chan_client[NTX],unsigned int NTX)
{


    int index = i2c_queue_front_interface_index();

    if (index>=0)
    {
        i2cx.ack_state = ack_state;
        master_event_buffer_push(index,event,i2cx.master_ptr,i2cx.data_rx_count,i2cx.user_id);
        outct (chan_client[index], XS1_CT_END );
    }
}

#ifdef UNUSED
select i2c_msi_select_data_bit_low()
{
    case MASTER => t_i2c when timerafter(scl_time) :> scl_time:
        DATA_BIT=1;
        break;
    case _i2c__port_scl when pinseq(0) :> _i2c__scl:
        DATA_BIT = 1;
        break;
    case _i2c__port_sda when pinsneq(_i2c__sda) :> _i2c__sda:
        DATA_BIT = 0;
        // start or stop bit detected
        break;
}
#endif

extern int last_address_destination;
int data_count = 0;

//#define I2C_FILTER_SDA

void i2c_msi_bit(int bit_state,chanend chan_client[NTX],chanend chan_server[NTX],unsigned int NTX)
{
    for(;;)
    {
        if (bit_state == SCL_RISE)
        {

                _i2c__sda = peek(_i2c__port_sda);

//                set_port_a32(LED2,0);

                if (i2cx.bit_count<8)
                {
                    i2cx.data_rx <<= 1;
                    i2cx.data_rx |= _i2c__sda;
                    i2cx.bit_count++;
                } else
                {
                    // read ack/nak here.
                    i2cx.bit_count = 0;

                    if (_i2c__sda)
                    {
                        if (SLAVE && SLAVE_TX)
                        {
                            DEBUG_PUT_STATE(DEBUG_SLAVE_RX_NAK);
                            SLAVE = SLAVE_TX = 0;
                        }
                        if (MASTER)
                        {
                            i2c_wait(50);
                            SCL_LOW(0)

                            push_master_event(I2C_NAK,MASTER_EVENT_TX,chan_client,NTX);

                            sequence_to_next_transfer();
                            return;
                        }
                    }
                }
                bit_state = SCL_FALL;
//                set_port_a32(0,LED2);


        }



        if (bit_state == SCL_FALL)  // SCL_FALL
        {

//#ifdef UNUSED


#ifdef UNUSED
             select {case i2c_msi_select_data_bit_low();}  // select routines appear to be very slow getting into.  put inline instead
#endif


             if (MASTER)
             {
                 t_i2c :> scl_time;
                 scl_time += 90;

                 do
                 {
                     unsigned char tmp;
#pragma ordered
                     select
                     {
                        case inct_byref (chan_server[int i], tmp ): // receive notification
                            DATA_BIT = 2;
                            break;

                        case t_i2c when timerafter(scl_time) :> scl_time:
                            DATA_BIT = 1;
                            break;
                        case _i2c__port_scl when pinseq(0) :> _i2c__scl:
                            DATA_BIT = 1;
                            break;
                        case _i2c__port_sda when pinsneq(_i2c__sda) :> _i2c__sda:
                            DATA_BIT = 0;
                            // start or stop bit detected
                            break;
                     }
                  } while (DATA_BIT == 2);

             } else
             {
//#pragma ordered
//                 set_port_a32(TEST_POINT1,0);
//                 set_port_a32(0,TEST_POINT1);

                 t_i2c :> scl_time;
//                 scl_time += 10000000;
//                 scl_time += 1E7;  // this seems to take a long time, don't use E notation

                 select {
//#ifdef UNUSED
                    case t_i2c when timerafter(scl_time + 10000000) :> void :
                        SLAVE = SLAVE_TX = ACTIVE = 0;
//                        set_port_a32(TEST_POINT1,0);
//                        set_port_a32(TEST_POINT2,0);
                        return;
//#endif

                    case _i2c__port_scl when pinseq(0) :> _i2c__scl:
                        DATA_BIT = 1;

//                    set_port_a32(TEST_POINT2,0);
//                    set_port_a32(0,TEST_POINT2);
                        break;
//#ifdef UNUSED
                    case _i2c__port_sda when pinsneq(_i2c__sda) :> _i2c__sda:

#ifdef I2C_FILTER_SDA
                            t_i2c :> scl_time;
                            t_i2c when timerafter(scl_time+20) :> scl_time;
//                        asm("nop;nop;");
//                    asm("nop;nop;");
//                    asm("nop;nop;");
//                    asm("nop;nop;");


                        _i2c__port_scl :> _i2c__scl;

                        if (_i2c__scl)
                            DATA_BIT = 0;
                        else
                            DATA_BIT = 1;

                        break;
#else
                        DATA_BIT = 0;
#endif
                            // start or stop bit detected
                        break;
//#endif
                 }

             }


                if (DATA_BIT)
                {

                    SCL_LOW(0);


                    if (i2cx.bit_count<8)
                    {
                        if (SLAVE_TX || MASTER_TX)
                        {
                            if (i2cx.data_tx & 0x80)
                                SDA_RELEASE
                            else
                                SDA_LOW(0)

                            i2cx.data_tx <<=1;
                        } else
                            SDA_RELEASE
                    }else
                    {   // ACK BIT

                        if (debug_count_stop)
                        {
                            if (!--debug_count_stop)
                                debug_count_stop = 45;
                        }
                        if (i2cx.slot_index)
                        {
                            if (SLAVE)
                            {
                                if (SLAVE_TX)
                                    SDA_RELEASE
                                else
                                {
                                    SDA_LOW(0)
                                    if (i2cx.data_rx_count<I2C_SLAVE_MAX_RX)
                                        slave_rx_info.buffer_rx[i2cx.data_rx_count++] = i2cx.data_rx;

//                                    i_i2c_msi_rx.data_rx(i2cx.slot_index-1,i2cx.data_rx);
                                    DEBUG_PUT_VAL(DEBUG_SLAVE_RX_DATA,i2cx.data_rx);
                                }
                            }
                            if (MASTER  && !MASTER_TX)
                            {

                                unsafe{
                                    i2cx.master_ptr[i2cx.data_rx_count] = i2cx.data_rx;
                                    i2cx.data_rx_count++;
                                    DEBUG_PUT_VAL(DEBUG_MASTER_RX_DATA,i2cx.data_rx);
                                }

                                if (i2cx.data_rx_count < i2cx.transfer_count)
                                {
                                    SDA_LOW(3)
                                }
                                else
                                {
                                    SDA_RELEASE     // indicate no more bytes to read

                                    push_master_event(I2C_ACK,MASTER_EVENT_RX,chan_client,NTX);

                                    sequence_to_next_transfer();
                                    return;
                                }
                            }
                        }
                        else
                        {
                             if ( (i2cx.data_rx & 0xFE) == i2c_config.slave_address )
                            {
//                                i_i2c_msi_rx.address_rx(i2cx.data_rx);

                                if (i2cx.data_rx & 1)
                                    SLAVE_TX = 1;
                                else
                                    SLAVE_TX = 0;

                                SDA_LOW(0)
                            }
                            else
                            {
                                DEBUG_PUT_VAL(DEBUG_EVENT_SLAVE_WRONG_ADDRESS,i2cx.data_rx);
                                SLAVE = 0;

                                if (!MASTER_TX)
                                    SDA_RELEASE
                            }
                        }

                        for(;;)
                        {
                            if (MASTER_TX)
                            {
                                if (i2cx.data_tx_orig != i2cx.data_rx)
                                {
                                    last_address_destination = 0;  // debugging
                                    MASTER = MASTER_TX = 0;  // lost arbitration
                                    DEBUG_PUT_VAL(DEBUG_LOST_ARB_MASTER,0);
                                    break;
                                }

                                if (!i2cx.slot_index &&i2cx.data_tx_orig & 1)
                                {
                                    MASTER_TX = 0;
                                    break;
                                }

                                if (i2cx.dest_reg == -1)
                                {
                                     if (i2cx.master_tx_count++ < i2cx.transfer_count)
                                     {
                                          unsafe {i2cx.data_tx = i2cx.data_tx_orig = i2cx.master_ptr[i2cx.tx_index];i2cx.tx_index++;}
                                     } else
                                     {
                                         i2c_rx_check(chan_client,NTX);
                                          push_master_event(I2C_ACK,MASTER_EVENT_TX,chan_client,NTX);
                                          sequence_to_next_transfer();
                                          return;
                                     }
                                } else
                                {
                                    i2cx.data_tx = i2cx.data_tx_orig = i2cx.dest_reg;
                                    i2cx.dest_reg = -1;
                                }
                                DEBUG_PUT_VAL(DEBUG_MASTER_TX_DATA,i2cx.data_tx);
                            }
                            break;
                       }

                       if (SLAVE_TX)
                          i2cx.data_tx = i2cx.data_tx_orig = slave_rx_info.buffer_tx[i2cx.slot_index];

                       i2cx.slot_index++;

                    }

                    if (MASTER)
                        i2c_wait(78);

                    SCL_RELEASE;

                    select {case _i2c__port_scl when pinseq(1) :> _i2c__scl: break;}

                    bit_state = SCL_RISE;
                } else
                {
                    i2c_rx_check(chan_client,NTX);
//                    i_i2c_msi_rx.startstop();

                    if (_i2c__sda)  // rx stop bit
                    {
                        DEBUG_PUT_STATE(DEBUG_STOP_DETECTED);
                        ACTIVE = SLAVE = 0;
                        return;
                    } else
                    {
                        DEBUG_PUT_STATE(DEBUG_START_DETECTED);
                        rx_start_bit_init(MASTER_DISABLE);
                        bit_state = SCL_FALL;
                    }
                }
//#endif
        }
    }
}

select i2c_msi_start_select(chanend chan_poke_client[NTX],chanend chan_poke_server[NTX],unsigned int NTX)
{
    case _i2c__port_sda when pinseq(0) :> _i2c__sda:
        ACTIVE = 1;

        rx_start_bit_init(MASTER_DISABLE);


        i2c_msi_bit(SCL_FALL,chan_poke_client,chan_poke_server,NTX);

        break;


}

select i2c_msi_bus_select(chanend chan_poke_client[NTX],unsigned int NTX)
{
#ifdef UNUSED
           case (scl_release_check(SLAVE && !MASTER && !SUSPENDED) ) => _i2c__port_scl when pinseq(1) :> _i2c__scl:
               _i2c__sda = peek(_i2c__port_sda);


               i2c_msi_bit(SCL_RISE,chan_poke_client);
                break;
#endif
}

void break_here()
{
    stop_here();
}

//#endif


