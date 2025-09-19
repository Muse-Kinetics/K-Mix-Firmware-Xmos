#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <flashlib.h>

#define FILE_BUF_SIZE 4096
char file_buf[FILE_BUF_SIZE];

#define FLASH_DATA_FILE_NAME    "flashdata.bin"
#define FLASH_BOOT_FILE_NAME    "flashboot.bin"

//#define REBOOT_ONLY

//#define FORCE_ERROR
#define FORCE_ERASE

void reboot();

// Callback for supplying page data
unsigned int supplyData(void* userPtr,
                        unsigned int numBytes,
                        unsigned char* dstBuf)
{
  return( fread( dstBuf, 1, numBytes, (FILE*)userPtr ) );
}

// Flash connection function
extern int flash_connect();

void flash_erase() {
  fl_eraseAll();
}

int flash_cmd_enable_ports() __attribute__ ((weak));
int flash_cmd_enable_ports() {
  return 0;
}


// Factory image programming
#pragma stackfunction 2048
int flash_addFactoryImage(unsigned address,
                          unsigned imageSize,
                          unsigned (*getData)(void*,unsigned,unsigned char*),
                          void* userPtr)
{
  if (imageSize == 0)
    return 0;

  unsigned pageSize = fl_getPageSize();

  /* Write data. */
  unsigned char buf[256];
  int finalPage = 0;

  while (!finalPage) {
    unsigned pageBytes = pageSize;
    if (pageBytes >= imageSize) {
      pageBytes = imageSize;
      finalPage = 1;
    }
    unsigned pageRead = 0;

    /* Get a page of data. */
    do {
      unsigned read = (*getData)(userPtr, pageBytes - pageRead, &buf[pageRead]);
      if (read == 0)
        return 1;
      else if (read > (pageBytes - pageRead))
        return 1;
      pageRead += read;
    } while (pageBytes - pageRead);

    /* Write the page. */
//    printf("Writing page at [0x%x]\n", address);
    if (fl_writePage(address, buf) != 0)
      return 1;
    imageSize -= pageBytes;
    address += pageSize;
  }
  fl_endWriteImage();
  return 0;
}

#define CHUNK_LEN   256

void file_read_test(FILE* infile,unsigned int size)
{
    unsigned int chunk_len;
    unsigned char buffer[CHUNK_LEN];


    while (size)
    {
        if (size>CHUNK_LEN)
            chunk_len = CHUNK_LEN;
        else
            chunk_len = size;

        fread( buffer, 1, chunk_len, infile );

        size -= chunk_len;
    }
}

unsigned int prepare_file(FILE **inFile,char *filename)
{
    unsigned int imageSize;

    *inFile = fopen(filename, "rb");
    if(*inFile == NULL) {
      fprintf(stderr,"Error: Failed to open input data file.\n");
      exit(1);
    }
    setvbuf(*inFile, file_buf, _IOFBF, FILE_BUF_SIZE);

    if(0 != fseek(*inFile, 0, SEEK_END)) {
      fprintf(stderr,"Error: Failed to discover input data file size.\n");
      exit(1);
    }
    imageSize = (int)ftell(*inFile);
    if(0 != fseek(*inFile, 0, SEEK_SET)) {
      fprintf(stderr,"Error: Failed to input file pointer.\n");
      exit(1);
    }
    return imageSize;
}

