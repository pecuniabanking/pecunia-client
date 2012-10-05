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


#ifndef GWEN_CRYPT_PADDALGO_H
#define GWEN_CRYPT_PADDALGO_H


#include <gwenhywfar/list2.h>


typedef struct GWEN_CRYPT_PADDALGO GWEN_CRYPT_PADDALGO;

#ifdef __cplusplus
extern "C" {
#endif

GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_CRYPT_PADDALGO,
			     GWEN_Crypt_PaddAlgo,
			     GWENHYWFAR_API)

#ifdef __cplusplus
}
#endif


typedef enum {
  GWEN_Crypt_PaddAlgoId_Unknown=-1,
  GWEN_Crypt_PaddAlgoId_None=0,
  GWEN_Crypt_PaddAlgoId_Any,
  /** ISO 9796/1 without appendix 4 */
  GWEN_Crypt_PaddAlgoId_Iso9796_1,
  /** ISO 9796/1 with appendix 4 */
  GWEN_Crypt_PaddAlgoId_Iso9796_1A4,
  /** ISO 9796/2 with random (SigG v1.0) */
  GWEN_Crypt_PaddAlgoId_Iso9796_2,
  /** PKCS#1 block type 01 */
  GWEN_Crypt_PaddAlgoId_Pkcs1_1,
  /** PKCS#1 block type 02 */
  GWEN_Crypt_PaddAlgoId_Pkcs1_2,
  /** fill left with zeroes */
  GWEN_Crypt_PaddAlgoId_LeftZero,
  /** fill right with zeroes */
  GWEN_Crypt_PaddAlgoId_RightZero,
  /** ANSI X9.23 */
  GWEN_Crypt_PaddAlgoId_AnsiX9_23,
  /** PKCS#1 PSS with SHA-256 */
  GWEN_Crypt_PaddAlgoId_Pkcs1_Pss_Sha256
} GWEN_CRYPT_PADDALGOID;



#include <gwenhywfar/db.h>


#ifdef __cplusplus
extern "C" {
#endif

GWENHYWFAR_API GWEN_CRYPT_PADDALGOID GWEN_Crypt_PaddAlgoId_fromString(const char *s);
GWENHYWFAR_API const char *GWEN_Crypt_PaddAlgoId_toString(GWEN_CRYPT_PADDALGOID a);


GWENHYWFAR_API GWEN_CRYPT_PADDALGO *GWEN_Crypt_PaddAlgo_new(GWEN_CRYPT_PADDALGOID id);
GWENHYWFAR_API GWEN_CRYPT_PADDALGO *GWEN_Crypt_PaddAlgo_dup(const GWEN_CRYPT_PADDALGO *a);
GWENHYWFAR_API GWEN_CRYPT_PADDALGO *GWEN_Crypt_PaddAlgo_fromDb(GWEN_DB_NODE *db);
GWENHYWFAR_API int GWEN_Crypt_PaddAlgo_toDb(const GWEN_CRYPT_PADDALGO *a, GWEN_DB_NODE *db);
GWENHYWFAR_API void GWEN_Crypt_PaddAlgo_Attach(GWEN_CRYPT_PADDALGO *a);
GWENHYWFAR_API void GWEN_Crypt_PaddAlgo_free(GWEN_CRYPT_PADDALGO *a);

GWENHYWFAR_API GWEN_CRYPT_PADDALGOID GWEN_Crypt_PaddAlgo_GetId(const GWEN_CRYPT_PADDALGO *a);

GWENHYWFAR_API int GWEN_Crypt_PaddAlgo_GetPaddSize(const GWEN_CRYPT_PADDALGO *a);
GWENHYWFAR_API void GWEN_Crypt_PaddAlgo_SetPaddSize(GWEN_CRYPT_PADDALGO *a, int s);


#ifdef __cplusplus
}
#endif


#endif

