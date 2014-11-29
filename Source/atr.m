
/*  $Id: atr.cpp,v 1.1 2011/05/04 22:37:44 willuhn Exp $

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

#include <stdio.h>
#include <string.h>

#include "atr.h"
#include "ctapi-tools.h"

void analyzeATR(unsigned char *atr,size_t len)
{
    char          temp[1024];
    unsigned char ts=atr[0];
    unsigned char t0=atr[1];
    
    if (ts==0x3F)
        LogDebug(@"ATR: using inverse coding convention");
    else if (ts==0x3B)
        LogDebug(@"ATR: using direct coding convention");
    else
        LogWarning(@"ATR: unknown coding convention!");
    
    int           posi=1;
    unsigned char t=atr[posi];
    int           idx=1;
    
    while (t&0xF0) {
        if (t&0x10) {
            LogDebug(@"TA%i present",idx);
            posi++;
        }

        if (t&0x20) {
            LogDebug(@"TB%i present",idx);
            posi++;
        }

        if (t&0x40) {
            LogDebug(@"TC%i present",idx);
            posi++;
        }

        if (t&0x80) {
            LogDebug(@"TD%i present",idx);
            posi++;
            t=atr[posi];
        } else {
            t=0;
        }
        
        idx++;
    }
    
    unsigned char nof_hisBytes=t0&0x0F;
    sprintf(temp,"there are %i historical bytes: ",nof_hisBytes);
    
    for (int i=0;i<nof_hisBytes;i++) {
        unsigned char ch=atr[posi+1+i];
        sprintf(temp+strlen(temp),"%c",(ch<0x20)?'.':ch);
    }
    LogDebug(@"%s", temp);
}
