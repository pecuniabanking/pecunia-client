
/*  $Id: tools.cpp,v 1.1 2011/05/04 22:37:44 willuhn Exp $

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

char* bytes2hex(int size,unsigned char *bytes)
{
    char* ret=calloc(sizeof(char), 3*size+1);

    for (int i=0;i<size;i++) {
        sprintf(ret+(3*i),"%02X ",bytes[i]);
    }
    ret[(3*size)]=0;
    return ret;
}

char* substr(int size,const char *st,int offset,int num)
{
    char *ret=NULL;
    
    if (offset<size) {
        if (offset+num>size)
            num=size-offset;
        ret=calloc(sizeof(char), num+1);
        strncpy(ret,st+offset,num);
        ret[num]=0x00;
    }
    
    return ret;
}

unsigned char* trim(unsigned char *st,size_t maxsize)
{
    unsigned int i=0;
    while (i<maxsize && st[i]!=0x20) {
        i++;
    }
    st[i]=0x00;
    return st;
}
