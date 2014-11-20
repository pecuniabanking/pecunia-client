
/*  $Id: seccos.h,v 1.1 2011/05/04 22:37:55 willuhn Exp $

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

#ifndef _SECCOS_H
#define _SECCOS_H

#include <stdlib.h>

// seccos commands
#define SECCOS_CLA_STD           ((unsigned char)0x00)
#define SECCOS_CLA_SM_PROPR      ((unsigned char)0x04)
#define SECCOS_CLA_SM1           ((unsigned char)0x08)
#define SECCOS_CLA_EXT           ((unsigned char)0xB0)
#define SECCOS_INS_GET_CHALLENGE ((unsigned char)0x84)
#define SECCOS_INS_GET_KEYINFO   ((unsigned char)0xEE)
#define SECCOS_INS_INT_AUTH      ((unsigned char)0x88)
#define SECCOS_INS_PUT_DATA      ((unsigned char)0xDA)
#define SECCOS_INS_READ_BINARY   ((unsigned char)0xB0)
#define SECCOS_INS_READ_RECORD   ((unsigned char)0xB2)
#define SECCOS_INS_SELECT_FILE   ((unsigned char)0xA4)
#define SECCOS_INS_VERIFY        ((unsigned char)0x20)
#define SECCOS_INS_MODIFY        ((unsigned char)0x24)
#define SECCOS_INS_WRITE_RECORD  ((unsigned char)0xDC)

// SM stuff
#define SECCOS_SM_VALUE_LE   ((unsigned char)0x96)
#define SECCOS_SM_CRT_CC     ((unsigned char)0xB4)
#define SECCOS_SM_RESP_DESCR ((unsigned char)0xBA)

#define SECCOS_SM_REF_INIT_DATA ((unsigned char)0x87)

// select stuff
#define SECCOS_SELECT_RET_NOTHING ((unsigned char)0x0C)
#define SECCOS_SELECT_RET_FCP     ((unsigned char)0x04)
#define SECCOS_SELECT_RET_FCI     ((unsigned char)0x00)
#define SECCOS_SELECT_RET_FMD     ((unsigned char)0x08)

// file ids
#define SECCOS_EF_CURRENT ((unsigned short int)0x3FFF)
#define SECCOS_EF_MF      ((unsigned short int)0x3F00)
#define SECCOS_EF_DIR     ((unsigned short int)0x2F00)
#define SECCOS_EF_ATR     ((unsigned short int)0x2F01)
#define SECCOS_EF_GDO     ((unsigned short int)0x2F02)
#define SECCOS_EF_KEY     ((unsigned short int)0x0010)
#define SECCOS_EF_PWD     ((unsigned short int)0x0012)
#define SECCOS_EF_KEYD    ((unsigned short int)0x0013)
#define SECCOS_EF_PWDD    ((unsigned short int)0x0015)
#define SECCOS_EF_FBZ     ((unsigned short int)0x0016)
#define SECCOS_EF_ALIAS   ((unsigned short int)0x0018)
#define SECCOS_EF_CERT    ((unsigned short int)0x0019)
#define SECCOS_EF_RULE    ((unsigned short int)0x0030)
#define SECCOS_EF_DO      ((unsigned short int)0x0031)
#define SECCOS_EF_FCI     ((unsigned short int)0x0032)
#define SECCOS_EF_SE      ((unsigned short int)0x0033)
#define SECCOS_EF_RC      ((unsigned short int)0x0034)
#define SECCOS_EF_RCD     ((unsigned short int)0x0035)
#define SECCOS_EF_RCZ     ((unsigned short int)0x0036)

#define SECCOS_PWD_TYPE_GLOBAL ((unsigned char)0x00)
#define SECCOS_PWD_TYPE_DF     ((unsigned char)0x80)
#define SECCOS_KEY_TYPE_GLOBAL ((unsigned char)0x00)
#define SECCOS_KEY_TYPE_DF     ((unsigned char)0x80)

#define SECCOS_PIN_CODING_BCD ((unsigned char)0x00)
#define SECCOS_PIN_CODING_T50 ((unsigned char)0x01)
#define SECCOS_PIN_CODING_F2P ((unsigned char)0x02)
#define SECCOS_PIN_CODING_BIO ((unsigned char)0xFF)

// FCP
typedef struct SECCOS_FCP {
    unsigned short int reservedMem;
    unsigned char      fdsize;
    unsigned char      *fd;
    unsigned char      fileidsize;
    unsigned char      fileid[2];
    unsigned char      dfnamesize;
    unsigned char      *dfname;
    unsigned char      freemem;
    unsigned char      reservedMem2;
    unsigned char      sfi;
    // *** acls
} SECCOS_FCP;

bool SECCOS_readBinary_1(size_t *size,unsigned char *buffer);
bool SECCOS_readBinary_2(size_t *size,unsigned char *buffer,unsigned char maxsize);
bool SECCOS_readBinary_3(size_t *size,unsigned char *buffer,unsigned short offset,unsigned char maxsize);

void* SECCOS_selectRoot(unsigned char returntype);
void* SECCOS_selectSubFile(unsigned char returntype,unsigned short int fileid);
void* SECCOS_selectDF(unsigned char returntype,unsigned short int fileid);
void* SECCOS_selectFileByName(unsigned char returntype,unsigned char namesize,unsigned char *name);
void* SECCOS_selectFileByPath(unsigned char returntype,unsigned char pathsize,unsigned char *path);

bool SECCOS_readRecordBySFI(unsigned short int sfi,unsigned char recordnum,unsigned char *buffer,size_t *size);
bool SECCOS_readRecord(unsigned char recordnum,unsigned char *buffer,size_t *size);
bool SECCOS_writeRecordBySFI(unsigned short int sfi,unsigned char recordnum,unsigned char *buffer,size_t size);

bool SECCOS_putData(unsigned short int tag,unsigned char dataLen,unsigned char *data);

bool SECCOS_isPinInitialized(unsigned char pwdnum,unsigned char pwdtype);
bool SECCOS_verifyPin_1(unsigned char pwdnum,unsigned char pwdtype,unsigned char pincoding,size_t pinlen,unsigned char *pin);
bool SECCOS_verifyPin_2(const char *msg,unsigned char timeout,unsigned char pinlen,unsigned char pincoding,unsigned char pwdnum,unsigned char pwdtype,bool usebio);

bool SECCOS_modifyPin(unsigned char pwdnum,unsigned char pwdtype,size_t oldlen,unsigned char *oldpin,size_t newlen,unsigned char *newpin);

bool SECCOS_getKeyInfo(unsigned char keynum,unsigned char keytype,unsigned char *buffer,size_t *size);
bool SECCOS_getChallenge(size_t *len,unsigned char *challenge);
bool SECCOS_internalAuthenticate(unsigned char keynum,unsigned char keytype,
                                 size_t dataLen,unsigned char *data,
                                 size_t *encLen,unsigned char *enc);

#endif
