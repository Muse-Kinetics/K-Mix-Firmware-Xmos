#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <stdio.h>
#include <ctype.h>

typedef struct {uint32_t type,subtype,buildnum,flags,length;} HEADER;

HEADER header,headers[100];
int header_count = 0;

enum {TYPE_SHARC,TYPE_8051,TYPE_XMOS,TYPE_END = 0xff};

unsigned int process_file(unsigned char **image,char *filepath,int bitreverse_len);
int make_debug_bin(FILE *fd);
uint32_t swap_int(uint32_t val);

unsigned parse_hex_decimal(char *str)
{
    unsigned rval;
    
//    char *ptr = str;
    
//    while(*ptr) { *ptr = touppr(*ptr); ptr++; }
    
    if (strchr(str,'X') || strchr(str,'x'))
        sscanf(str,"%X",&rval);
    else
        sscanf(str,"%d",&rval);
        
    return rval;
}

int duplicate_check(HEADER header)
{
    int i;
    
    for (i=0;i<header_count;i++)
    {
        if (header.type == headers[i].type && header.subtype == headers[i].subtype)
            return 1;
    }
    
    headers[header_count++] = header;
    
    return 0;
}

#define PAGE_SIZE       256
#define PAGE_SIZE_MASK  (PAGE_SIZE-1)

void pad_out_image(FILE *fd)
{
    unsigned long count =  ftell (fd);
    
    count &= PAGE_SIZE_MASK;
    
    if (count)
    {
        while(count++ < PAGE_SIZE)
            fputc(0,fd);
    }
}



#define MAX_TEXT_LINE   1000
int main(int argc, const char * argv[]) {
    
    char line[MAX_TEXT_LINE];
    unsigned char *image = 0;
    
    uint32_t format = 0;
    
    system("pwd");
    
    FILE *fs = fopen("flashdata.txt","r");
    FILE *fd = fopen("flashdata.bin","wb");
    
    if (!fs)
    {
        printf("Could not open flashdata.txt\n");
        return 0;
    }
    
//    FILE *fdebug = fopen("flashdebug.bin","wb");
//    make_debug_bin(fdebug);
    
    fwrite(&format,1,sizeof(format),fd);

    
    
    while(fgets(line,MAX_TEXT_LINE,fs))
    {
        int count;
        char filepath[1000];
        
        
        
        if (strlen(line) && line[0] != '#')
            {
                count = sscanf(line,"%d %d %d %s",&header.type,&header.subtype,&header.buildnum,filepath);

                if (count >= 3)
                {
                    
                    char *pch = strtok (line," \t");
                    


                    header.type = parse_hex_decimal(pch);
                    pch = strtok (NULL, " \t");
                    header.subtype = parse_hex_decimal(pch);
                    pch = strtok (NULL, " \t");
                    header.buildnum = parse_hex_decimal(pch);
                    pch = strtok (NULL, " \t");
                    header.flags = parse_hex_decimal(pch);

                    
                    
                    switch(header.type)
                    {
                        case TYPE_8051:
                            pch = strtok (NULL, " \t");
                            sscanf(pch,"%s",filepath);
                            header.length = process_file(&image,filepath,0);
                            if (!header.length)
                                return -1;
                            break;
                        case TYPE_SHARC:
                            pch = strtok (NULL, " \t");
                            sscanf(pch,"%s",filepath);
                            header.length = process_file(&image,filepath,8);
                            if (!header.length)
                                return -1;
                            break;
                        case TYPE_XMOS:
                        default:
                            header.length = 0;
                            strcpy(filepath,"");
                            break;

                    }
                    
                    printf("%d %d 0x%x(%d) 0x%x %s %d\n",header.type,header.subtype,header.buildnum,header.buildnum,header.flags,filepath,header.length);
                    
                    if (duplicate_check(header))
                    {
                        printf("\nError: Duplicate type and subtype\n\n");
                        return -1;
                    }

                    
//                    if (header.length)
                    {
#if 0
                        header.type = swap_int(header.type);
                        header.subtype = swap_int(header.subtype);
                        header.buildnum = swap_int(header.buildnum);
                        header.length = swap_int(header.length)
                        fwrite(&header,1,sizeof(header),fd);
                        fwrite(image,1,swap_int(header.length),fd);
#else
                        fwrite(&header,1,sizeof(header),fd);
                        if (header.length)
                            fwrite(image,1,header.length,fd);
#endif
                    }
                }
            }
        
    }
    
    header.type = TYPE_END;header.subtype=0;header.length = 0;header.buildnum = 0;
    fwrite(&header,1,sizeof(header),fd);

    
    memset(&header,0,sizeof(header));
    
    fwrite(&header,1,sizeof(header),fd);
    
    pad_out_image(fd);
    
    fclose(fd);
    

    return 0;
}

uint32_t swap_int(uint32_t val)
{
    return ( (val & 0xff000000) >> 24) | ( (val & 0x00ff0000) >> 8 ) | ( (val & 0x0000ff00) << 8) | ( (val & 0x000000ff) << 24);
}


void bitreverse(unsigned char *image,unsigned int bitlength)
{
    int x;
    unsigned int b;
    unsigned char s[10],d[10];
    unsigned int bytestoreverse = bitlength/8;
    
    for (x=0;x<bytestoreverse;x++)
    {
        s[x] = image[x];
    }
    
    for (b=0;b < bitlength;b++){
        int last_carry = 0,carry;
        for (x=0;x<bytestoreverse;x++)
        {
            carry = s[x] & 0x80;
            s[x] <<= 1;
            
            if (last_carry)
                s[x] |= 1;
            
            last_carry = carry;
        }
        
        for (x=bytestoreverse-1;x>=0;x--)
        {
            carry = d[x] & 0x01;
            d[x] >>= 1;
            
            if (last_carry)
                d[x] |= 0x80;
            
            last_carry = carry;
        }
    }
    
    for (x=bytestoreverse-1;x>=0;x--)
    {
        image[bytestoreverse-x-1] = d[x];
    }
}


unsigned int process_file(unsigned char **image,char *filepath,int bitreverse_len)
{
    FILE *fs = fopen(filepath,"rb");
    unsigned int size,i;
    
    if (fs==NULL)
    {
        printf("Unable to open %s\n",filepath);
        return 0;
    }
    
    fseek(fs,0,SEEK_END);
    size = (uint32_t) ftell(fs);
    fseek(fs,0,SEEK_SET);
    
    if (*image)
        free(*image);
    
    *image = (unsigned char *) malloc(size);
    
    fread(*image,1,size,fs);
    
    if (bitreverse_len)
    for(i=0;i<size;i++)
    {
        bitreverse(*image + i,bitreverse_len);
    }
    
    

    return size;
}

int make_debug_bin(FILE *fd)
{
    uint32_t i,r;
    
    for (i=0;i<517;i++)
    {
        r = i;
        bitreverse((unsigned char *)&r,32);
        fwrite(&r,1,4,fd);
    }
    
    fclose(fd);
    return 0;
}
