
/*  $Id: bcs.h,v 1.1 2011/05/04 22:37:55 willuhn Exp $

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

#ifndef _BCS_H
#define _BCS_H

#include <stdlib.h>

// functional units
#define BCS_FU_CT         ((unsigned char)0x00)
#define BCS_FU_CARD       ((unsigned char)0x01)
#define BCS_FU_CARD2      ((unsigned char)0x02)
#define BCS_FU_DISPLAY    ((unsigned char)0x40)
#define BCS_FU_KEYBD      ((unsigned char)0x50)
#define BCS_FU_PRINTER    ((unsigned char)0x60)
#define BCS_FU_BIO_FINGER ((unsigned char)0x70)
#define BCS_FU_BIO_VOICE  ((unsigned char)0x71)
#define BCS_FU_BIO_DYN    ((unsigned char)0x72)
#define BCS_FU_BIO_FACE   ((unsigned char)0x73)
#define BCS_FU_BIO_IRIS   ((unsigned char)0x74) 

#define BCS_HAS_FU_CARD       ((unsigned short int)0x0001)
#define BCS_HAS_FU_CARD2      ((unsigned short int)0x0002)
#define BCS_HAS_FU_DISPLAY    ((unsigned short int)0x0004)
#define BCS_HAS_FU_KEYBD      ((unsigned short int)0x0008)
#define BCS_HAS_FU_PRINTER    ((unsigned short int)0x0010)
#define BCS_HAS_FU_BIO_FINGER ((unsigned short int)0x0020) 
#define BCS_HAS_FU_BIO_VOICE  ((unsigned short int)0x0040) 
#define BCS_HAS_FU_BIO_DYN    ((unsigned short int)0x0080) 
#define BCS_HAS_FU_BIO_FACE   ((unsigned short int)0x0100) 
#define BCS_HAS_FU_BIO_IRIS   ((unsigned short int)0x0200) 

// bcs-commands 
#define BCS_CLA                ((unsigned char)0x20)
#define BCS_INS_RESET          ((unsigned char)0x11)
#define BCS_INS_REQ_ICC        ((unsigned char)0x12)
#define BCS_INS_STATUS         ((unsigned char)0x13)
#define BCS_INS_EJECT          ((unsigned char)0x15)
#define BCS_INS_INPUT          ((unsigned char)0x16)
#define BCS_INS_OUTPUT         ((unsigned char)0x17)
#define BCS_INS_PERF_VERIF     ((unsigned char)0x18)
#define BCS_INS_MOD_VERIF_DATA ((unsigned char)0x19)

// eject stuff
#define BCS_EJECT_KEEP true
#define BCS_EJECT_THROW false 
#define BCS_EJECT_BLINK true
#define BCS_EJECT_DONT_BLINK false 
#define BCS_EJECT_BEEP true
#define BCS_EJECT_DONT_BEEP false 

// bio stuff
#define BCS_USE_BIO      (true)
#define BCS_DONT_USE_BIO (false)


typedef enum BCS_ConnStatus {
    BCS_CONN_UNKNOWN,
    BCS_CONN_YES,
    BCS_CONN_NO
} BCS_ConnStatus;


typedef struct BCS_ICCStatus {
    bool           cardpresent;
    BCS_ConnStatus connected; 
} BCS_ICCStatus;


bool               BCS_resetCT();
char*              BCS_requestCTManufacturer();
BCS_ICCStatus*     BCS_requestICCStatus(size_t *number);
unsigned short int BCS_requestFunctionalUnits();

bool               BCS_requestCard(const char *msg,unsigned char timeout);
bool               BCS_resetCard();
bool               BCS_ejectCard(const char *msg,unsigned char timeout,bool keep,bool blink,bool beep);

bool               BCS_performVerification(const char *msg,unsigned char timeout,unsigned char pinlen,unsigned char pincoding,bool usebio,size_t cmdsize,unsigned char *verifycommand,unsigned char insertpos);
bool               BCS_modifyVerificationData(const char *msg,unsigned char timeout,unsigned char pinlen,unsigned char pincoding,bool usebio,size_t cmdsize,unsigned char *verifycommand,unsigned char insertposOld,unsigned char insertposNew);

extern unsigned short int BCS_FUs;

#endif
