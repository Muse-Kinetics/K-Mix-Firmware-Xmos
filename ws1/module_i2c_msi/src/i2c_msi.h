#ifndef I2C_MS_H_
#define I2C_MS_H_

#include "i2c_msi_config.h"
#include "i2c_msi_c.h"

//#define IGNORE_SPURIOUS_STARTS



enum {MASTER_EVENT_NONE,MASTER_EVENT_TX,MASTER_EVENT_RX};
enum {SLAVE_EVENT_NONE,SLAVE_EVENT_RX,SLAVE_EVENT_TX};
//#define I2C_SQUARE_WAVE


#define I2C_NOTIFY_COMPLETION_NO    0
#define I2C_NOTIFY_COMPLETION_YES   1

#define I2C_ACK 1
#define I2C_NAK 0



interface i2c_msi_rx_if {
#ifdef UNUSED
    void i2c_slave_rx_reg_word(int dest_reg,unsigned int data,int len);
    void i2c_slave_rx_buffer( unsigned char * unsafe buffer,int len);
    void i2c_slave_tx_buffer( unsigned char * unsafe buffer);
    void i2c_master_rx(int read_id);
#endif
    void address_rx(int address);
    void data_rx(int index,int data);
    void startstop();
    int data_tx(int index);
#ifdef USE_NOTIFICATIONS
    [[notification]] slave  void notify_slave_event(void);
    [[clears_notification]] i2c_msi_event * unsafe notify_slave_event_clear();
#endif
} ;

interface i2c_msi_tx_if {
    [[guarded]]
    int i2c_master_write_reg_buffer(int dest_address, int dest_reg,unsigned char * unsafe buffer, int len,int notify_flag);
    [[guarded]]
    int i2c_master_write_reg_word(int dest_address, int dest_reg,unsigned int data,int notify_flag);
    [[guarded]]
    int i2c_master_read_buffer(int dest_address,unsigned char *unsafe buffer,int len,int notifiy_flag,int read_id);
    void i2c_master_suspend_clear();
    [[notification]] slave  void notify_master_event(void);
    [[clears_notification]] I2C_MSI_EVENT * unsafe notify_master_event_clear();
};


//#define SERVER_SLAVE server interface i2c_msi_rx_if i_i2c_msi_rx[nrx],unsigned int nrx
//#define   SERVER_SLAVE_PASS i2c_msi_rx_if i_i2c_msi_rx,nrx

//#define SERVER_SLAVE server interface i2c_msi_rx_if i_i2c_msi_rx
//#define SERVER_SLAVE_PASS i_i2c_msi_rx

#define SERVER_SLAVE client interface i2c_msi_rx_if i_i2c_msi_rx
#define SERVER_SLAVE_PASS i_i2c_msi_rx


void i2c_msi_init(int i2c_address_slave);

select i2c_msi_bus_free_select(chanend ?chan_poke);
select i2c_msi_bus_active_select(chanend ?chan_poke);


int i2c_msi_write_reg_buffer(int dest_address, int dest_reg,unsigned char * unsafe buffer, int len,int interface_index);
int i2c_msi_write_reg_word(int dest_address, int dest_reg,unsigned int data,int interface_index);
int i2c_msi_read_buffer(int dest_address,unsigned char * unsafe buffer, int len,int interface_index,int read_id);
void i2c_tx_queue_check(chanend chan_poke_client[NTX],chanend chan_poke_server[NTX],unsigned int NTX);
void i2c_msi_suspend_clear();
I2C_MSI_EVENT * unsafe master_event_buffer_pop(int index);
I2C_MSI_EVENT * unsafe slave_event_buffer_pop(void);
void debug_put_sync();
void break_here();

#ifdef I2C_SQUARE_WAVE
void i2c_square_wave(int khz);
#endif

void show_error2(void);

int i2c_msi_bus_free();

select i2c_msi_start_select(chanend chan_poke_client[NTX],chanend chan_poke_server[NTX], unsigned int NTX);
select i2c_msi_bus_select(chanend chan_poke_client[NTX],unsigned int NTX);
//select i2c_msi_user_select(SERVER_SLAVE,server interface i2c_msi_tx_if i_i2c_tx[ntx],unsigned int ntx);


void i2c_msi_bit(int bit_state,chanend chan_poke_client[NTX],chanend chan_poke_server[NTX],unsigned int NTX);

#endif /* I2C_MS_H_ */

#ifdef UNUSED
[[notification]] slave void changed();

/** Get the current value of the button.
 *
 *  This returns either BUTTON_UP or BUTTON_DOWN.
 */
[[clears_notification]] button_val_t get_value();
#endif

#define I2C_USER \
case i_i2c_tx[int i].i2c_master_write_reg_buffer(int dest_address, int dest_reg,unsigned char * unsafe buffer, int len,int notify_flag) -> int return_val: \
    return_val = i2c_msi_write_reg_buffer(dest_address,dest_reg,buffer,len,notify_flag == I2C_NOTIFY_COMPLETION_YES ? i : -1);\
    break;\
case i_i2c_tx[int i].i2c_master_write_reg_word(int dest_address, int dest_reg,unsigned int data,int notify_flag) -> int return_val:\
    return_val = i2c_msi_write_reg_word(dest_address,dest_reg,data,notify_flag == I2C_NOTIFY_COMPLETION_YES ? i : -1);\
    break;\
case i_i2c_tx[int i].i2c_master_read_buffer(int dest_address,unsigned char *unsafe buffer,int len,int notify_flag,int read_id) -> int return_val:\
    return_val = i2c_msi_read_buffer(dest_address,buffer,len,notify_flag == I2C_NOTIFY_COMPLETION_YES ? i : -1,read_id);\
    break;\
case i_i2c_tx[int i].i2c_master_suspend_clear():\
        i2c_msi_suspend_clear();\
        break;\
case i_i2c_tx[int i].notify_master_event_clear() -> i2c_msi_event * unsafe return_val:\
        return_val = master_event_buffer_pop();\
        break;\
case i_i2c_msi_rx.notify_slave_event_clear() -> i2c_msi_event * unsafe return_val:\
        return_val = slave_event_buffer_pop();\
        break;

