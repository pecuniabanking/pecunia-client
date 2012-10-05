/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id: tag16_l.h 790 2005-07-23 09:32:08Z aquamaniac $
    begin       : Sun Jun 13 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWENHYWFAR_OHBCI_TAG16_H
#define GWENHYWFAR_OHBCI_TAG16_H

#include <gwenhywfar/buffer.h>
#include <gwenhywfar/misc.h>


typedef struct GWEN_TAG16 GWEN_TAG16;

GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_TAG16, GWEN_Tag16, GWENHYWFAR_API)


GWENHYWFAR_API GWEN_TAG16 *GWEN_Tag16_new();
GWENHYWFAR_API void GWEN_Tag16_DirectlyToBuffer(unsigned int tagType,
						const char *p,
						int size,
						GWEN_BUFFER *buf);

GWENHYWFAR_API void GWEN_Tag16_free(GWEN_TAG16 *tlv);

GWENHYWFAR_API GWEN_TAG16 *GWEN_Tag16_fromBuffer(GWEN_BUFFER *mbuf, int isBerTlv);
GWENHYWFAR_API GWEN_TAG16 *GWEN_Tag16_fromBuffer2(const uint8_t *p, uint32_t l, int doCopy);

GWENHYWFAR_API unsigned int GWEN_Tag16_GetTagType(const GWEN_TAG16 *tlv);
GWENHYWFAR_API unsigned int GWEN_Tag16_GetTagLength(const GWEN_TAG16 *tlv);
GWENHYWFAR_API const void *GWEN_Tag16_GetTagData(const GWEN_TAG16 *tlv);

GWENHYWFAR_API unsigned int GWEN_Tag16_GetTagSize(const GWEN_TAG16 *tlv);




#endif /* GWENHYWFAR_OHBCI_TAG16_H */

