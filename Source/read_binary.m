
/*  $Id: read_binary.cpp,v 1.1 2011/05/04 22:37:44 willuhn Exp $

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

bool SECCOS_readBinary_3(size_t *size,unsigned char *buffer,unsigned short offset,unsigned char maxsize)
{
    unsigned char command[]=
    {
        SECCOS_CLA_STD,
        SECCOS_INS_READ_BINARY,
        (offset>>8)&0xFF,
        (offset>>0)&0xFF,
        maxsize,
    };
    unsigned short int len=300;
    unsigned char      *response=calloc(sizeof(char), len);
    
    unsigned short int status=CTAPI_performWithCard("readBinary",5,command,&len,response);
    
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

bool SECCOS_readBinary_2(size_t *size,unsigned char *buffer,unsigned char maxsize)
{
    return SECCOS_readBinary_3(size,buffer,0,maxsize);
}

bool SECCOS_readBinary_1(size_t *size,unsigned char *buffer)
{
    return SECCOS_readBinary_3(size,buffer,0,0);
}
