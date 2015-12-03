
/*  $Id: bcs.cpp,v 1.1 2011/05/04 22:37:44 willuhn Exp $

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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "atr.h"
#include "bcs.h"
#include "ctapi-tools.h"
#include "tools.h"

unsigned short int BCS_FUs=0;

bool BCS_resetCT()
{
    unsigned char command[]=
    {
        BCS_CLA,
        BCS_INS_RESET,
        BCS_FU_CT,
        0x00,
        0x00,
    };
    unsigned short int len=2;
    unsigned char      *response=calloc(sizeof(unsigned char),len);
    unsigned short int status=CTAPI_performWithCT("resetCT",4,command,&len,response);
    bool               ret=CTAPI_isOK(status);
    free(response);
    
    // request and store available FUs
    BCS_FUs=0;
    if (ret) {
        BCS_FUs=BCS_requestFunctionalUnits();
    }
    
    return ret;
}

bool BCS_resetCard()
{
    unsigned char command[]=
    {
        BCS_CLA,
        BCS_INS_RESET,
        BCS_FU_CARD,
        0x01,
        0x00
    };
    unsigned short int len=300;
    unsigned char      *response=calloc(sizeof(unsigned char),len);
    
    unsigned short int status=CTAPI_performWithCT("resetCard",5,command,&len,response);
    analyzeATR(response,len);
    
    free(response);
    return CTAPI_isOK(status);
}

bool BCS_requestCard(const char *msg,unsigned char timeout)
{
    unsigned char      *command=calloc(sizeof(unsigned char),300);
    unsigned short int cmdLen;
    
    command[0]=BCS_CLA;
    command[1]=BCS_INS_REQ_ICC;
    command[2]=BCS_FU_CARD;
    command[3]=0x01;
    
    if (msg==NULL || !(BCS_FUs & BCS_HAS_FU_DISPLAY)) {
        if (timeout==0) {
            cmdLen=4;
        } else {
            if (BCS_FUs & BCS_HAS_FU_DISPLAY) {
                command[4]=3;
                command[5]=0x80;
                command[6]=1;
                command[7]=timeout;
                cmdLen=8;
            } else {
                command[4]=1;
                command[5]=timeout;
                cmdLen=6;
            }
        }
    } else {
        int l=strlen(msg);
        
        if (timeout==0) {
            command[4]=2+l;
            command[5]=0x50;
            command[6]=l;
            strncpy((char*)command+7,msg,250);
            cmdLen=4+1+2+l;
        } else {
            command[4]=2+l+3;
            command[5]=0x50;
            command[6]=l;
            strncpy((char*)command+7,msg,250);
            command[4+1+2+l]=0x80;
            command[4+1+2+l+1]=1;
            command[4+1+2+l+2]=timeout;
            cmdLen=4+1+2+l+3;
        }
    }
    
    command[cmdLen++]=0x00;

    unsigned short int len=300;
    unsigned char      *response=calloc(sizeof(unsigned char),len);
    
    unsigned short int status=CTAPI_performWithCT("requestCard",cmdLen,command,&len,response);
    analyzeATR(response,len);
    
    free(command);
    free(response);
    return CTAPI_isOK(status);
}

char* BCS_requestCTManufacturer()
{
    unsigned char command[]=
    {
        BCS_CLA,
        BCS_INS_STATUS,
        BCS_FU_CT,
        0x46,
        0x00,
    };
    unsigned short int len=300;
    unsigned char      *response=calloc(sizeof(unsigned char),len);
    
    unsigned short int status=CTAPI_performWithCT("requestCTManufacturer",5,command,&len,response);
    
    char *ret=NULL;
    if (CTAPI_isOK(status)) {
        int offset=(response[0]==0x46)?2:0;
        ret=calloc(sizeof(char),300);
        
        sprintf(ret,"manufacturer:%s type:%s version:%s additional:%s",
                    substr(len-2,(const char*)response,offset,5),
                    substr(len-2,(const char*)response,offset+5,5),
                    substr(len-2,(const char*)response,offset+10,5),
                    substr(len-2,(const char*)response,offset+15,300));
    }
    
    free(response);
    return ret;
}

BCS_ICCStatus* BCS_requestICCStatus(size_t *number)
{
    unsigned char command[]=
    {
        BCS_CLA,
        BCS_INS_STATUS,
        BCS_FU_CT,
        0x80,
        0x00,
    };
    unsigned short int len=300;
    unsigned char      *response=calloc(sizeof(unsigned char),len);
    
    unsigned short int status=CTAPI_performWithCT("requestICCStatus",5,command,&len,response);
    
    BCS_ICCStatus *ret=NULL;
    if (CTAPI_isOK(status)) {
        int offset=(response[0]==0x80)?2:0;
        *number=len-offset-2;
        ret=calloc(sizeof(BCS_ICCStatus), *number);// new BCS_ICCStatus[*number];
        
        for (unsigned int i=0;i<*number;i++) {
            char item=response[offset+i];
            
            ret[i].cardpresent=(item&1)!=0;
            switch (item&0x06) {
                case 0x00: ret[i].connected=BCS_CONN_UNKNOWN; break;
                case 0x02: ret[i].connected=BCS_CONN_NO; break; 
                case 0x04: ret[i].connected=BCS_CONN_YES; break; 
            }
        }
    }
    
    free(response);
    return ret;
}

unsigned short int BCS_requestFunctionalUnits()
{
    unsigned char command[]=
    {
        BCS_CLA,
        BCS_INS_STATUS,
        BCS_FU_CT,
        0x81,
        0x00,
    };
    unsigned short int len=300;
    unsigned char      *response=calloc(sizeof(unsigned char),len);
    
    unsigned short int status=CTAPI_performWithCT("requestFunctionalUnits",5,command,&len,response);
    
    unsigned short int ret=0;
    if (CTAPI_isOK(status)) {
        int offset=(response[0]==0x81)?2:0;
        int size=len-offset-2;
        
        for (int i=0;i<size;i++) {
            switch (response[offset+i]) {
                case 0x01: ret|=BCS_HAS_FU_CARD; break;
                case 0x02: ret|=BCS_HAS_FU_CARD2; break;
                case 0x40: ret|=BCS_HAS_FU_DISPLAY; break;
                case 0x50: ret|=BCS_HAS_FU_KEYBD; break;
                case 0x60: ret|=BCS_HAS_FU_PRINTER; break;
                case 0x70: ret|=BCS_HAS_FU_BIO_FINGER; break;
                case 0x71: ret|=BCS_HAS_FU_BIO_VOICE; break;
                case 0x72: ret|=BCS_HAS_FU_BIO_DYN; break;
                case 0x73: ret|=BCS_HAS_FU_BIO_FACE; break;
                case 0x74: ret|=BCS_HAS_FU_BIO_IRIS; break;
            }
        }
    }
    
    free(response);
    return ret;
}

bool BCS_ejectCard(const char *msg,unsigned char timeout,bool keep,bool blink,bool beep)
{
    unsigned char      *command=calloc(sizeof(unsigned char),300);
    unsigned short int cmdLen;
    
    command[0]=BCS_CLA;
    command[1]=BCS_INS_EJECT;
    command[2]=BCS_FU_CARD;
    
    command[3]=0x00;
    if (keep)
        command[3]|=0x04;
    if (blink)
        command[3]|=0x02;
    if (beep)
        command[3]|=0x01;
    
    if (msg==NULL || !(BCS_FUs & BCS_HAS_FU_DISPLAY)) {
        if (timeout==0) {
            cmdLen=4;
        } else {
            if (BCS_FUs & BCS_HAS_FU_DISPLAY) {
                command[4]=3;
                command[5]=0x80;
                command[6]=1;
                command[7]=timeout;
                cmdLen=8;
            } else {
                command[4]=1;
                command[5]=timeout;
                cmdLen=6;
            }
        }
    } else {
        int l=strlen(msg);
        
        if (timeout==0) {
            command[4]=2+l;
            command[5]=0x50;
            command[6]=l;
            strncpy((char*)command+7,msg,250);
            cmdLen=4+1+2+l;
        } else {
            command[4]=2+l+3;
            command[5]=0x50;
            command[6]=l;
            strncpy((char*)command+7,msg,250);
            command[4+1+2+l]=0x80;
            command[4+1+2+l+1]=0x01;
            command[4+1+2+l+2]=timeout;
            cmdLen=4+1+2+l+3;
        }
    }

    unsigned short int len=2;
    unsigned char      *response=calloc(sizeof(unsigned char),len);
    
    unsigned short int status=CTAPI_performWithCT("ejectCard",cmdLen,command,&len,response);
    
    free(command);
    free(response);
    return CTAPI_isOK(status);
}

bool BCS_performVerification(const char *msg,unsigned char timeout,unsigned char pinlen,unsigned char pincoding,bool usebio,size_t cmdsize,unsigned char *verifycommand,unsigned char insertpos)
{
    unsigned char *command=calloc(sizeof(unsigned char),300);
    unsigned char writePos;
    
    command[0x00]=BCS_CLA;
    command[0x01]=BCS_INS_PERF_VERIF;
    command[0x02]=BCS_FU_CARD;
    command[0x03]=usebio?0x01:0x00;
    
    command[0x05]=0x52;
    command[0x06]=cmdsize+2;
    command[0x07]=(pinlen<<4)|pincoding;
    command[0x08]=insertpos;
    memcpy(command+0x09,verifycommand,cmdsize);
    
    writePos=0x09+cmdsize;
    if (msg!=NULL && (BCS_FUs & BCS_HAS_FU_DISPLAY)) {
        command[writePos++]=0x50;
        command[writePos++]=strlen(msg);
        memcpy(command+writePos,msg,strlen(msg));
        writePos+=strlen(msg);
    }
    
    /* TODO: this is disabled, because it does not work with all terminals
    if (timeout!=0) {
        command[writePos++]=0x80;
        command[writePos++]=1;
        command[writePos++]=timeout;
    }
    */
    
    command[0x04]=writePos-5;
    
    unsigned short int len=2;
    unsigned char *buffer = calloc(sizeof(unsigned char),len);
    
    unsigned short int status=CTAPI_performWithCT("performVerify",writePos,command,&len,buffer);
    
    free(command);
    return CTAPI_isOK(status);
}

