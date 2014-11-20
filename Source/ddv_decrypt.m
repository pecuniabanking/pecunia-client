
/*  $Id: ddv_decrypt.cpp,v 1.1 2011/05/04 22:37:59 willuhn Exp $

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

#include "seccos.h"

bool DDV_decryptKey(unsigned char keynum,unsigned char *enckey,unsigned char *plainkey)
{
    for (int part=0;part<2;part++) {
        size_t dataLen;
        if (!SECCOS_internalAuthenticate(keynum,SECCOS_KEY_TYPE_DF,  
                                         8,enckey+(8*part),
                                         &dataLen,plainkey+(8*part))) {
            return false;
        }
    }
    
    return true;
}
