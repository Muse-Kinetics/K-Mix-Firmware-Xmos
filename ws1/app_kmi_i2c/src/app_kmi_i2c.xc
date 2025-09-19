
#include <xs1.h>
#include <print.h>
#include <xscope.h>
#include "startkit_gpio.h"
#include "i2c_msi.h"
#include "i2c_msi_c.h"
#include "xscope_user.h"

#define DEBUG_PORT_APP_DECLARATION port _i2c_debug_port_app = XS1_PORT_1G;
#define DEBUG_PORT_APP_LOW _i2c_debug_port_app <: 0;
#define DEBUG_PORT_APP_RELEASE _i2c_debug_port_app :> void;

//#define ASYNC_POKE_TEST

DEBUG_PORT_APP_DECLARATION

void stop_here(void);

//#define SCHEDULE_ON_COMPLETION

I2C_TESTING_ADDRESS i2c_address;

#define  USE_TEST_MASTER_READ
#define  USE_TEST_MASTER_TX

enum {
#ifdef USE_TEST_MASTER_READ
    TEST_MASTER_READ,
#endif
#ifdef USE_TEST_MASTER_TX
    TEST_MASTER_TX,
#endif
    TEST_END};

//code const char test_targets[] = { 0x80,0x84 };
char test_targets[5] = { 0x20 };
//char test_targets[] = { 0x40 };

//#define NUM_TARGETS sizeof(test_targets)

int NUM_TARGETS = 0;

#ifdef ERROR_AFTER_TX_COUNT
int error_after_tx_count = ERROR_AFTER_TX_COUNT;
#endif

#define MAX_SOURCES 10
#define MAX_TARGETS 5

struct { timer test_timer;char enable,type,target_index,local_index,interface_index,slave_rx_error_count,master_rx_error_count;unsigned char sources[MAX_SOURCES];unsigned int time;unsigned long master_tx_vals[MAX_TARGETS],master_rx_vals[MAX_TARGETS],slave_tx_vals[MAX_TARGETS],slave_rx_vals[MAX_TARGETS];} test = {0,0,0};


unsigned int packet_tx_time = 0;

timer t_tx;


unsigned int crc32_remainder=1;

#define US  1E2
#define MS  1E5

#define INTERVAL_MIN    (5*MS)
#define INTERVAL_MAX    (5*MS)

unsigned char get_source_index(unsigned char source);
void test_write_read(chanend ?chan_poke);
void test_write(chanend ?chan_poke);
void test_reset(void);
void show_error(client startkit_led_if ?i_led,client startkit_button_if ?i_button,int error_num);
void serve_master_event_buffer(int index,client startkit_led_if ?i_led,client startkit_button_if ?i_button);

enum {READ_ID_NONE,READ_ID_TEST};

void timer_test()
{
    timer test_timer;
    unsigned int k,time1;

    test_timer:> time1;

    for (k=0;k<100;k++)
    {
        time1 += 1E8;
        test_timer when timerafter(time1) :> time1;

        printhexln(k);

    }
}

unsigned int random_interval(unsigned int interval_min,unsigned int interval_max)
{
    long long mresult;

    crc32(crc32_remainder, crc32_remainder, 0x04C11DB7);

    mresult = (interval_max - interval_min + 1) * (long long) crc32_remainder;

    mresult >>= 27;

    return mresult + interval_min       ;
//    return crc32_remainder;
}

void test_random()
{
    unsigned int i,smallest,largest,tx_time;

    smallest = largest = random_interval(INTERVAL_MIN,INTERVAL_MAX);

    for (i=0;i<100000;i++)
    {
        tx_time = random_interval(INTERVAL_MIN,INTERVAL_MAX);

        if (tx_time < smallest)
            smallest = tx_time;

        if (tx_time > largest)
            largest = tx_time;
    }

    printhexln(smallest);
    printhexln(largest);

}


void schedule_event()
{
    test.target_index = random_interval(0,NUM_TARGETS-1);

    test.type = random_interval(0,TEST_END-1);

    test.interface_index = random_interval(0,I2C_TX_INTERFACE_COUNT-1);


    test.test_timer :> test.time;

    test.time += random_interval(1,1E8/64);  // 1E8/2 =  aproximately .5 second

}


struct {timer t;unsigned int time;} led_info[3];

timer t_led_rx,t_led_tx;
unsigned int led_rx_time = 0,led_tx_time = 0;

void led_start(client startkit_led_if ?i_led,int index)
{
    led_info[index].t :> led_info[index].time;
    led_info[index].time += 1E6;
    i_led.set(2,index,LED_ON);
}



