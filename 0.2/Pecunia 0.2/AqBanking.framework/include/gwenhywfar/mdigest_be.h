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


#ifndef GWENHYWFAR_MDIGEST_BE_H
#define GWENHYWFAR_MDIGEST_BE_H

#include <gwenhywfar/mdigest.h>
#include <gwenhywfar/inherit.h>


GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_MDIGEST, GWENHYWFAR_API)


typedef int (*GWEN_MDIGEST_BEGIN_FN)(GWEN_MDIGEST *md);
typedef int (*GWEN_MDIGEST_END_FN)(GWEN_MDIGEST *md);
typedef int (*GWEN_MDIGEST_UPDATE_FN)(GWEN_MDIGEST *md,
				      const uint8_t *buf,
				      unsigned int l);


GWENHYWFAR_API
GWEN_MDIGEST *GWEN_MDigest_new(GWEN_CRYPT_HASHALGOID a);


GWENHYWFAR_API
GWEN_MDIGEST_BEGIN_FN GWEN_MDigest_SetBeginFn(GWEN_MDIGEST *md, GWEN_MDIGEST_BEGIN_FN f);

GWENHYWFAR_API
GWEN_MDIGEST_END_FN GWEN_MDigest_SetEndFn(GWEN_MDIGEST *md, GWEN_MDIGEST_END_FN f);

GWENHYWFAR_API
GWEN_MDIGEST_UPDATE_FN GWEN_MDigest_SetUpdateFn(GWEN_MDIGEST *md, GWEN_MDIGEST_UPDATE_FN f);

/**
 * This function takes over the given buffer
 */
GWENHYWFAR_API
void GWEN_MDigest_SetDigestBuffer(GWEN_MDIGEST *md, uint8_t *buf, unsigned int l);

GWENHYWFAR_API
void GWEN_MDigest_SetDigestLen(GWEN_MDIGEST *md, unsigned int l);


#endif


