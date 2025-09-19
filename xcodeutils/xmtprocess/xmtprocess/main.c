#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <dirent.h>
#include <ctype.h>

;
typedef struct {char *out,*in;} maptype;
#define COLUMN2 "\t\t\t\t\t\t\t\t\t\t"

#define DEBUG_SYNC  0

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

#define TS_DIVISOR  ((long) 1E3)

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

typedef struct {int id,user_type,flag_event,flag_val; char name[100],user_units[100]; } map_entry;

typedef struct {int count; map_entry entry[50]; } XMT_MAP;


#define ENTRY_ALLOC_CHUNKS  50
typedef struct {unsigned int type,user; long time_stamp; } record_entry;
typedef struct {unsigned int count,chunk_limit,display_index;long time_stamp_reference,time_stamp_lowest,sync_offset; record_entry *entries; } XMT;

typedef struct { XMT_MAP map;XMT record;} XMT_FILE;

struct {int count; long time_stamp_low_adjust; XMT_FILE entry[5]; } files;

void stop_here()
{
    
}

void set_sync_index(XMT_FILE *xmt)
{
    int i;
    
    for (i=0; i < xmt->record.count;i++)
    {
        if (!i || xmt->record.entries[i].time_stamp < xmt->record.time_stamp_lowest)
            xmt->record.time_stamp_lowest = xmt->record.entries[i].time_stamp;
        
        if (xmt->record.entries[i].type == DEBUG_SYNC)
        {
            xmt->record.time_stamp_reference = xmt->record.entries[i].time_stamp;
            return;
        }
    }
    xmt->record.time_stamp_reference = -1;
}

void sync_files()
{
    int i;
    long highest=0,sync_adjusted;
    
    for (i=0;i<files.count;i++)
    {
        if (!i || files.entry[i].record.time_stamp_reference > highest)
            highest = files.entry[i].record.time_stamp_reference;
    }
    
    for (i=0;i<files.count;i++)
    {
        
        files.entry[i].record.sync_offset = highest - files.entry[i].record.time_stamp_reference;
        
        sync_adjusted = files.entry[i].record.time_stamp_lowest + files.entry[i].record.sync_offset;
        
        if (!i || sync_adjusted < files.time_stamp_low_adjust)
            files.time_stamp_low_adjust = sync_adjusted;
        
//        printf("%ld %ld %ld\n",files.entry[i].record.time_stamp_lowest/(long)1E11,files.entry[i].record.time_stamp_reference/(long)1E11,files.entry[i].record.sync_offset/(long)1E11);

        
    }
    
}


int process_xmt(const char *file_name,XMT_FILE *xmt)
{
    char dest_name[500];
    sprintf(dest_name,"%s.commented",file_name);
    
    FILE *fs = fopen(file_name,"r");
    FILE *fd = fopen(dest_name,"w");
    
    if (fs==NULL)
        return 0;
    
    
    xmt->map.count = 0;
    xmt->record.display_index = 0;
    
    xmt->record.entries= malloc(ENTRY_ALLOC_CHUNKS*sizeof(record_entry));
    xmt->record.count = 0;
    xmt->record.chunk_limit = ENTRY_ALLOC_CHUNKS;
    
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
        
        if (!strcmp("XtEventType",pch))
        {
            int index = 0;
            
            while(pch!=NULL)
            {
                switch(index)
                {
                    case 2:
                        sscanf(pch,"%d",&xmt->map.entry[xmt->map.count].id);
                        break;
                    case 6:
                        strcpy(xmt->map.entry[xmt->map.count].name,pch);
                        break;
                    case 10:
                        sscanf(pch,"%d",&xmt->map.entry[xmt->map.count].user_type);
                        break;
                    case 12:
                        strcpy(xmt->map.entry[xmt->map.count].user_units,pch);
                        if (strcasestr(pch,"e"))
                            xmt->map.entry[xmt->map.count].flag_event = 1;
                        else
                            xmt->map.entry[xmt->map.count].flag_event = 0;
                        if (strcasestr(pch,"v"))
                            xmt->map.entry[xmt->map.count].flag_val = 1;
                        else
                            xmt->map.entry[xmt->map.count].flag_val = 0;
                        
                        break;
                        
                }
                index++;
                pch = strtok(NULL,DELIMS);
            }
            xmt->map.count++;
            
        } else
        if (!strcmp("Record",pch))
        {
            int index = 0;
            
            if (xmt->record.count == xmt->record.chunk_limit)
            {
                xmt->record.chunk_limit += ENTRY_ALLOC_CHUNKS;
                record_entry *newentry = (record_entry *) realloc(xmt->record.entries,xmt->record.chunk_limit * sizeof(record_entry));
                if (!newentry)
                    return 0; // fatal error
                xmt->record.entries = newentry;
            }
            
            while(pch!=NULL)
            {
                switch(index)
                {
                    case 2:
                        sscanf(pch,"%d",&xmt->record.entries[xmt->record.count].type);
                        break;
                    case 6:
                        if (strlen(pch)<5)
                            xmt->record.entries[xmt->record.count].time_stamp = 0;
                        else {
                            pch[strlen(pch)-4] = 0;  // cut off the last 4 zero digits
                            sscanf(pch,"%ld",&xmt->record.entries[xmt->record.count].time_stamp);
                        }
                        break;
                    case 10:
                        sscanf(pch,"%d",&xmt->record.entries[xmt->record.count].user);
                        break;
                }
                index++;
                pch = strtok(NULL,DELIMS);
                
            }
            xmt->record.count++;
            
        }
        
        
        
        while (pch != NULL)
        {
            last_token = pch;
            pch = strtok (NULL, DELIMS);
        }
        
        
#ifdef UNUSED
        
        if (isstringanumber(last_token))
        {
            char *comment = find_replacement_string(last_token);
            
            fprintf(fd,"%s      ",line2);
            
            if (comment)
                fprintf(fd,"%s %s\n",last_token,comment);
            else
                fprintf(fd,"%s\n",last_token);
        }
#endif
        
        
    }
    
    set_sync_index(xmt);

    
    fclose(fs);
    fclose(fd);
    
    //    remove(file_name);
    //    rename(TEMP_NAME,file_name);
    
    
    
    
    return 1;
}