char master_read_buffer[5];
#define MAX_SLAVE_RX_COUNT  10
struct {int packet_count,index;unsigned char buffer[MAX_SLAVE_RX_COUNT];} slave_rx;

void debug_port_toggle(void);

int global_error_val;

int debug_error_count = 0;


//[[combinable]]
void app_task(
        client startkit_led_if ?i_led,
        client startkit_button_if ?i_button,
        chanend ?chan_error,
        chanend chan_client[NTX],
        chanend chan_server[NTX],
        unsigned int NTX
)
{
#if defined(SIGNAL_MONITOR)
    DEBUG_PORT_APP_RELEASE
#endif
    unsigned char tmp;

    led_info[0].time = 0;
    led_info[1].time = 0;

    slave_rx.packet_count=0;


    while(1)
    {
        select
        {

            case _i2c_debug_port_app when pinseq(0) :> void:
#ifdef SYNC_ON_SIGNAL
                debug_put_sync();
                debug_put_sync();
                debug_put_sync();
#endif
#ifdef BREAK_ON_SIGNAL
            for(;;);
#endif
                break;



            case i_button.changed():
                    button_val_t val = i_button.get_value();
                    if (val == BUTTON_DOWN) {

#ifdef ASYNC_POKE_TEST
#endif

                        i_led.set(0,0,LED_ON);


                        if (test.enable)
                        {
//                            test_reset();
                            test.enable = 0;
                            i_led.set(2,2,LED_OFF);
                            i_led.set(0,2,LED_OFF);
                        } else
                        {

//                          i_i2c_msi_tx.i2c_master_write_reg_word(i2c_address.b,5,0x00008000,I2C_NOTIFY_COMPLETION_NO);  // send to ourselves
//                          i_i2c_msi_tx.i2c_master_write_reg_word(i2c_address.remote_8051,5,0x11111191,I2C_NOTIFY_COMPLETION_NO);  // send to ourselves
//                          i_i2c_msi_tx.i2c_master_write_reg_word(i2c_address.remote_8051 ,5,0,I2C_NOTIFY_COMPLETION_NO);  // send to ourselves

//                          i_i2c_msi_tx.i2c_master_read_buffer(i2c_address.remote_8051,master_read_buffer,4,I2C_NOTIFY_COMPLETION_YES,READ_ID_TEST);

//                          test_write_read(chan_poke_server);
//                          test_write(chan_poke_server);

                            test.enable = 1;
                            schedule_event();
                            i_led.set(0,2,LED_ON);

#ifdef SIGNAL_ON_START
                DEBUG_PORT_LOW
                DEBUG_PORT_RELEASE
#ifdef SYNC_ON_SIGNAL
                debug_put_sync();
                debug_put_sync();
                debug_put_sync();
#endif

#endif

                        }

                    } else
                        i_led.set(0,0,LED_OFF);


                    break;



            case inct_byref (chan_client[int i], tmp ): // receive notificatio

                    serve_master_event_buffer(i,i_led,i_button);
                    break;


            case (led_info[0].time) => led_info[0].t when timerafter(led_info[0].time) :> void:

                led_info[0].time = 0;
                i_led.set(2,0,LED_OFF);

                break;

            case (led_info[1].time) => led_info[1].t when timerafter(led_info[1].time) :> void:

                led_info[1].time = 0;
                i_led.set(2,1,LED_OFF);

                break;

            case (test.enable && test.time) => test.test_timer when timerafter(test.time) :> void:

                test.time = 0;

                switch(test.type)
                {
#ifdef  USE_TEST_MASTER_TX
                    case TEST_MASTER_TX:

                        test_write(chan_server[test.interface_index]);

#ifndef SCHEDULE_ON_COMPLETION
                            schedule_event();
#endif


                    break;
#endif

#ifdef  USE_TEST_MASTER_READ
                    case TEST_MASTER_READ:

                        test_write_read(chan_server[test.interface_index]);

#ifndef SCHEDULE_ON_COMPLETION
                            schedule_event();
#endif

                    break;
#endif
                    default:
                        for(;;);
                        break;
                }
                break;

                case chan_error :>  global_error_val :
                    show_error(i_led,i_button,global_error_val);
                    break;

        }
unsafe{
        for(;;)
        {
            I2C_MSI_EVENT * unsafe event = slave_event_buffer_pop();
            if (!event)
                break;

            switch(event->type)
            {
                case SLAVE_EVENT_RX:
                    switch(event->count)
                    {
                        case 1:
                        {
                            DEBUG_PUT_STATE(DEBUG_SLAVE_RX_COUNT1);
//                            if ( debug_error_count++==500 )
//                                show_error(i_led,0);

                            test.local_index = get_source_index(slave_rx.buffer[0]);

                            slave_tx_buffer_set(0,test.slave_tx_vals[test.local_index] >> 0);
                            slave_tx_buffer_set(1,test.slave_tx_vals[test.local_index] >> 8);
                            slave_tx_buffer_set(2,test.slave_tx_vals[test.local_index] >> 16);
                            slave_tx_buffer_set(3,test.slave_tx_vals[test.local_index] >> 24);

                            test.slave_tx_vals[test.local_index]++;

                            led_start(i_led,1);
                        }
                        break;

                        case 5:
                        {
                            unsigned int rxval;


                            DEBUG_PUT_STATE(DEBUG_SLAVE_RX_COUNT5);

                            test.local_index = get_source_index(slave_rx.buffer[0]);

                            rxval = event->buffer[1] << 0 | event->buffer[2] << 8 | event->buffer[3] << 16 | event->buffer[4] << 24;

                            if (rxval != test.slave_rx_vals[test.local_index])
                            {
                                show_error(i_led,i_button,0);
                                test.slave_rx_vals[test.local_index]= rxval;
                            }

                            test.slave_rx_vals[test.local_index]++;

                            led_start(i_led,1);
                        }
                         break;

                        default:
                        {
                            show_error(i_led,i_button,0);
                        }
                            break;
                    }
                    break;
            }

        }

     }

    }
}

