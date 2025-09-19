#include "i2c_msi_c.h"
#include "hwlock.h"

typedef struct {
    int address_destination;
    int dest_reg;
    int tx_count;
#ifdef __XC__
    unsigned char * unsafe tx_address;
#else
    unsigned char *tx_address;
#endif
    unsigned int data;
    int interface_index;
    int nak_count;
    int user_id;
 } I2C_TX_ENTRY;

#define MAX_I2C_ENTRIES 20
typedef struct {int front,back;I2C_TX_ENTRY i2c_tx_entry[MAX_I2C_ENTRIES];} I2C_QUEUE;

I2C_QUEUE i2c_queue;

extern void stop_here(void);


void scl_release();

static hwlock_t lock_tx;


void i2c_init_lock()
{
    lock_tx = hwlock_alloc();
}

void i2c_acquire_lock()
{
//    hwlock_acquire(lock_tx);
}

void i2c_release_lock()
{
//    hwlock_release(lock_tx);
}



int i2c_next_queue = 0;

int i2c_enqueue_common(int dest_address,int dest_reg,int len,int interface_index,int user_id)
{
    i2c_next_queue = i2c_queue.back + 1;
    if (i2c_next_queue == MAX_I2C_ENTRIES)
        i2c_next_queue = 0;

    if (i2c_next_queue == i2c_queue.front)
        return 0;

    i2c_queue.i2c_tx_entry[i2c_queue.back].address_destination = dest_address;
    if (dest_address == 0x80)
        stop_here();
    i2c_queue.i2c_tx_entry[i2c_queue.back].dest_reg = dest_reg;
    i2c_queue.i2c_tx_entry[i2c_queue.back].tx_count = len;
    i2c_queue.i2c_tx_entry[i2c_queue.back].interface_index = interface_index;
    i2c_queue.i2c_tx_entry[i2c_queue.back].nak_count = I2C_TX_RETRY_COUNT;
    i2c_queue.i2c_tx_entry[i2c_queue.back].user_id = user_id;


    return 1;

}
int advance_queue()
{
    i2c_queue.back = i2c_next_queue;
    return i2c_next_queue;
}

int i2c_enqueue_buffer(int dest_address,int dest_reg,unsigned char *buffer,int len,int interface_index,int read_id)
{
    if (i2c_enqueue_common(dest_address,dest_reg,len,interface_index,read_id))
    {
        i2c_queue.i2c_tx_entry[i2c_queue.back].tx_address = buffer;
        advance_queue();
        return 1;
    }
//    for(;;);
    return 0;
}

void i2c_queue_set_data_address(int data)
{
    i2c_queue.i2c_tx_entry[i2c_queue.back].data = data;
    i2c_queue.i2c_tx_entry[i2c_queue.back].tx_address = (unsigned char *) &i2c_queue.i2c_tx_entry[i2c_queue.back].data;
}
void i2c_queue_init()
{

    i2c_queue.front = 0;
    i2c_queue.back = 0;
}
int i2c_queue_empty()
{
    return i2c_queue.back == i2c_queue.front;
}

int last_address_destination=0;
int last_front=0;



void copy_tx_queue_front()
{
    int cur_address = i2c_queue.i2c_tx_entry[i2c_queue.front].address_destination;

    if (cur_address & 1)
    {
        if ( (cur_address & ~1) != last_address_destination)
            break_here();
    }

    last_address_destination = i2c_queue.i2c_tx_entry[i2c_queue.front].address_destination ;
    last_front = i2c_queue.front;

    i2cx.data_tx = i2cx.data_tx_orig = i2c_queue.i2c_tx_entry[i2c_queue.front].address_destination;
    i2cx.dest_reg = i2c_queue.i2c_tx_entry[i2c_queue.front].dest_reg;
    i2cx.master_ptr = i2c_queue.i2c_tx_entry[i2c_queue.front].tx_address;
    i2cx.transfer_count = i2c_queue.i2c_tx_entry[i2c_queue.front].tx_count;
    i2cx.user_id = i2c_queue.i2c_tx_entry[i2c_queue.front].user_id;
}

void advance_queue_front()
{
            int next = i2c_queue.front + 1;
            if (next == MAX_I2C_ENTRIES)
                i2c_queue.front = 0;
            else
                i2c_queue.front = next;

}
int i2c_queue_front_interface_index()
{
    return i2c_queue.i2c_tx_entry[i2c_queue.front].interface_index;
}

I2C_MSI_EVENT *master_event_buffer_pop(int index)
{
    if (master_events[index].count)
    {
        I2C_MSI_EVENT * event = master_events[index].events + master_events[index].index_out++;


        if (master_events[index].index_out == MAX_MASTER_EVENTS)
            master_events[index].index_out = 0;

        master_events[index].count--;

        return event;

    } else
        return 0;

}

I2C_MSI_EVENT * slave_event_buffer_pop(void)
{
    if (slave_events.count)
    {
        I2C_MSI_EVENT * event = slave_events.events + slave_events.index_out++;


        if (slave_events.index_out == MAX_MASTER_EVENTS)
            slave_events.index_out = 0;

        slave_events.count--;

        return event;

    } else
        return 0;

}

void slave_tx_buffer_set(int index, unsigned char val)
{
    slave_rx_info.buffer_tx[index] = val;
}













