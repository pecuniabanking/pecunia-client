
/*  $Id: read_record.cpp,v 1.1 2011/05/04 22:37:44 willuhn Exp $

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
#include "seccos.h"

bool SECCOS_readRecordBySFI(unsigned short int sfi,unsigned char recordnum,unsigned char *buffer,size_t *size)
{
    unsigned char command[]=
    {
        SECCOS_CLA_STD,
        SECCOS_INS_READ_RECORD,
        recordnum,
        (sfi<<3)|0x04,
        0x00,
    };
    unsigned short int len=300;
    unsigned char      *response=calloc(sizeof(unsigned char), len);
    
    unsigned short int status=CTAPI_performWithCard("readRecord",5,command,&len,response);

    if (CTAPI_isOK(status)) {
        *size=len-2;
        memcpy(buffer,response,*size);
        free(response);
        return true;
    } else {
        free(response);
        return false;
    }
}

bool SECCOS_readRecord(unsigned char recordnum,unsigned char *buffer,size_t *size)
{
    return SECCOS_readRecordBySFI(0x00,recordnum,buffer,size);
}
