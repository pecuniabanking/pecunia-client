/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Sun Jun 13 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWENHYWFAR_TLV_H
#define GWENHYWFAR_TLV_H

#include <gwenhywfar/buffer.h>
#include <gwenhywfar/misc.h>


typedef struct GWEN_TLV GWEN_TLV;

GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_TLV, GWEN_TLV, GWENHYWFAR_API)


GWENHYWFAR_API
GWEN_TLV *GWEN_TLV_new();
GWENHYWFAR_API
void GWEN_TLV_free(GWEN_TLV *tlv);

GWENHYWFAR_API
GWEN_TLV *GWEN_TLV_create(unsigned int tagType,
                          unsigned int tagMode,
                          const void *p,
                          unsigned int dlen,
                          int isBerTlv);


GWENHYWFAR_API
GWEN_TLV *GWEN_TLV_fromBuffer(GWEN_BUFFER *mbuf, int isBerTlv);

GWENHYWFAR_API
int GWEN_TLV_toBuffer(GWEN_TLV *tlv, GWEN_BUFFER *mbuf);

GWENHYWFAR_API
int GWEN_TLV_DirectlyToBuffer(unsigned int tagType,
                              unsigned int tagMode,
                              const void *tagData,
                              int tagLength,
                              int isBerTlv,
                              GWEN_BUFFER *mbuf);


GWENHYWFAR_API
int GWEN_TLV_IsBerTlv(const GWEN_TLV *tlv);

GWENHYWFAR_API
unsigned int GWEN_TLV_GetTagType(const GWEN_TLV *tlv);
GWENHYWFAR_API
unsigned int GWEN_TLV_GetTagLength(const GWEN_TLV *tlv);
GWENHYWFAR_API
const void *GWEN_TLV_GetTagData(const GWEN_TLV *tlv);

GWENHYWFAR_API
int GWEN_TLV_IsContructed(const GWEN_TLV *tlv);
GWENHYWFAR_API
unsigned int GWEN_TLV_GetClass(const GWEN_TLV *tlv);
GWENHYWFAR_API
unsigned int GWEN_TLV_GetTagSize(const GWEN_TLV *tlv);




#endif /* GWENHYWFAR_TLV_H */