void serve_master_event_buffer(int index,client startkit_led_if ?i_led,client startkit_button_if ?i_button)
{
    unsafe {
     for(;;)
     {
         I2C_MSI_EVENT * unsafe event = master_event_buffer_pop(index);
         if (!event)
             break;

#ifdef ERROR_AFTER_TX_COUNT
         if (!error_after_tx_count)
             show_error(i_led,0);
         else
             error_after_tx_count--;
#endif

         if (event->ack_state == I2C_NAK)
         {
#ifdef SCHEDULE_ON_COMPLETION
             schedule_event();
#endif
         } else
         switch(event->type)
         {
             case MASTER_EVENT_TX:
                 led_start(i_led,0);
#ifdef SCHEDULE_ON_COMPLETION
                 schedule_event();
#endif
                 break;

             case MASTER_EVENT_RX:
                 led_start(i_led,0);
                 if (event->user_id == READ_ID_TEST)
                  {
                      int rval = event->buffer[0] << 0 | event->buffer[1] << 8 | event->buffer[2] << 16 | event->buffer[3] << 24;
                      if (rval != test.master_rx_vals[test.target_index])
                      {
                          show_error(i_led,i_button,0);
                          test.master_rx_vals[test.target_index] = rval;
                       }
                      test.master_rx_vals[test.target_index]++;
                  }
#ifdef SCHEDULE_ON_COMPLETION
                 schedule_event();
#endif

                 break;
         }

     }

}
}

int ms_event(int);

void show_sda(void);


void background_task(int i2c_address_slave,chanend ?chan_error,chanend chan_i2c_client[NLINK],chanend chan_i2c_server[NLINK],unsigned NLINK)
{
    unsigned char tmp;

    i2c_msi_init(i2c_address_slave);

   for(;;)
   {

       if (i2c_msi_bus_free())
       {
           i2c_tx_queue_check(chan_error,chan_i2c_client,NLINK);

#pragma ordered
           select
           {

#ifdef USE_NOTIFICATIONS
               case i_i2c_msi_rx.notify_slave_event_clear() -> i2c_msi_event * unsafe return_val:
    //           DEBUG_PUT_STATE(DEBUG_10);
                       return_val = slave_event_buffer_pop();
                       break;
#endif

               case inct_byref (chan_i2c_server[int i], tmp ): // receive notification
                    break;

               case i2c_msi_start_select(chan_error,chan_i2c_client,NLINK);
            }
        } else
        {
#pragma ordered
            select
            {
               case i2c_msi_bus_select(chan_error,chan_i2c_client,NLINK);
            }
        }
   }

}


unsigned char get_source_index(unsigned char source)
{
    unsigned char i;
    for (i=0;i<MAX_SOURCES;i++)
    {
        if (!test.sources[i])
        {
            test.sources[i] = source;
            return i;
        }

        if (test.sources[i]==source)
            return i;
    }
    return 0;
}


int slave_rx_data = 0;
int test_write_read_index = 0;

//#define DOUBLE_TEST

