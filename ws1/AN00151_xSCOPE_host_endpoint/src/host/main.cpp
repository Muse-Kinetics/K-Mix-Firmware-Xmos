#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xscope_endpoint.h>
  
static volatile unsigned int running = 1;

void xscope_print(unsigned long long timestamp,
                  unsigned int length,
                  unsigned char *data) {
  if (length) {
    if (data[0] == 'q') {
      running = 0; 
      return;
   }

    for (int i = 0; i < length; i++) 
      printf("%c", *(&data[i]));

    printf("\n");
  }
}

void xscope_register(unsigned int id,
                     unsigned int type,
		     unsigned int r,
		     unsigned int g,
		     unsigned int b,
		     unsigned char *name,
		     unsigned char *unit,
		     unsigned int data_type,
		     unsigned char *data_name) {

   printf("xSCOPE register event (id [%d] name [%s])\n", 
          id, name);
}

void xscope_record(unsigned int id,
                   unsigned long long timestamp,
		   unsigned int length,
		   unsigned long long dataval,
		   unsigned char *databytes) {
   float mstimestamp = timestamp / 1000000000.0f;

   printf("xSCOPE record event (id [%d] timestamp [%.3f ms] value [%lld])\n", 
          id, mstimestamp, dataval);

}

int main (void) {
  xscope_ep_set_print_cb(xscope_print);
  xscope_ep_set_register_cb(xscope_register);
  xscope_ep_set_record_cb(xscope_record);
  xscope_ep_connect("localhost", "10234");

  printf("\n----- xSCOPE Endpoint Demo -----\n");

  while(running);

  return 0;
}
