/***************************************************************************
    begin       : Sun Nov 30 2008
    copyright   : (C) 2008 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPTMGR_SIGTAIL_H
#define GWEN_CRYPTMGR_SIGTAIL_H

#include <gwenhywfar/gwentime.h>
#include <gwenhywfar/buffer.h>
#include <gwenhywfar/list1.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef struct GWEN_SIGTAIL GWEN_SIGTAIL;
GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_SIGTAIL, GWEN_SigTail, GWENHYWFAR_API)


GWEN_SIGTAIL *GWEN_SigTail_new();
void GWEN_SigTail_free(GWEN_SIGTAIL *st);

GWEN_SIGTAIL *GWEN_SigTail_fromBuffer(const uint8_t *p, uint32_t l);
int GWEN_SigTail_toBuffer(const GWEN_SIGTAIL *st, GWEN_BUFFER *buf, uint8_t tagType);

const uint8_t *GWEN_SigTail_GetSignaturePtr(const GWEN_SIGTAIL *st);
uint32_t GWEN_SigTail_GetSignatureLen(const GWEN_SIGTAIL *st);
void GWEN_SigTail_SetSignature(GWEN_SIGTAIL *st, const uint8_t *p, uint32_t l);


int GWEN_SigTail_GetSignatureNumber(const GWEN_SIGTAIL *st);
void GWEN_SigTail_SetSignatureNumber(GWEN_SIGTAIL *st, int i);


#ifdef __cplusplus
}
#endif


#endif

