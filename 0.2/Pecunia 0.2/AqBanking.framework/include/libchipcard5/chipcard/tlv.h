/***************************************************************************
    begin       : Sun Jun 13 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CLIENT_TLV_H
#define CHIPCARD_CLIENT_TLV_H

#include <gwenhywfar/buffer.h>
#include <gwenhywfar/misc.h>
#include <chipcard/chipcard.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct LC_TLV LC_TLV;

GWEN_LIST_FUNCTION_LIB_DEFS(LC_TLV, LC_TLV, CHIPCARD_API)


CHIPCARD_API
LC_TLV *LC_TLV_new();
CHIPCARD_API
void LC_TLV_free(LC_TLV *tlv);

CHIPCARD_API
LC_TLV *LC_TLV_fromBuffer(GWEN_BUFFER *mbuf, int isBerTlv);

CHIPCARD_API
int LC_TLV_IsBerTlv(const LC_TLV *tlv);
CHIPCARD_API
unsigned int LC_TLV_GetTagType(const LC_TLV *tlv);
CHIPCARD_API
unsigned int LC_TLV_GetTagLength(const LC_TLV *tlv);
CHIPCARD_API
const void *LC_TLV_GetTagData(const LC_TLV *tlv);

CHIPCARD_API
int LC_TLV_IsContructed(const LC_TLV *tlv);
CHIPCARD_API
unsigned int LC_TLV_GetClass(const LC_TLV *tlv);
CHIPCARD_API
unsigned int LC_TLV_GetTagSize(const LC_TLV *tlv);


#ifdef __cplusplus
}
#endif


#endif /* CHIPCARD_CLIENT_TLV_H */

