/***************************************************************************
    begin       : Mon Dec 01 2008
    copyright   : (C) 2008 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPTMGR_CRYPTMGR_H
#define GWEN_CRYPTMGR_CRYPTMGR_H


#include <gwenhywfar/buffer.h>

/**
 * @defgroup MOD_CRYPT_CRYPTMGR Cryptographic Object Manager
 * @ingroup MOD_CRYPT
 * @brief Framework for Signing, Verifying, Encrypting and Decrypting of data objects
 *
 * This group contains functions which operate on cryptographic objects.
 * These objects are signed objects and encrypted objects. Data can be wrapped
 * in those objects for secure transmission.
 *
 * Keys used by this group are identified by a name, number and version.
 * There is a local key (used for signing and decryption) and a peer key (used
 * for signature verification and encryption).
 *
 * This module handles the adminstration of signed objects and encrypted objects.
 * The cryptographic functions are performed using callbacks. Therefore you can't
 * instantiate an object of this group directly. You must call the constructor of
 * one of the implementations (like @ref GWEN_CryptMgrKeys_new).
 *
 * Signed objects and encrypted objects consist of modified TLV (Tag, Length, Value)
 * objects with the following structure:
 * <table>
 *   <tr><th>Position</th><th>Length</th><th>Description</th></tr>
 *   <tr><td>0</td><td>1</td><td>Type</td></tr>
 *   <tr><td>1</td><td>2</td><td>Length of the following value (or 0)</td></tr>
 *   <tr><td>2</td><td>n</td><td>Value</td></tr>
 * </table>
 *
 * A signed object is such a TLV object consisting of:
 * <ul>
 *   <li>signature head (name, number and version of the key used, datetime etc)</li>
 *   <li>signed data</li>
 *   <li>signature tail containing the actual signature</li>
 * </ul>
 *
 * Encrypted objects are another kind of TLVs containing:
 * <ul>
 *   <li>crypt head (name, number and version of the key used, message key etc)</li>
 *   <li>encrypted data</li>
 * </ul>
 *
 */
/*@{*/

#define GWEN_CRYPTMGR_TLV_SIGNEDOBJECT      0x21
#define GWEN_CRYPTMGR_TLV_ENCRYPTEDOBJECT   0x22


typedef struct GWEN_CRYPTMGR GWEN_CRYPTMGR;


typedef enum {
  GWEN_CryptProfile_None=0,
  /**
   * Padding for key    : ISO 9796-2
   * Encryption for key : RSA 2048
   * Padding for data   : ANSIX9_23
   * Encryption for data: BLOWFISH-256
   */
  GWEN_CryptProfile_1=1
} GWEN_CRYPT_PROFILE;


typedef enum {
  GWEN_SignatureProfile_None=0,
  /**
   * Hash: RMD-160
   * Padd: ISO 9796-2
   * Sign: RSA 2048
   */
  GWEN_SignatureProfile_1=1
} GWEN_SIGNATURE_PROFILE;


#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API
void GWEN_CryptMgr_free(GWEN_CRYPTMGR *cm);

/** @name Information About the Local Key
 *
 */
/*@{*/
GWENHYWFAR_API
const char *GWEN_CryptMgr_GetLocalKeyName(const GWEN_CRYPTMGR *cm);

GWENHYWFAR_API
int GWEN_CryptMgr_GetLocalKeyNumber(const GWEN_CRYPTMGR *cm);

GWENHYWFAR_API
int GWEN_CryptMgr_GetLocalKeyVersion(const GWEN_CRYPTMGR *cm);
/*@}*/


/** @name Information About the Peer Key
 *
 */
/*@{*/
GWENHYWFAR_API
const char *GWEN_CryptMgr_GetPeerKeyName(const GWEN_CRYPTMGR *cm);

GWENHYWFAR_API
int GWEN_CryptMgr_GetPeerKeyNumber(const GWEN_CRYPTMGR *cm);

GWENHYWFAR_API
int GWEN_CryptMgr_GetPeerKeyVersion(const GWEN_CRYPTMGR *cm);
/*@}*/


/** @name Information About the Algorithms for Signing and Encrypting
 *
 */
/*@{*/
GWENHYWFAR_API
int GWEN_CryptMgr_GetCryptProfile(const GWEN_CRYPTMGR *cm);

GWENHYWFAR_API
void GWEN_CryptMgr_SetCryptProfile(GWEN_CRYPTMGR *cm, int i);

GWENHYWFAR_API
int GWEN_CryptMgr_GetSignatureProfile(const GWEN_CRYPTMGR *cm);

GWENHYWFAR_API
void GWEN_CryptMgr_SetSignatureProfile(GWEN_CRYPTMGR *cm, int i);
/*@}*/


/** @name Basic Cryptographic Functions
 *
 */
/*@{*/

/**
 * Sign the given data and create a signed object containing the signature and the given data.
 */
GWENHYWFAR_API
int GWEN_CryptMgr_Sign(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);

/**
 * Encrypt the given data and create an encrypted object containing the encrypted data.
 */
GWENHYWFAR_API
int GWEN_CryptMgr_Encrypt(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);

/**
 * Extract the data from a signed object and verify the signature.
 */
GWENHYWFAR_API
int GWEN_CryptMgr_Verify(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);

/**
 * Extracts the data from an encrypted object and decrypts it.
 */
GWENHYWFAR_API
int GWEN_CryptMgr_Decrypt(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);
/*@}*/


/** @name Complex Cryptographic Functions
 *
 * Functions of this group perform multiple operations in one setting (e.g. signing and encrypting
 * or decrypting and verifying a signature).
 */
/*@{*/

/**
 * Sign the given data (thus creating a signed object) and encrypt the result of that operation
 * (i.e. creating an encrypted object containing a signed object which actually contains the data).
 */
GWENHYWFAR_API
int GWEN_CryptMgr_Encode(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);

/**
 * Decrypt the given data which is expected to be an encrypted object containing a signed object
 * which actually contains the data. The signature of the contained signed object is verified.
 */
GWENHYWFAR_API
int GWEN_CryptMgr_Decode(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);
/*@}*/


#ifdef __cplusplus
}
#endif

/*@}*/ /* defgroup */


#endif


