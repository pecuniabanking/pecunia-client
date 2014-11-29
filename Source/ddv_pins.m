
/*  $Id: ddv_pins.cpp,v 1.1 2011/05/04 22:37:59 willuhn Exp $

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

#include "ctapi-tools.h"
#include "seccos.h"

bool DDV_verifyHBCIPin_1(bool usebio)
{
    bool ret=false;
    
    LogDebug(@"verifying PIN via ct-keypad");
    if (SECCOS_verifyPin_2(NULL,0,0,SECCOS_PIN_CODING_F2P,1,SECCOS_PWD_TYPE_DF,usebio)) {
        ret=true;
    }
    
    return ret;
}

bool DDV_verifyHBCIPin_2(unsigned char *pin)
{
    bool ret=false;
    
    LogDebug(@"verifying PIN via pc-keyboard");
    if (SECCOS_verifyPin_1(1,SECCOS_PWD_TYPE_DF,SECCOS_PIN_CODING_F2P,strlen((const char*)pin),pin)) {
        ret=true;
    }
    
    return ret;
}