#define SP5 "     "
#define SP10 "          "
#define SP20 "                    "

#define DISPLAY_COLUMN_WIDTH 50

struct {int index; char line[DISPLAY_COLUMN_WIDTH*10];} display;

void display_files(char *output_name)
{
    FILE *fd = fopen(output_name,"w");
    
    for(;;)
    {
        long lowest_timestamp=0;
        int flag,index_lowest;
        
        flag = 0;
        
        // find lowest timestamp
        for (int i = 0; i < files.count; i++)
        {
            int display_index = files.entry[i].record.display_index;
            if (display_index == files.entry[i].record.count)
                continue;
            
            long adjusted_timestamp = files.entry[i].record.entries[display_index].time_stamp + files.entry[i].record.sync_offset - files.time_stamp_low_adjust;
            
            if (!flag || adjusted_timestamp < lowest_timestamp)
            {
                flag++;
                index_lowest = i;
                lowest_timestamp = adjusted_timestamp;
            }
        }
        
        if (!flag)
            break;
        
        if (flag==2)
            stop_here();

        display.index = 0;
        memset(display.line,' ',sizeof(display.line));
        
        for (int i = 0; i < files.count; i++)
        {
            int display_index = files.entry[i].record.display_index;
            display.index = i * DISPLAY_COLUMN_WIDTH;
            
            if (display_index == files.entry[i].record.count)
                continue;
            
            long adjusted_timestamp = files.entry[i].record.entries[display_index].time_stamp + files.entry[i].record.sync_offset - files.time_stamp_low_adjust;
            
            if (adjusted_timestamp == lowest_timestamp)
            {
                int type = files.entry[i].record.entries[files.entry[i].record.display_index].type;
                char *name = files.entry[i].map.entry[type].name;
                int val = files.entry[i].record.entries[files.entry[i].record.display_index].user;
                

                if (files.entry[i].map.entry[type].flag_val)
                    sprintf(display.line+display.index,"%30s%15d"SP5,name,val);
                else
                    sprintf(display.line+display.index,"%30s"SP20,name);
                
                
                files.entry[i].record.display_index++;
            }
        }
        
        fprintf(fd,"%20ld: %s\n",lowest_timestamp/TS_DIVISOR,display.line);

        
    }
    fclose(fd);
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
    
    files.count = 0;
    
    if (dp != NULL)
    {
        while ((ep = readdir (dp)))
        {
            char *ext = extension(ep->d_name);
            
            if (ext && !strcmp(extension(ep->d_name),"xmt"))
            {
                process_xmt(ep->d_name,&files.entry[0]);
                puts (ep->d_name);
            }
        }
        
        (void) closedir (dp);
        
        sync_files();
    }
    else
    {
        perror ("Couldn't open the directory");
    }
    
}


int main(int argc, const char * argv[]) {
    if (argc<2)
    {
        printf("usage: %s xmtfiles",argv[0]);
        exit(0);
               
    }
    
    for (int i=1;i<argc;i++)
    {
        process_xmt(argv[i],&files.entry[files.count]);
        files.count++;
        
    }
    
    sync_files();
    display_files("commented_xmp.txt");
    
    return 0;
}
