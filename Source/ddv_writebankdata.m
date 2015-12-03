
/*  $Id: ddv_writebankdata.cpp,v 1.1 2011/05/04 22:37:59 willuhn Exp $

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

#include "ddvcard.h"
#include "seccos.h"

void expand(unsigned char *orig,unsigned char *dest,size_t len)
{
    memcpy(dest,orig,strlen((char*)orig));
    for (unsigned int i=strlen((char*)orig);i<len;i++) {
        dest[i]=0x20;
    }
}

bool DDV_writeBankData(unsigned char recordnum,HBCI_BankData *data)
{
    bool ret=false;
    
    // *** ungueltig fuer RSA-Karten
    unsigned char *rawData=calloc(sizeof(unsigned char), 88);
    unsigned char st[300];
    
    expand(data->shortname,st,20); memcpy(rawData,st,20);
    expand(data->commaddr,st,28);  memcpy(rawData+25,st,28);
    expand(data->commaddradd,st,2); memcpy(rawData+53,st,2);
    expand(data->country,st,3); memcpy(rawData+55,st,3);
    expand(data->userid,st,30); memcpy(rawData+58,st,30);
    
    for (int i=0;i<4;i++) {
        unsigned char ch1=data->blz[i<<1]-0x30;
        unsigned char ch2=data->blz[(i<<1)+1]-0x30;
        
        if (ch1==2 && ch2==0) {
            ch1^=0x0F;
        }
        
        rawData[20+i]=(ch1<<4) | ch2;
    }
    rawData[24]=data->commtype;
    
    if (SECCOS_writeRecordBySFI(DDV_EF_BNK,recordnum,rawData,88)) {
        ret=true;
    }
    
    free(rawData);
    return ret;
}
