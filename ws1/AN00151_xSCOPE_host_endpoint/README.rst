xSCOPE - Custom Host Endpoint
=============================

.. appnote:: AN00151

.. version:: 1.0.1

Summary
-------

This application note shows how to create a simple example which
uses the XMOS xSCOPE application trace system to provide 
instrumentation logging to a custom application running on a host machine.

The code associated with this application note demonstrates a simple console
application running on a host PC which can communicate to the xCORE multicore
microcontroller via the xSCOPE system.

The xTIMEcomposer development tools provide an xSCOPE endpoint library which
can be used to interface a custom application into the xSCOPE server provided.
This allows communication to and from the xCORE processor via a simple API and
socket connection which can be enabled.

Example code for both the xCORE and host system is provided to enable an
end to end demonstration of this capability.

Required tools and libraries
............................

* xTIMEcomposer Tools - Version 13.2

Required hardware
.................

This application note is designed to run on any XMOS xCORE multicore microcontroller.

The example code provided with the application has been implemented and tested
on the XMOS startKIT but there is no dependancy on this board and it can be 
modified to run on any development board which has xSCOPE support available. 
It can also be run on the XMOS simulator if required.

Prerequisites
.............

  - This document assumes familiarity with the XMOS xCORE architecture,
    the XMOS tool chain and the xC language. Documentation related to these
    aspects which are not specific to this application note are linked to
    in the *References* appendix.

  - For descriptions of XMOS related terms found in this document please see
    the XMOS Glossary [#]_.

  - The XMOS tools manual contains information regarding the use of xSCOPE 
    and how to use it via code running on an xCORE processor [#]_.

  .. [#] http://www.xmos.com/published/glossary

  .. [#] http://www.xmos.com/published/xtimecomposer-user-guide
