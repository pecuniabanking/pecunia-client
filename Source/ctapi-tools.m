
/*  $Id: ctapi-tools.cpp,v 1.1 2011/05/04 22:37:44 willuhn Exp $

    This file is part of HBCI4Java
    Copyright (C) 2001-2007  Stefan Palme

    HBCI4Java is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    HBCI4Java is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <string.h>
#include <stdio.h>
#include "ctapi-tools.h"


const CTAPI_MapInt2String CTAPI_statusMsgs[]=
{
    {0x6200,"timeout"},
    {0x6201,"card already present"},
    {0x6281,"part of returned data may be corrupted"},
    {0x6282,"end of file reached before Le bytes read"},
    {0x6283,"selected file invalidated"},
    {0x6284,"FCI format incorrect"},
    {0x6381,"file filled up by last write"},
    {0x63C0,"use of internal retry routine (0)"},
    {0x63C1,"use of internal retry routine (1)"},
    {0x63C2,"use of internal retry routine (2)"},
    {0x63C3,"use of internal retry routine (3)"},
    {0x63C4,"use of internal retry routine (4)"},
    {0x63C5,"use of internal retry routine (5)"},
    {0x63C6,"use of internal retry routine (6)"},
    {0x63C7,"use of internal retry routine (7)"},
    {0x63C8,"use of internal retry routine (8)"},
    {0x63C9,"use of internal retry routine (9)"},
    {0x63CA,"use of internal retry routine (10)"},
    {0x63CB,"use of internal retry routine (11)"},
    {0x63CC,"use of internal retry routine (12)"},
    {0x63CD,"use of internal retry routine (13)"},
    {0x63CE,"use of internal retry routine (14)"},
    {0x63CF,"use of internal retry routine (15)"},
    {0x6400,"command not successful"},
    {0x6401,"aborted by cancel key"},
    {0x64A1,"no card present"},
    {0x64A2,"card not activated"},
    {0x6581,"memory failure"},
    {0x6700,"wrong length"},
    {0x6881,"logical channel not supported"},
    {0x6882,"secure messaging not supported"},
    {0x6883,"final command expected"},
    {0x6900,"command not allowed"},
    {0x6981,"command incompatible with file structure"},
    {0x6982,"security status not satisfied"},
    {0x6983,"authentication method blocked"},
    {0x6984,"referenced data invalidated"},
    {0x6985,"conditions of use not satisfied"},
    {0x6986,"command not allowed (no EF selected)"},
    {0x6987,"expected SM data objects missing"},
    {0x6988,"SM data objects inconsistent"},
    {0x6A00,"wrong parameters p1,p2"},
    {0x6A80,"incorrect parameters in data field"},
    {0x6A81,"function not supported"},
    {0x6A82,"file not found"},
    {0x6A83,"record not found"},
    {0x6A84,"not enough memory space"},
    {0x6A85,"Lc inconsistent with TLV structure"},
    {0x6A86,"incorrect parameters p1-p2"},
    {0x6A87,"Lc inconsistent with p1-p2"},
    {0x6A88,"referenced data not found"},
    {0x6B00,"wrong parameters (offset outside transparent EF)"},
    {0x6C00,"wrong length in Le"},
    {0x6D00,"wrong instruction"},
    {0x6E00,"class not supported"},
    {0x6F00,"communication with ICC not possible"},
    {0x9000,"success"},
    {0x9001,"success"},
    {0x0000,NULL},
};

const CTAPI_MapChar2String CTAPI_errorMsgs[]=
{
    {0,"success"},
    {-1,"invalid parameter or value"},
    {-8,"CT error"},
    {-10,"transmission error"},
    {-11,"memory error"},
    {-127,"aborted"},
    {-128,"HTSI error"},
    {0,NULL},
};

unsigned short int ctnum;

CTAPI_ERROR     CTAPI_error;

void CTAPI_log(const char *msg)
{
    CC_LOG(@"%s",msg);
}

unsigned short int extractStatus(unsigned short int len,unsigned char *response)
{
    return (((unsigned short int)response[len-2])<<8) + (((unsigned short int)response[len-1])&(unsigned char)0xFF);
}

char* CTAPI_getStatusString(unsigned short int status)
{
    CTAPI_MapInt2String *codes=(CTAPI_MapInt2String*)CTAPI_statusMsgs;
    
    while (codes->msg!=NULL) {
        if (codes->code==status) {
            char *ret=calloc(sizeof(char),strlen(codes->msg)+1);
            strcpy(ret,codes->msg);
            return ret;
        }
        codes++;
    }
    
    char* ret=calloc(sizeof(char),5);
    sprintf(ret,"%04X",status);
    return ret; 
}

char* CTAPI_getErrorString(char status)
{
    CTAPI_MapChar2String *codes=(CTAPI_MapChar2String*)CTAPI_errorMsgs;
    
    while (codes->msg!=NULL) {
        if (codes->code==status) {
            char *ret=calloc(sizeof(char),strlen(codes->msg)+1);
            strcpy(ret,codes->msg);
            return ret;
        }
        codes++;
    }
    
    char* ret=calloc(sizeof(char),5);
    sprintf(ret,"%i",status);
    return ret; 
}

bool CTAPI_isOK(unsigned short int status)
{
    return ((status&0xFF00)==0x9000) ||
           ((status&0xFF00)==0x6100);
}

#define MIN_LOCAL_RESPONSE_BUFFER_SIZE 4096
static unsigned short int perform(unsigned char _dad,const char *name,
             unsigned short int lenIn,unsigned char *command,
             unsigned short int *lenOut,unsigned char *response)
{
    unsigned char sad=CTAPI_SAD;
    unsigned char dad=_dad;
    
    char logmsg[1024];
    char temp[20];
    static unsigned char *response_local = NULL;
    static unsigned short int lenOut_local, lenOut_return;
     
    if (response_local==NULL) {
      lenOut_local = MIN_LOCAL_RESPONSE_BUFFER_SIZE;
        response_local = calloc(sizeof(char), lenOut_local);
      if (response_local==NULL) {
        CTAPI_log("Alloc of local response buffer failed. Out of memory. Aborting!");
        return 0;
      }
    }
    if (lenOut_local<(*lenOut)) {
      free( response_local );
      lenOut_local = *lenOut;
      response_local = calloc(sizeof(char), lenOut_local);
      if (response_local==NULL) {
        CTAPI_log("Realloc of local response buffer failed. Out of memory. Aborting!");
        return 0;
      }
    }
    lenOut_return = lenOut_local;  
      
    sprintf(logmsg,"%s apdu:",name);
    for (int i=0;i<lenIn;i++) {
        sprintf(temp," %02X",command[i]);
        strcat(logmsg,temp);
    }
    CTAPI_log(logmsg);
    
    memcpy(CTAPI_error.request,command,lenIn);
    CTAPI_error.reqLen=lenIn;

    char err;
    int  retries=3;
    while (retries--) { 
        err=CT_data(ctnum,&dad,&sad,lenIn,command,&lenOut_return,response_local);
        CTAPI_error.ret=err;
        
        if (!err)
            break;
        
        sprintf(logmsg,"%s: %i (%s)",name,err,CTAPI_getErrorString(err));
        CTAPI_log(logmsg);
    }

    if (lenOut_return < (*lenOut)) {
      *lenOut = lenOut_return;
    }
    memcpy(response,response_local, *lenOut);
    if (err!=0) {
        CTAPI_log("aborting");
        return 0;
    }
    
    sprintf(logmsg,"%s response:",name);
    for (int i=0;i<*lenOut;i++) {
        sprintf(temp," %02X",response[i]);
        strcat(logmsg,temp);
    }
    CTAPI_log(logmsg);
    
    memcpy(CTAPI_error.response,response,*lenOut);
    CTAPI_error.resLen=*lenOut;

    unsigned short int status=extractStatus(*lenOut,response);
    CTAPI_error.status=status;

    char *msg=CTAPI_getStatusString(status);
    sprintf(logmsg,"%s: %s",name,msg);
    CTAPI_log(logmsg);
    
    free(msg);
    return status;
}

unsigned short int CTAPI_performWithCT(const char *name,unsigned short int lenIn,unsigned char *command,unsigned short int *lenOut,unsigned char *response)
{
    return perform(CTAPI_DAD_CT,name,lenIn,command,lenOut,response);
}

unsigned short int CTAPI_performWithCard(const char *name,unsigned short int lenIn,unsigned char *command,unsigned short int *lenOut,unsigned char *response)
{
    return perform(CTAPI_DAD_CARD,name,lenIn,command,lenOut,response);
}

bool CTAPI_initCTAPI(unsigned short int portnum,unsigned short int _ctnum)
{
    ctnum=_ctnum;
    
    return CT_init(ctnum, portnum) == 0;
}

bool CTAPI_closeCTAPI()
{
    char logmsg[300];
    
    // closing CTAPI lib
    signed char err=CT_close(ctnum);
    if (err!=0) {
        sprintf(logmsg,"CT_close: %i (%s)",err,CTAPI_getErrorString(err));
        CTAPI_log(logmsg);
        return false;
    }
    
    CTAPI_log("closing CTAPI ok");
    return true;
}
