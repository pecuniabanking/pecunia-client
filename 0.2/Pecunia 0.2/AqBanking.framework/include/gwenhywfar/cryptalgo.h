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


#ifndef GWEN_CRYPT_CRYPTALGO_H
#define GWEN_CRYPT_CRYPTALGO_H


#include <gwenhywfar/list2.h>

typedef struct GWEN_CRYPT_CRYPTALGO GWEN_CRYPT_CRYPTALGO;

#ifdef __cplusplus
extern "C" {
#endif

GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_CRYPT_CRYPTALGO,
			     GWEN_Crypt_CryptAlgo,
			     GWENHYWFAR_API)
#ifdef __cplusplus
}
#endif


typedef enum {
  GWEN_Crypt_CryptAlgoId_Unknown=-1,
  GWEN_Crypt_CryptAlgoId_None=0,
  GWEN_Crypt_CryptAlgoId_Any,
  /** RSA */
  GWEN_Crypt_CryptAlgoId_Rsa,
  /** DSA */
  GWEN_Crypt_CryptAlgoId_Dsa,
  /* DES */
  GWEN_Crypt_CryptAlgoId_Des,
  /** triple-key DES */
  GWEN_Crypt_CryptAlgoId_Des3K,
  /* blowfish */
  GWEN_Crypt_CryptAlgoId_BlowFish,
  /* AES-128 */
  GWEN_Crypt_CryptAlgoId_Aes128,
} GWEN_CRYPT_CRYPTALGOID;


typedef enum {
  GWEN_Crypt_CryptMode_Unknown=-1,
  GWEN_Crypt_CryptMode_None=0,
  GWEN_Crypt_CryptMode_Ecb, /* electronic codebook */
  GWEN_Crypt_CryptMode_Cfb, /* cipher feedback */
  GWEN_Crypt_CryptMode_Cbc  /* cipher block chaining */
} GWEN_CRYPT_CRYPTMODE;


#include <gwenhywfar/db.h>


#ifdef __cplusplus
extern "C" {
#endif

GWENHYWFAR_API GWEN_CRYPT_CRYPTALGOID GWEN_Crypt_CryptAlgoId_fromString(const char *s);
GWENHYWFAR_API const char *GWEN_Crypt_CryptAlgoId_toString(GWEN_CRYPT_CRYPTALGOID a);

GWENHYWFAR_API GWEN_CRYPT_CRYPTMODE GWEN_Crypt_CryptMode_fromString(const char *s);
GWENHYWFAR_API const char *GWEN_Crypt_CryptMode_toString(GWEN_CRYPT_CRYPTMODE m);


GWENHYWFAR_API GWEN_CRYPT_CRYPTALGO *GWEN_Crypt_CryptAlgo_new(GWEN_CRYPT_CRYPTALGOID id,
							      GWEN_CRYPT_CRYPTMODE m);
GWENHYWFAR_API GWEN_CRYPT_CRYPTALGO *GWEN_Crypt_CryptAlgo_dup(const GWEN_CRYPT_CRYPTALGO *a);
GWENHYWFAR_API GWEN_CRYPT_CRYPTALGO *GWEN_Crypt_CryptAlgo_fromDb(GWEN_DB_NODE *db);
GWENHYWFAR_API int GWEN_Crypt_CryptAlgo_toDb(const GWEN_CRYPT_CRYPTALGO *a, GWEN_DB_NODE *db);
GWENHYWFAR_API void GWEN_Crypt_CryptAlgo_Attach(GWEN_CRYPT_CRYPTALGO *a);
GWENHYWFAR_API void GWEN_Crypt_CryptAlgo_free(GWEN_CRYPT_CRYPTALGO *a);

GWENHYWFAR_API GWEN_CRYPT_CRYPTALGOID GWEN_Crypt_CryptAlgo_GetId(const GWEN_CRYPT_CRYPTALGO *a);
GWENHYWFAR_API GWEN_CRYPT_CRYPTMODE GWEN_Crypt_CryptAlgo_GetMode(const GWEN_CRYPT_CRYPTALGO *a);
GWENHYWFAR_API uint8_t *GWEN_Crypt_CryptAlgo_GetInitVectorPtr(const GWEN_CRYPT_CRYPTALGO *a);
GWENHYWFAR_API uint32_t GWEN_Crypt_CryptAlgo_GetInitVectorLen(const GWEN_CRYPT_CRYPTALGO *a);
GWENHYWFAR_API int GWEN_Crypt_CryptAlgo_SetInitVector(GWEN_CRYPT_CRYPTALGO *a,
						      const uint8_t *pv,
						      uint32_t lv);


GWENHYWFAR_API int GWEN_Crypt_CryptAlgo_GetChunkSize(const GWEN_CRYPT_CRYPTALGO *a);
GWENHYWFAR_API void GWEN_Crypt_CryptAlgo_SetChunkSize(GWEN_CRYPT_CRYPTALGO *a, int s);


GWENHYWFAR_API int GWEN_Crypt_CryptAlgo_GetKeySizeInBits(const GWEN_CRYPT_CRYPTALGO *a);
GWENHYWFAR_API void GWEN_Crypt_CryptAlgo_SetKeySizeInBits(GWEN_CRYPT_CRYPTALGO *a, int s);


#ifdef __cplusplus
}
#endif

#endif


