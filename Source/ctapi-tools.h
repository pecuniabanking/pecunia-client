
/*  $Id: ctapi-tools.h,v 1.1 2011/05/04 22:37:54 willuhn Exp $

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

#ifndef _CTAPI_TOOLS_H
#define _CTAPI_TOOLS_H

#include <stdlib.h>

// sad and dad
#define CTAPI_SAD      ((unsigned char)0x02)
#define CTAPI_DAD_CT   ((unsigned char)0x01)
#define CTAPI_DAD_CARD ((unsigned char)0x00)

// CTAPI error codes
#define CTAPI_ERR_OK      ((char)0) 
#define CTAPI_ERR_INVALID ((char)-1) 
#define CTAPI_ERR_CT      ((char)-8) 
#define CTAPI_ERR_TRANS   ((char)-10) 
#define CTAPI_ERR_MEMORY  ((char)-11) 
#define CTAPI_ERR_HOST    ((char)-127) 
#define CTAPI_ERR_HTSI    ((char)-128) 

typedef struct CTAPI_ERROR {
    unsigned char      request[300];
    size_t             reqLen;
    unsigned char      response[300];
    size_t             resLen;
    char               ret;
    unsigned short int status;
} CTAPI_ERROR;

// error codes
typedef struct CTAPI_MapInt2String {
    unsigned short int code;
    const char*        msg;
} CTAPI_MapInt2String;

// error codes
typedef struct CTAPI_MapChar2String {
    char        code;
    const char* msg;
} CTAPI_MapChar2String;

extern const CTAPI_MapInt2String CTAPI_statusMsgs[];
extern const CTAPI_MapChar2String CTAPI_errorMsgs[];

bool               CTAPI_initCTAPI(unsigned short int portnum,unsigned short int ctnum);
unsigned short int CTAPI_performWithCT(const char *name,unsigned short int lenIn,unsigned char *command,unsigned short int *lenOut,unsigned char *response);
unsigned short int CTAPI_performWithCard(const char *name,unsigned short int lenIn,unsigned char *command,unsigned short int *lenOut,unsigned char *response);

char*              CTAPI_getErrorString(char status);
char*              CTAPI_getStatusString(unsigned short int status);
bool               CTAPI_isOK(unsigned short int status);

bool               CTAPI_closeCTAPI();

extern CTAPI_ERROR     CTAPI_error;

typedef unsigned char IU8;
typedef char IS8;
typedef unsigned short IU16;

extern IS8 CT_init(IU16 ctn, IU16 pn);
extern IS8 CT_data(IU16 ctn, IU8 *dad, IU8 *sad, IU16 lenc, IU8 *command, IU16 *lenr, IU8 *response);
extern IS8 CT_close(IU16 ctn);

#endif
