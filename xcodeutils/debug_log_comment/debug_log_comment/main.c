
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <dirent.h>
#include <ctype.h>

;
typedef struct {char *out,*in;} maptype;
#define COLUMN2 "\t\t\t\t\t\t\t\t\t\t"

maptype map[] ={
    "DEBUG_LOST_ARB_MASTER","1000",
    "DEBUG_LOST_ARB_SLAVE","1001",
    "DEBUG_SLAVE_EVENT_RX","1002",
    "DEBUG_SLAVE_EVENT_TX","1003",
    "DEBUG_MASTER_EVENT_RX","1004",
    "DEBUG_MASTER_EVENT_TX","1005",
    "DEBUG_MASTER_WRITE_REG_WORD","1006",
    "DEBUG_MASTER_WRITE_REG_WORD_FULL","1007",
    "DEBUG_MASTER_EVENT_PUSH","1008",
    "DEBUG_SLAVE_EVENT_PUSH","1009",
    "DEBUG_ADVANCE_QUEUE_FRONT","1010",
    "DEBUG_STATE_TRANSITION","1011",
    "DEBUG_EVENT_SLAVE_WRONG_ADDRESS","1012",
    "DEBUG_EVENT_SDA_ERROR","1013",
    "DEBUG_QUEUE_TX","1014",
    COLUMN2"DEBUG_START_ASSERTED","1100",
    COLUMN2"DEBUG_START_DETECTED","1101",
    COLUMN2"DEBUG_STOP_DETECTED","1102",
    COLUMN2"DEBUG_ADVANCE_QUEUE_ERROR","1200",
    0,0
};

int isstringanumber(char *text)
{
    while(text && *text)
    {
        if (!isdigit(*text))
            return 0;
        text++;
    }
    
    return 1;
}


char *find_replacement_string(char *in)
{
    char *out;
    int index = 0;
    
    if (!in)
        return NULL;
    
    for(;;)
    {
        if (map[index].in)
        {
            if (!strcmp(in,map[index].in))
                return map[index].out;
        } else
                return 0;
        index++;
        
    }
    
    return out;
}

#define TEMP_NAME   "tempfile"

#define DELIMS  " \t\n=\"/<>"

int process_txt(const char *file_name)
{
    char dest_name[500];
    sprintf(dest_name,"%s.commented",file_name);
    
    FILE *fs = fopen(file_name,"r");
    FILE *fd = fopen(dest_name,"w");
    
    if (fs==NULL)
        return 0;
    
    for(;;)
    {
        char *pch,*last_token=NULL;
        char line1[500],line2[500];
        if (!fgets(line1,sizeof(line1)-1,fs))
            break;
        strcpy(line2,line1);
        
        char *pos;
        if ((pos=strchr(line2, '\n')) != NULL)
            *pos = '\0';
        
        last_token = NULL;
        pch = strtok (line1,DELIMS);
        while (pch != NULL)
        {
            last_token = pch;
            pch = strtok (NULL, DELIMS);
        }
        
        if (isstringanumber(last_token))
        {
            char *comment = find_replacement_string(last_token);
            
            fprintf(fd,"%s      ",line2);
        
            if (comment)
                fprintf(fd,"%s %s\n",last_token,comment);
            else
                fprintf(fd,"%s\n",last_token);
        }
        
        
    }
    
    fclose(fs);
    fclose(fd);
    
//    remove(file_name);
//    rename(TEMP_NAME,file_name);
    

    
    
    return 1;
}
char *extension(char *path)
{
    int k,period = -1;
    for (k=0;path[k];k++)
        if (path[k]=='.')
            period = k;
    
    if (period==-1)
        return NULL;
    else
        return &path[period+1];
}

void process_dir(void)
{
    DIR *dp;
    struct dirent *ep;
    dp = opendir (".");
    
    if (dp != NULL)
    {
        while ((ep = readdir (dp)))
        {
            char *ext = extension(ep->d_name);
            
            if (ext && (!strcmp(extension(ep->d_name),"txt") || !strcmp(extension(ep->d_name),"xmt")))
            {
                process_txt(ep->d_name);
                puts (ep->d_name);
            }
        }
        
        (void) closedir (dp);
    }
    else
        perror ("Couldn't open the directory");
    
}


int main(int argc, const char * argv[]) {
    process_dir();
    return 0;
}
