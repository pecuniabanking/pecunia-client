
/*  $Id: verify_pin.cpp,v 1.1 2011/05/04 22:37:44 willuhn Exp $

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

#include "ctapi-tools.h"
#include "bcs.h"
#include "seccos.h"

bool SECCOS_isPinInitialized(unsigned char pwdnum,unsigned char pwdtype)
{
    unsigned char *command=calloc(sizeof(unsigned char),5);
    
    command[0]=SECCOS_CLA_STD;
    command[1]=SECCOS_INS_VERIFY;
    command[2]=0x00;
    command[3]=pwdtype|pwdnum;
    command[4]=0x00;
    
    unsigned char      *response=calloc(sizeof(unsigned char),2);
    unsigned short int len=2;
    
    unsigned short int status=CTAPI_performWithCard("verify",5,command,&len,response);
    
    free(command);
    free(response);
    return (status==(unsigned short)0x6700);
}

bool SECCOS_verifyPin_1(unsigned char pwdnum,unsigned char pwdtype,unsigned char pincoding,size_t pinlen,unsigned char *pin)
{
    // calculate size of data structure to store pin
    size_t pinspace = 0;
    if (pincoding==SECCOS_PIN_CODING_BCD) {
        pinspace=pinlen>>1;
        if (pinlen&1) {
            pinspace++;
        }
    } else if (pincoding==SECCOS_PIN_CODING_T50) {
        pinspace=pinlen;
    } else if (pincoding==SECCOS_PIN_CODING_F2P) {
        pinspace=8;
    }
    
    // allocate command memory
    size_t        commandLen=5+pinspace;
    unsigned char *command=calloc(sizeof(unsigned char),commandLen);
    
    command[0]=SECCOS_CLA_STD;
    command[1]=SECCOS_INS_VERIFY;
    command[2]=0x00;
    command[3]=pwdtype|pwdnum;
    command[4]=pinspace;
    
    if (pincoding==SECCOS_PIN_CODING_BCD) {
        // bcd-encode given PIN
        
        for (unsigned int i=0;i<pinspace;i++) {
            command[5+i]=0xFF;
        }
        
        for (unsigned int i=0;i<pinlen;i++) {
            command[5+(i>>1)]&=(0x0F)<<(4*(i&1));
            command[5+(i>>1)]|=(pin[i]-0x30) << (4-(4*(i&1)));
        }
        
    } else if (pincoding==SECCOS_PIN_CODING_T50) {
        // just copy given PIN
        memcpy(command+5, pin, pinlen);
        
    } else if (pincoding==SECCOS_PIN_CODING_F2P) {
        // f2p-encode given PIN
        command[5]=0x25;
        command[6]=0xff;
        command[7]=0xff;
        command[8]=0xff;
        command[9]=0xff;
        command[10]=0xff;
        command[11]=0xff;
        command[12]=0xff;
        
        for (unsigned int i=0;i<pinlen;i++) {
            command[6+(i>>1)]&=(0x0F)<<(4*(i&1));
            command[6+(i>>1)]|=(pin[i]-0x30) << (4-(4*(i&1)));
        }
    }
    
    unsigned char      *response=calloc(sizeof(unsigned char),2);
    unsigned short int len=2;
    
    unsigned short int status=CTAPI_performWithCard("verify",commandLen,command,&len,response);
    
    free(command);
    free(response);
    return CTAPI_isOK(status);
}

bool SECCOS_verifyPin_2(const char *msg,unsigned char timeout,unsigned char pinlen,unsigned char pincoding,unsigned char pwdnum,unsigned char pwdtype,bool usebio)
{
    // calculate size of data structure to store pin
    size_t        pinspace = 0;
    unsigned char pincoding_bcs=pincoding;
    unsigned char insert_posi = 0;
    
    if (pincoding==SECCOS_PIN_CODING_BCD) {
        pinspace=pinlen>>1;
        if (pinlen&1) {
            pinspace++;
        }
        insert_posi=6;
        
    } else if (pincoding==SECCOS_PIN_CODING_T50) {
        pinspace=pinlen;
        insert_posi=6;
        
    } else if (pincoding==SECCOS_PIN_CODING_F2P) {
        pinspace=8;
        pincoding_bcs=SECCOS_PIN_CODING_BCD;
        insert_posi=7;
    }
    
    // allocate command memory
    size_t        commandLen=4+((pinspace==0)?0:(1+pinspace));
    unsigned char *command=calloc(sizeof(unsigned char),commandLen);
    
    command[0]=SECCOS_CLA_STD;
    command[1]=SECCOS_INS_VERIFY;
    command[2]=0x00;
    command[3]=pwdtype|pwdnum;
    
    if (pinspace!=0) {
        command[4]=pinspace;
        
        if (pincoding==SECCOS_PIN_CODING_BCD) {
            for (unsigned int i=0;i<pinspace;i++) {
                command[5+i]=0xFF;
            }
            
        } else if (pincoding==SECCOS_PIN_CODING_T50) {
            for (unsigned int i=0;i<pinspace;i++) {
                command[5+i]=0x20;
            }
            
        } else if (pincoding==SECCOS_PIN_CODING_F2P) {
            command[5]=0x25;
            command[6]=0xff;
            command[7]=0xff;
            command[8]=0xff;
            command[9]=0xff;
            command[10]=0xff;
            command[11]=0xff;
            command[12]=0xff;
        }
    }

    bool ret=BCS_performVerification(msg,timeout,pinlen,pincoding_bcs,usebio,commandLen,command,insert_posi);
    free(command);
    
    return ret;
}

