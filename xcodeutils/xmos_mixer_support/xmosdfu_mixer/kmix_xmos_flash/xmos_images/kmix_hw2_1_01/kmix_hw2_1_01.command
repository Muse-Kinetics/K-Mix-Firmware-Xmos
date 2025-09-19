#!/bin/bash

#cause exit if any command fails
set -e

cd "$( dirname "${BASH_SOURCE[0]}")"
source /applications/XMOS_SetEnv13.sh

#get last part of shell script name into element
for element in ${BASH_SOURCE//\// } ; do
	STRNAME=$element
done

rm -f *.bin

#remove .command from name
xefile=`echo $STRNAME | cut -d . -f -1`


if [ ! -f "flashdata.bin" ]
then
    echo "flashdata.bin not found."
	../../support/flashdata flashdata.txt
fi

if [ ! -f "flashboot.bin" ]
then
    echo "flashboot.bin not found."
	xflash  --factory $xefile.xe --spi-spec ../../support/MICRON_N25Q128A.spispec --boot-partition-size 262144  -o flashboot.bin --verbose
fi

if [ ! -f "flashupgrade.bin" ]
then
    echo "flashupgrade.bin not found."
	xflash  --upgrade 1 $xefile.xe --spi-spec ../../support/MICRON_N25Q128A.spispec --boot-partition-size 262144  -o flashupgrade.bin --verbose --factory-version 13.2
fi


#xrun --verbose --io app_factory_image_programmer_Debug.xe
#xrun --verbose reboot.xe
xrun --io ../../support/app_factory_image_programmer.xe

echo $?


xrun ../../support/app_factory_reboot.xe






#create flashdata.bin from files listed in flashdata.txt
#../../support/flashdata flashdata.txt

#xflash --upgrade 1 $xefile.xe --factory-version 13.2 -o upgrade.bin
#xflash --factory $xefile.xe --boot-partition-size 262144 --factory-version 13.2 -o flashboot.bin
#xflash  --factory $xefile.xe --spi-spec ../../support/MICRON_N25Q128A.spispec --boot-partition-size 262144 --data flashdata.bin  -o flashbootdata.bin --verbose
#xflash  --factory $xefile.xe --spi-spec ../../support/MICRON_N25Q128A.spispec --boot-partition-size 262144  -o flashboot.bin --verbose


#run the following two command if using DFU
#../../support/xmosdfu --downloadboot upgrade.bin  --downloaddata flashdata.bin
#../../support/xmosdfu  --downloaddata flashdata.bin

#run the following command if using the jtag adapter
#xflash  --spi-spec ../../support/MICRON_N25Q128A.spispec --boot-partition-size 262144 --data flashdata.bin  --verbose $xefile.xe
#xflash  --spi-spec ../../support/MICRON_N25Q128A.spispec --boot-partition-size 262144  --verbose $xefile.xe



# got error:Error: F03115 --data may not be specified without also specifying an image.
#xflash --target KMI_MIXER --spi-spec ../../support/MICRON_N25Q128A.spispec --boot-partition-size 262144 --data flashdata.bin  --verbose

exit 0