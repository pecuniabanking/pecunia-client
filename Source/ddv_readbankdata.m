
/*  $Id: ddv_readbankdata.cpp,v 1.1 2011/05/04 22:37:59 willuhn Exp $

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

#include "ddvcard.h"
#include "seccos.h"
#include "tools.h"

bool DDV_readBankData(unsigned char idx,HBCI_BankData *entry)
{
    bool ret=false;
    
    // *** ungueltig fuer RSA-Karten
    unsigned char rawData[300];
    size_t        rawLen;
    
    if (SECCOS_readRecordBySFI(DDV_EF_BNK,idx,rawData,&rawLen)) {
        entry->recordnum=idx;
        
        strncpy((char*)entry->shortname,(const char*)rawData,20);
        trim(entry->shortname,20);
        strncpy((char*)entry->commaddr,(const char*)rawData+25,28);
        trim(entry->commaddr,28);
        strncpy((char*)entry->commaddradd,(const char*)rawData+53,2);
        trim(entry->commaddradd,2);
        strncpy((char*)entry->country,(const char*)rawData+55,3);
        trim(entry->country,3);
        strncpy((char*)entry->userid,(const char*)rawData+58,30);
        trim(entry->userid,30);

        for (int j=0;j<4;j++) {
            unsigned char ch=rawData[20+j];
            unsigned char nibble;
                
            nibble=(rawData[20+j]>>4)&0x0F;
            if (nibble>0x09) {
                nibble^=0x0F;
            }
            entry->blz[j<<1]=nibble+0x30;
                
            nibble=rawData[20+j]&0x0F;
            if (nibble>0x09) {
                nibble^=0x0F;
            }
            entry->blz[(j<<1)+1]=nibble+0x30;
        }
        entry->blz[8]=0x00;
        entry->commtype=rawData[24];

        ret=true;
    }
    
    return ret;
}