void test_write(chanend ?chan_poke)
{

                i2c_msi_write_reg_word(test_targets[test.target_index],i2c_address.local>>1,test.master_tx_vals[test.target_index],test.interface_index);
                test.master_tx_vals[test.target_index]++;

#ifdef DOUBLE_TEST
                i2c_msi_write_reg_word(test_targets[test.target_index],i2c_address.local>>1,test.master_tx_vals[test.target_index],test.interface_index);
                test.master_tx_vals[test.target_index]++;
#endif
                outct (chan_poke, XS1_CT_END );

}
void test_write_read(chanend ?chan_poke)
{
                i2c_msi_write_reg_buffer(test_targets[test.target_index],i2c_address.local>>1,master_read_buffer,0,-1);
                i2c_msi_read_buffer(test_targets[test.target_index],master_read_buffer,4,test.interface_index,READ_ID_TEST);

#ifdef DOUBLE_TEST
                i2c_msi_write_reg_buffer(test_targets[test.target_index],i2c_address.local>>1,master_read_buffer,0,-1);
                i2c_msi_read_buffer(test_targets[test.target_index],master_read_buffer,4,test.interface_index,READ_ID_TEST);
#endif
                outct (chan_poke, XS1_CT_END );
}


void set_i2c_address(startkit_gpio_ports &ps)
{
    int p32_port_val;

    ps.p32 :> p32_port_val;

    if (p32_port_val & 0x80000000)
    {
        i2c_address.local = I2C_ADDRESS_B;
        i2c_address.remote = I2C_ADDRESS_A;
    }
    else
    {
        i2c_address.local = I2C_ADDRESS_A;
        i2c_address.remote = I2C_ADDRESS_B;
    }
    i2c_address.remote_8051 = I2C_ADDRESS_C;

//    i2c_address.local = 0x20;  // hardwire for now to work with 8051

    printhexln(i2c_address.local);
    printhexln(p32_port_val);
    printstrln("abc");
}

void add_target(int target)
{
    if (NUM_TARGETS == MAX_TARGETS)
        return;

    test_targets[NUM_TARGETS++] = target;
}


startkit_gpio_ports gpio_ports =
  {XS1_PORT_32A, XS1_PORT_4A, XS1_PORT_4B, XS1_CLKBLK_1};


int main(void)
{
    startkit_button_if i_button;
    startkit_led_if i_led;
//    interface i2c_msi_rx_if i_i2c_msi_rx;
//    interface i2c_msi_tx_if i_i2c_msi_tx[I2C_TX_INTERFACE_COUNT];

    chan chan_error;

    chan chan_i2c_client[I2C_TX_INTERFACE_COUNT];
    chan chan_i2c_server[I2C_TX_INTERFACE_COUNT];

#ifdef DO_NOTHING
    for(;;);
#endif

#if defined(XSCOPE)
            xscope_register(XSCOPE_REGISTER);
            xscope_config_io(XSCOPE_IO_BASIC);
#endif


    set_i2c_address(gpio_ports);

//    add_target(i2c_address.remote_8051);

    add_target(i2c_address.remote);
//    add_target(i2c_address.local);  // send to yourself
//    add_target(0x46);

//    add_target(i2c_address.local);
//    add_target(i2c_address.remote_8051);

//    timer_test();

    par {
         par {
            app_task(i_led,i_button,chan_error,chan_i2c_client,chan_i2c_server,I2C_TX_INTERFACE_COUNT);
            startkit_gpio_driver(i_led, i_button,null,null,gpio_ports);
        }

         background_task(i2c_address.local,chan_error,chan_i2c_client,chan_i2c_server,I2C_TX_INTERFACE_COUNT);
    }

    return 0;

}

void test_reset(void)
{
    int i;

    for (i=0;i<MAX_TARGETS;i++)
    {
        test.master_tx_vals[i] = 0;
        test.master_rx_vals[i] = 0;
        test.slave_tx_vals[i] = 0;
        test.slave_rx_vals[i] = 0;
    }
    for (i=0;i<MAX_SOURCES;i++)
        test.sources[i] = 0;


}

void signal_error(client startkit_button_if ?i_button)
{
#ifdef SIGNAL_ON_ERROR
    DEBUG_PORT_APP_LOW
    DEBUG_PORT_APP_LOW
    DEBUG_PORT_APP_RELEASE
    debug_put_sync();
    debug_put_sync();
    debug_put_sync();

#ifdef BREAK_ON_SIGNAL
    select {case i_button.changed():break;}
    stop_here();
#endif

#endif

}

void show_error(client startkit_led_if ?i_led,client startkit_button_if ?i_button,int error_num)
{
    signal_error(i_button);

    led_start(i_led,2);
}

void break_here()
{
    stop_here();
}
