// Copyright (c) 2015, XMOS Ltd, All rights reserved
#include <platform.h>
#include <xscope.h>
#include <print.h>

void process_xscope(chanend xscope_data_in) {
  int bytesRead = 0;
  unsigned char buffer[256];

  xscope_connect_data_from_host(xscope_data_in);

  while (1) {
    select {
      case xscope_data_from_host(xscope_data_in, buffer, bytesRead):
      if (bytesRead) {
        printstr(buffer);
        if (buffer[0] == 'q')
          return;
      }
      break;
    }
  }
}

int main (void) {
  chan xscope_data_in;

  par {
    xscope_host_data(xscope_data_in);
    on tile[0]: process_xscope(xscope_data_in);
  }

  return 0;
}