#define PAGE_SIZE   256
int download_data()
{
    FILE *inFile;
    unsigned int imageSize;
    unsigned char fileBuf[PAGE_SIZE];
    unsigned char verify_buf[PAGE_SIZE];
    int i,blockNum = 0;

    imageSize = prepare_file(&inFile,FLASH_DATA_FILE_NAME);
    printf("flashdata image size is %d\n",imageSize);

    if (imageSize==0)
        return 0;

        while(imageSize)
        {
            unsigned int chunkSize;

            if (imageSize>PAGE_SIZE)
                chunkSize = PAGE_SIZE;
            else
                chunkSize = imageSize;

            fread(fileBuf, 1, chunkSize, inFile);

            if (fl_writeDataPage(blockNum,fileBuf))
            {
                printf("blockNum exceeds size\n");
                return 0;
            }

            fl_readDataPage(blockNum,verify_buf);

            for (i=0;i<chunkSize;i++)
            {
                if (fileBuf[i] != verify_buf[i])
                {
                    printf("%d",i);
                    return 0;
                }
            }

            if (!(blockNum % 100))
                printf("%d\n",blockNum);

            blockNum++;


            imageSize -= chunkSize;
        }

#ifdef FORCE_ERROR
        return 0;
#else
        return 1;
#endif

}


int main()
{
  FILE* inFile = NULL;
  int imageSize;
  unsigned int imageAddr = 0;

  unsigned char checkBuf[256];
  unsigned char fileBuf[256];
  unsigned int checkPos = 0;
  int gotError = 0;

#ifdef REBOOT_ONLY
  reboot();
#endif

  imageSize = prepare_file(&inFile,FLASH_BOOT_FILE_NAME);


//  file_read_test(inFile,imageSize);


//  if (0==flash_cmd_enable_ports()) {
  if( 0 == flash_connect() ) {
    fprintf(stderr,"Error: failed to recognise attached flash device.\n");
    fclose(inFile);
    exit(1);
  }

  fl_BootImageInfo bii;

#ifdef FORCE_ERASE
  printf("%s\n", "Erasing flash");
  flash_erase();

  fl_readPage(0, checkBuf);

  for(int i=0;i<256;i++)
      if (checkBuf[i]!=0xff)
      {
          fprintf(stderr,"Error: erase failed");
          fl_disconnect();
          exit(1);
      }

#else

  if(0 != fl_getFirstBootImage(&bii)) {
    printf("%s\n", "No factory image found, erase not required");
  } else {
    printf("%s\n", "Factory image found");
    printf("%s\n", "Erasing flash");
    flash_erase();
  }
#endif

  // Disable flash protection
  fl_setProtection(0);

  if(0 != flash_addFactoryImage( 0, imageSize, &supplyData, (void*)inFile)) {
    fprintf(stderr,"Error: failed to add new boot image.\n");
    fclose(inFile);
    fl_disconnect();
    exit(1);
  }

  printf("Factory boot image added.\n");

  // Verify programming step

  if(0 != fseek(inFile, 0, SEEK_SET)) {
    fprintf(stderr,"Error: Failed to input file pointer.\n");
    exit(1);
  }

  if(0 != fl_getFirstBootImage(&bii)) {
    fprintf(stderr,"Error: failed to locate factory boot image.\n");
    fclose(inFile);
    fl_disconnect();
    exit(1);
  }

  while(checkPos < imageSize) {
    int thisSize = ((imageSize-checkPos)>256) ? 256 : (imageSize-checkPos);
    fl_readPage(checkPos+imageAddr, checkBuf);
    fread(fileBuf, 1, 256, inFile);
    int i;
    for(i=0; i<thisSize; i++) {
      if(checkBuf[i] != fileBuf[i]) {
        printf("Error: verification mismatch at offset 0x%08x (file:0x%02x, flash:0x%02x).\n",checkPos+i,fileBuf[i],checkBuf[i]);
        gotError = 1;
        exit(1);
      }
    }
     if(gotError) {
      exit(1);
    }
//     else
//        printf("Good: at offset 0x%08x.\n",checkPos);

     checkPos += 256;

  }

  fclose(inFile);
  inFile = NULL;

  printf("boot verification complete.\n");

  if (!download_data())
  {
      printf("Error writing %s\n",FLASH_DATA_FILE_NAME);
      exit(1);
  }

  printf("Finished\n");

  fl_setProtection(1);
  fl_disconnect();

//  inFile = fopen("finished", "wb");
//  fclose(inFile);

//  reboot();

  exit(0);


}

