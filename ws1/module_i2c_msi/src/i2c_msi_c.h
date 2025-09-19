#include "i2c_msi_config.h"


#ifndef I2C_MSI_C_H_
#define I2C_MSI_C_H_


#define I2C_TX_RETRY_COUNT  1

typedef struct {
    int state;
    int slave_flag;
    int master_flag;
    int master_writer_flag;
    int slave_writer_flag;
    int suspend_flag;
    int read_flag;
    int active_flag;
    int bus_busy_flag;
    int data_bit_flag;
#ifdef __XC__
    unsigned char * unsafe master_ptr;
    unsigned char * unsafe slave_address;
#else
    unsigned char * master_ptr;
    unsigned char * slave_address;
#endif
    unsigned char data_rx;
    unsigned char data_tx;
    unsigned char data_tx_orig;
    int dest_reg;
    int master_tx_count;
    int slave_tx_count;
    int data_rx_count;
    int transfer_count;
    int slot_index;
    int tx_index;
    int bit_count;
    int bit_expect;
    int nak_count;
    int ack_state;
    int user_id;

 } I2CX;

 extern I2CX i2cx;

 typedef struct { int
     type,
     count,
     user_id,
     ack_state;
#ifdef __XC__
     char *unsafe buffer;
#else
     char * buffer;
#endif
     } I2C_MSI_EVENT;

#define MAX_MASTER_EVENTS   5
typedef struct { int index_in,index_out,count; I2C_MSI_EVENT events[MAX_MASTER_EVENTS]; } MASTER_EVENTS;
typedef struct { int index_in,index_out,count; I2C_MSI_EVENT events[MAX_MASTER_EVENTS]; } SLAVE_EVENTS;


extern MASTER_EVENTS master_events[];
extern SLAVE_EVENTS slave_events;

typedef struct  {int count; unsigned char buffer_rx[I2C_SLAVE_MAX_RX];unsigned char buffer_tx[I2C_SLAVE_MAX_TX];} SLAVE_RX_INFO_TYPE;
extern SLAVE_RX_INFO_TYPE slave_rx_info;






int i2c_enqueue_common(int dest_address,int dest_reg,int len,int interface_index,int user_id);

#ifdef __XC__
int i2c_enqueue_buffer(int dest_address,int dest_reg,unsigned char * unsafe buffer,int len,int interface_index,int read_id);
#else
int i2c_enqueue_buffer(int dest_address,int dest_reg,unsigned char *buffer,int len,int interface_index,int read_id);
#endif

int advance_queue();
void i2c_queue_set_data_address(int data);
void i2c_queue_init();
int i2c_queue_empty();
void copy_tx_queue_front();
void advance_queue_front();
int i2c_queue_front_interface_index();
void slave_tx_buffer_set(int index, unsigned char val);
void break_here();
void i2c_init_lock();
void i2c_acquire_lock();
void i2c_release_lock();





#endif /* I2C_MSI_C_H_ */
