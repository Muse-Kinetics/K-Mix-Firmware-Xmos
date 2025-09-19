#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xscope_endpoint.h>

void xscope_print(unsigned long long timestamp,
                  unsigned int length,
                  unsigned char *data) {
  if (length) {
    printf("--> ");
    for (int i = 0; i < length; i++) {
      printf("%c", *(&data[i]));
    }
  }
}

int main (void) {
  char data[1024];

  xscope_ep_set_print_cb(xscope_print);
  xscope_ep_connect("localhost", "10234");

  printf("----- xSCOPE Console Demo -----\n");

  while(data[0] != 'q') {
    if (fgets(data, 1024, stdin)) {
      xscope_ep_request_upload(strlen(data)+1, (const unsigned char *)data);
    }
  }
  return 0;
}
