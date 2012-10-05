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


#ifndef GWEN_CRYPT_TOKEN_KEYINFO_H
#define GWEN_CRYPT_TOKEN_KEYINFO_H


#include <gwenhywfar/list1.h>
#include <gwenhywfar/list2.h>



typedef struct GWEN_CRYPT_TOKEN_KEYINFO GWEN_CRYPT_TOKEN_KEYINFO;

#ifdef __cplusplus
extern "C" {
#endif

GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_CRYPT_TOKEN_KEYINFO, GWEN_Crypt_Token_KeyInfo, GWENHYWFAR_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_CRYPT_TOKEN_KEYINFO, GWEN_Crypt_Token_KeyInfo, GWENHYWFAR_API)

#ifdef __cplusplus
}
#endif



/** @name Key Status
 *
 */
/*@{*/
typedef enum {
  GWEN_Crypt_Token_KeyStatusUnknown=-1,
  GWEN_Crypt_Token_KeyStatusFree=0,
  GWEN_Crypt_Token_KeyStatusNew,
  GWEN_Crypt_Token_KeyStatusActive
} GWEN_CRYPT_TOKEN_KEYSTATUS;
/*@}*/



/** @name Key Flags
 *
 */
/*@{*/
#define GWEN_CRYPT_TOKEN_KEYFLAGS_HASSTATUS      0x00010000
#define GWEN_CRYPT_TOKEN_KEYFLAGS_HASMODULUS     0x00020000
#define GWEN_CRYPT_TOKEN_KEYFLAGS_HASEXPONENT    0x00040000
#define GWEN_CRYPT_TOKEN_KEYFLAGS_HASACTIONFLAGS 0x00080000
#define GWEN_CRYPT_TOKEN_KEYFLAGS_HASKEYVERSION  0x00100000
#define GWEN_CRYPT_TOKEN_KEYFLAGS_HASSIGNCOUNTER 0x00200000
#define GWEN_CRYPT_TOKEN_KEYFLAGS_HASKEYNUMBER   0x00400000

#define GWEN_CRYPT_TOKEN_KEYFLAGS_ACTIONMASK     0x0000000f
#define GWEN_CRYPT_TOKEN_KEYFLAGS_CANSIGN        0x00000001
#define GWEN_CRYPT_TOKEN_KEYFLAGS_CANVERIFY      0x00000002
#define GWEN_CRYPT_TOKEN_KEYFLAGS_CANENCIPHER    0x00000004
#define GWEN_CRYPT_TOKEN_KEYFLAGS_CANDECIPHER    0x00000008
/*@}*/



#include <gwenhywfar/cryptalgo.h>
#include <gwenhywfar/cryptalgo.h>


#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_Crypt_Token_KeyInfo_new(uint32_t kid,
						       GWEN_CRYPT_CRYPTALGOID a,
						       int keySize);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_free(GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_Crypt_Token_KeyInfo_dup(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
uint32_t GWEN_Crypt_Token_KeyInfo_GetKeyId(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
const char *GWEN_Crypt_Token_KeyInfo_GetKeyDescr(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SetKeyDescr(GWEN_CRYPT_TOKEN_KEYINFO *ki, const char *s);


GWENHYWFAR_API
GWEN_CRYPT_CRYPTALGOID GWEN_Crypt_Token_KeyInfo_GetCryptAlgoId(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
int GWEN_Crypt_Token_KeyInfo_GetKeySize(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SetKeySize(GWEN_CRYPT_TOKEN_KEYINFO *ki, int i);

GWENHYWFAR_API
uint32_t GWEN_Crypt_Token_KeyInfo_GetFlags(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SetFlags(GWEN_CRYPT_TOKEN_KEYINFO *ki, uint32_t f);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_AddFlags(GWEN_CRYPT_TOKEN_KEYINFO *ki, uint32_t f);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SubFlags(GWEN_CRYPT_TOKEN_KEYINFO *ki, uint32_t f);

GWENHYWFAR_API
const uint8_t *GWEN_Crypt_Token_KeyInfo_GetModulusData(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
uint32_t GWEN_Crypt_Token_KeyInfo_GetModulusLen(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SetModulus(GWEN_CRYPT_TOKEN_KEYINFO *ki,
					 const uint8_t *p,
					 uint32_t len);

GWENHYWFAR_API
const uint8_t *GWEN_Crypt_Token_KeyInfo_GetExponentData(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
uint32_t GWEN_Crypt_Token_KeyInfo_GetExponentLen(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SetExponent(GWEN_CRYPT_TOKEN_KEYINFO *ki,
					  const uint8_t *p,
					  uint32_t len);

GWENHYWFAR_API
uint32_t GWEN_Crypt_Token_KeyInfo_GetKeyNumber(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SetKeyNumber(GWEN_CRYPT_TOKEN_KEYINFO *ki,
					   uint32_t i);

GWENHYWFAR_API
uint32_t GWEN_Crypt_Token_KeyInfo_GetKeyVersion(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SetKeyVersion(GWEN_CRYPT_TOKEN_KEYINFO *ki,
					    uint32_t i);

GWENHYWFAR_API
uint32_t GWEN_Crypt_Token_KeyInfo_GetSignCounter(const GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
void GWEN_Crypt_Token_KeyInfo_SetSignCounter(GWEN_CRYPT_TOKEN_KEYINFO *ki,
					     uint32_t i);


#ifdef __cplusplus
}
#endif


#endif



