/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id: crypttoken.h 1113 2007-01-10 09:14:16Z martin $
    begin       : Wed Mar 16 2005
    copyright   : (C) 2005 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPT_CRYPTDEFS_H
#define GWEN_CRYPT_CRYPTDEFS_H


#include <gwenhywfar/gwenhywfarapi.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef enum {
  GWEN_Crypt_PinType_Unknown=-1,
  GWEN_Crypt_PinType_None=0,
  GWEN_Crypt_PinType_Access,
  GWEN_Crypt_PinType_Manage
} GWEN_CRYPT_PINTYPE;

GWENHYWFAR_API GWEN_CRYPT_PINTYPE GWEN_Crypt_PinType_fromString(const char *s);
GWENHYWFAR_API const char *GWEN_Crypt_PinType_toString(GWEN_CRYPT_PINTYPE pt);



typedef enum {
  GWEN_Crypt_PinEncoding_Unknown=-1,
  GWEN_Crypt_PinEncoding_None=0,
  GWEN_Crypt_PinEncoding_Bin,
  GWEN_Crypt_PinEncoding_Bcd,
  GWEN_Crypt_PinEncoding_Ascii,
  GWEN_Crypt_PinEncoding_FPin2
} GWEN_CRYPT_PINENCODING;

GWENHYWFAR_API GWEN_CRYPT_PINENCODING GWEN_Crypt_PinEncoding_fromString(const char *s);
GWENHYWFAR_API const char *GWEN_Crypt_PinEncoding_toString(GWEN_CRYPT_PINENCODING pe);


GWENHYWFAR_API int GWEN_Crypt_TransformPin(GWEN_CRYPT_PINENCODING peSrc,
					   GWEN_CRYPT_PINENCODING peDst,
					   unsigned char *buffer,
					   unsigned int bufLength,
					   unsigned int *pinLength);

GWENHYWFAR_API int GWEN_Crypt_KeyDataFromText(const char *text,
					      unsigned char *buffer,
					      unsigned int bufLength);

GWENHYWFAR_API void GWEN_Crypt_Random(int quality, uint8_t *buffer, uint32_t len);


#ifdef __cplusplus
}
#endif


#endif

