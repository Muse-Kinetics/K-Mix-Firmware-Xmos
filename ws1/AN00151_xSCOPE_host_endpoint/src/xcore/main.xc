// Copyright (c) 2015, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <platform.h>
#include <xscope.h>
#include <print.h>

void output_xscope() {
  printstr("Starting xSCOPE probe output");
  delay_milliseconds(1);
  for (int i = 0; i < 25; i++) {
    xscope_int(VALUE, i);
    delay_milliseconds(1);
  }
  printstr("Finished xSCOPE probe output");
  // Send q to signal host application exit
  printstr("q");
}

int main (void) {
  par {
    on tile[0]: output_xscope();
  }

  return 0;
}
