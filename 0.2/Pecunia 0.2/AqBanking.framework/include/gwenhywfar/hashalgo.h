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


#ifndef GWEN_CRYPT_HASHALGO_H
#define GWEN_CRYPT_HASHALGO_H


#include <gwenhywfar/list2.h>


typedef struct GWEN_CRYPT_HASHALGO GWEN_CRYPT_HASHALGO;


#ifdef __cplusplus
extern "C" {
#endif

GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_CRYPT_HASHALGO,
			     GWEN_Crypt_HashAlgo,
			     GWENHYWFAR_API)

#ifdef __cplusplus
}
#endif


typedef enum {
  GWEN_Crypt_HashAlgoId_Unknown=-1,
  GWEN_Crypt_HashAlgoId_None=0,
  GWEN_Crypt_HashAlgoId_Any,
  /** SHA-1 */
  GWEN_Crypt_HashAlgoId_Sha1,
  /** Ripemd 160 */
  GWEN_Crypt_HashAlgoId_Rmd160,
  /** MD-5 */
  GWEN_Crypt_HashAlgoId_Md5,
  GWEN_Crypt_HashAlgoId_Sha256,
} GWEN_CRYPT_HASHALGOID;


#include <gwenhywfar/db.h>


#ifdef __cplusplus
extern "C" {
#endif

GWENHYWFAR_API GWEN_CRYPT_HASHALGOID GWEN_Crypt_HashAlgoId_fromString(const char *s);
GWENHYWFAR_API const char *GWEN_Crypt_HashAlgoId_toString(GWEN_CRYPT_HASHALGOID a);


GWENHYWFAR_API GWEN_CRYPT_HASHALGO *GWEN_Crypt_HashAlgo_new(GWEN_CRYPT_HASHALGOID id);
GWENHYWFAR_API GWEN_CRYPT_HASHALGO *GWEN_Crypt_HashAlgo_dup(const GWEN_CRYPT_HASHALGO *a);
GWENHYWFAR_API GWEN_CRYPT_HASHALGO *GWEN_Crypt_HashAlgo_fromDb(GWEN_DB_NODE *db);
GWENHYWFAR_API int GWEN_Crypt_HashAlgo_toDb(const GWEN_CRYPT_HASHALGO *a, GWEN_DB_NODE *db);
GWENHYWFAR_API void GWEN_Crypt_HashAlgo_Attach(GWEN_CRYPT_HASHALGO *a);
GWENHYWFAR_API void GWEN_Crypt_HashAlgo_free(GWEN_CRYPT_HASHALGO *a);

GWENHYWFAR_API GWEN_CRYPT_HASHALGOID GWEN_Crypt_HashAlgo_GetId(const GWEN_CRYPT_HASHALGO *a);
GWENHYWFAR_API uint8_t *GWEN_Crypt_HashAlgo_GetInitVectorPtr(const GWEN_CRYPT_HASHALGO *a);
GWENHYWFAR_API uint32_t GWEN_Crypt_HashAlgo_GetInitVectorLen(const GWEN_CRYPT_HASHALGO *a);
GWENHYWFAR_API int GWEN_Crypt_HashAlgo_SetInitVector(GWEN_CRYPT_HASHALGO *a,
						     const uint8_t *pv,
						     uint32_t lv);

#ifdef __cplusplus
}
#endif


#endif