bool BCS_modifyVerificationData(const char *msg,unsigned char timeout,unsigned char pinlen,unsigned char pincoding,bool usebio,size_t cmdsize,unsigned char *verifycommand,unsigned char insertposOld,unsigned char insertposNew)
{
    unsigned char *command=calloc(sizeof(unsigned char),300);
    unsigned char writePos;
    
    command[0x00]=BCS_CLA;
    command[0x01]=BCS_INS_MOD_VERIF_DATA;
    command[0x02]=BCS_FU_CARD;
    command[0x03]=usebio?0x01:0x00;
    
    command[0x05]=0x52;
    command[0x06]=cmdsize+3;
    command[0x07]=(pinlen<<4)|pincoding;
    command[0x08]=insertposOld;
    command[0x09]=insertposNew;
    memcpy(command+0x0A,verifycommand,cmdsize);
    
    writePos=0x0A+cmdsize;
    if (msg!=NULL && (BCS_FUs & BCS_HAS_FU_DISPLAY)) {
        command[writePos++]=0x50;
        command[writePos++]=strlen(msg);
        memcpy(command+writePos,msg,strlen(msg));
        writePos+=strlen(msg);
    }
    
    /* TODO: this is disabled, because it does not work with all terminals
    if (timeout!=0) {
        command[writePos++]=0x80;
        command[writePos++]=1;
        command[writePos++]=timeout;
    }
    */
    
    command[0x04]=writePos-5;
    
    unsigned short int len=2;
    unsigned char *buffer = calloc(sizeof(unsigned char),len);
    
    unsigned short int status=CTAPI_performWithCT("modifyVerificationData",writePos,command,&len,buffer);
    
    free(command);
    return CTAPI_isOK(status);
}
