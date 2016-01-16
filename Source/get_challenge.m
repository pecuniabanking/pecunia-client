
/*  $Id: get_challenge.cpp,v 1.1 2011/05/04 22:37:44 willuhn Exp $

    This file is part of HBCI4Java
    Copyright (C) 2001-2007 Stefan Palme

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

bool SECCOS_getChallenge(size_t *len,unsigned char *challenge)
{
    unsigned char command[]={
        SECCOS_CLA_STD,
        SECCOS_INS_GET_CHALLENGE,
        0x00,
        0x00,
        *len,
    };
    
    unsigned char      *response=calloc(sizeof(unsigned char), *len+2);
    unsigned short int resLen=*len+2;
    unsigned short int status=CTAPI_performWithCard("getChallenge",5,command,&resLen,response);
    
    if (CTAPI_isOK(status)) {
        *len=resLen-2;
        memcpy(challenge,response,*len);
        
        free(response);
        return true;
    } else {
        free(response);
        return false;
    }
}
