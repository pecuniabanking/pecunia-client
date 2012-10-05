/** 
 * XMLSec library
 *
 * This is free software; see Copyright file in the source
 * distribution for preciese wording.
 * 
 * Copyright (C) 2002-2003 Aleksey Sanin <aleksey@aleksey.com>
 */
#ifndef __XMLSEC_GNUTLS_CRYPTO_H__
#define __XMLSEC_GNUTLS_CRYPTO_H__    

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */ 

#include <xmlsec/xmlsec.h>
#include <xmlsec/keys.h>
#include <xmlsec/transforms.h>
#include <xmlsec/dl.h>

XMLSEC_CRYPTO_EXPORT xmlSecCryptoDLFunctionsPtr	xmlSecCryptoGetFunctions_gnutls(void);

/**
 * Init shutdown
 */
XMLSEC_CRYPTO_EXPORT int		xmlSecGnuTLSInit		(void);
XMLSEC_CRYPTO_EXPORT int		xmlSecGnuTLSShutdown		(void);

XMLSEC_CRYPTO_EXPORT int		xmlSecGnuTLSKeysMngrInit	(xmlSecKeysMngrPtr mngr);
XMLSEC_CRYPTO_EXPORT int		xmlSecGnuTLSGenerateRandom	(xmlSecBufferPtr buffer,
									 xmlSecSize size);


/********************************************************************
 *
 * AES transforms
 *
 *******************************************************************/
#ifndef XMLSEC_NO_AES
/**
 * xmlSecGnuTLSKeyDataAesId:
 * 
 * The AES key data klass.
 */
#define xmlSecGnuTLSKeyDataAesId \
	xmlSecGnuTLSKeyDataAesGetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecKeyDataId 	xmlSecGnuTLSKeyDataAesGetKlass	(void);
XMLSEC_CRYPTO_EXPORT int		xmlSecGnuTLSKeyDataAesSet	(xmlSecKeyDataPtr data,
									 const xmlSecByte* buf,
									 xmlSecSize bufSize);
/**
 * xmlSecGnuTLSTransformAes128CbcId:
 * 
 * The AES128 CBC cipher transform klass.
 */
#define xmlSecGnuTLSTransformAes128CbcId \
	xmlSecGnuTLSTransformAes128CbcGetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecTransformId	xmlSecGnuTLSTransformAes128CbcGetKlass(void);

/**
 * xmlSecGnuTLSTransformAes192CbcId:
 * 
 * The AES192 CBC cipher transform klass.
 */
#define xmlSecGnuTLSTransformAes192CbcId \
	xmlSecGnuTLSTransformAes192CbcGetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecTransformId	xmlSecGnuTLSTransformAes192CbcGetKlass(void);

/**
 * xmlSecGnuTLSTransformAes256CbcId:
 * 
 * The AES256 CBC cipher transform klass.
 */
#define xmlSecGnuTLSTransformAes256CbcId \
	xmlSecGnuTLSTransformAes256CbcGetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecTransformId	xmlSecGnuTLSTransformAes256CbcGetKlass(void);

#endif /* XMLSEC_NO_AES */

/********************************************************************
 *
 * DES transforms
 *
 *******************************************************************/
#ifndef XMLSEC_NO_DES
/**
 * xmlSecGnuTLSKeyDataDesId:
 * 
 * The DES key data klass.
 */
#define xmlSecGnuTLSKeyDataDesId \
	xmlSecGnuTLSKeyDataDesGetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecKeyDataId 	xmlSecGnuTLSKeyDataDesGetKlass	(void);
XMLSEC_CRYPTO_EXPORT int		xmlSecGnuTLSKeyDataDesSet	(xmlSecKeyDataPtr data,
									 const xmlSecByte* buf,
									 xmlSecSize bufSize);

/**
 * xmlSecGnuTLSTransformDes3CbcId:
 * 
 * The DES3 CBC cipher transform klass.
 */
#define xmlSecGnuTLSTransformDes3CbcId \
	xmlSecGnuTLSTransformDes3CbcGetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecTransformId xmlSecGnuTLSTransformDes3CbcGetKlass(void);

#endif /* XMLSEC_NO_DES */


/********************************************************************
 *
 * HMAC transforms
 *
 *******************************************************************/
#ifndef XMLSEC_NO_HMAC

XMLSEC_CRYPTO_EXPORT int               xmlSecGnuTLSHmacGetMinOutputLength(void);
XMLSEC_CRYPTO_EXPORT void              xmlSecGnuTLSHmacSetMinOutputLength(int min_length);

/** 
 * xmlSecGnuTLSKeyDataHmacId:
 * 
 * The HMAC key klass.
 */
#define xmlSecGnuTLSKeyDataHmacId \
	xmlSecGnuTLSKeyDataHmacGetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecKeyDataId	xmlSecGnuTLSKeyDataHmacGetKlass	(void);
XMLSEC_CRYPTO_EXPORT int		xmlSecGnuTLSKeyDataHmacSet	(xmlSecKeyDataPtr data,
									 const xmlSecByte* buf,
									 xmlSecSize bufSize);
/**
 * xmlSecGnuTLSTransformHmacMd5Id:
 * 
 * The HMAC with MD5 signature transform klass.
 */
#define xmlSecGnuTLSTransformHmacMd5Id \
	xmlSecGnuTLSTransformHmacMd5GetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecTransformId xmlSecGnuTLSTransformHmacMd5GetKlass(void);
#endif /* XMLSEC_NO_HMAC */

/**
 * xmlSecGnuTLSTransformHmacRipemd160Id:
 * 
 * The HMAC with RipeMD160 signature transform klass.
 */
#define xmlSecGnuTLSTransformHmacRipemd160Id \
	xmlSecGnuTLSTransformHmacRipemd160GetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecTransformId xmlSecGnuTLSTransformHmacRipemd160GetKlass(void);

/**
 * xmlSecGnuTLSTransformHmacSha1Id:
 * 
 * The HMAC with SHA1 signature transform klass.
 */
#define xmlSecGnuTLSTransformHmacSha1Id \
	xmlSecGnuTLSTransformHmacSha1GetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecTransformId xmlSecGnuTLSTransformHmacSha1GetKlass(void);



/********************************************************************
 *
 * SHA1 transform
 *
 *******************************************************************/
#ifndef XMLSEC_NO_SHA1
/**
 * xmlSecGnuTLSTransformSha1Id:
 * 
 * The SHA1 digest transform klass.
 */
#define xmlSecGnuTLSTransformSha1Id \
	xmlSecGnuTLSTransformSha1GetKlass()
XMLSEC_CRYPTO_EXPORT xmlSecTransformId xmlSecGnuTLSTransformSha1GetKlass(void);
#endif /* XMLSEC_NO_SHA1 */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __XMLSEC_GNUTLS_CRYPTO_H__ */

#define __XMLSEC_GNUTLS_CRYPTO_H__    
