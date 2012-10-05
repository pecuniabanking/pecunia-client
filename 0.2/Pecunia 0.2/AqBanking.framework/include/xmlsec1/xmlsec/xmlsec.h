/** 
 * XML Security Library (http://www.aleksey.com/xmlsec).
 *
 * General functions and forward declarations.
 *
 * This is free software; see Copyright file in the source
 * distribution for preciese wording.
 * 
 * Copyright (C) 2002-2003 Aleksey Sanin <aleksey@aleksey.com>
 */
#ifndef __XMLSEC_H__
#define __XMLSEC_H__    

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */ 

#include <libxml/tree.h>

#include <xmlsec/version.h>
#include <xmlsec/exports.h>
#include <xmlsec/strings.h>

/***********************************************************************
 *
 * Basic types to make ports to exotic platforms easier
 *
 ***********************************************************************/
/**
 * xmlSecPtr:
 *
 * Void pointer.
 */
typedef void*					xmlSecPtr;

/**
 * xmlSecSize:
 *
 * Size of something. Should be typedef instead of define
 * but it will break ABI (todo).
 */
#ifdef XMLSEC_NO_SIZE_T
#define xmlSecSize				unsigned int
#else  /* XMLSEC_NO_SIZE_T */
#define xmlSecSize				size_t
#endif /* XMLSEC_NO_SIZE_T */

/**
 * xmlSecByte:
 *
 * One byte. Should be typedef instead of define
 * but it will break ABI (todo).
 */
#define xmlSecByte				unsigned char

/***********************************************************************
 *
 * Forward declarations
 *
 ***********************************************************************/
typedef struct _xmlSecKeyData 			xmlSecKeyData, *xmlSecKeyDataPtr; 
typedef struct _xmlSecKeyDataStore		xmlSecKeyDataStore, *xmlSecKeyDataStorePtr; 
typedef struct _xmlSecKeyInfoCtx  		xmlSecKeyInfoCtx, *xmlSecKeyInfoCtxPtr; 
typedef struct _xmlSecKey 			xmlSecKey, *xmlSecKeyPtr; 
typedef struct _xmlSecKeyStore			xmlSecKeyStore, *xmlSecKeyStorePtr; 
typedef struct _xmlSecKeysMngr  		xmlSecKeysMngr, *xmlSecKeysMngrPtr; 
typedef struct _xmlSecTransform 		xmlSecTransform, *xmlSecTransformPtr; 
typedef struct _xmlSecTransformCtx 		xmlSecTransformCtx, *xmlSecTransformCtxPtr; 

#ifndef XMLSEC_NO_XMLDSIG
typedef struct _xmlSecDSigCtx 			xmlSecDSigCtx, *xmlSecDSigCtxPtr; 
#endif /* XMLSEC_NO_XMLDSIG */

#ifndef XMLSEC_NO_XMLENC
typedef struct _xmlSecEncCtx 			xmlSecEncCtx, *xmlSecEncCtxPtr; 
#endif /* XMLSEC_NO_XMLENC */

#ifndef XMLSEC_NO_XKMS
typedef struct _xmlSecXkmsServerCtx		xmlSecXkmsServerCtx, *xmlSecXkmsServerCtxPtr; 
#endif /* XMLSEC_NO_XKMS */

XMLSEC_EXPORT int	xmlSecInit		(void);
XMLSEC_EXPORT int	xmlSecShutdown		(void);



/***********************************************************************
 *
 * Version checking
 *
 ***********************************************************************/
/** 
 * xmlSecCheckVersionExact:
 *
 * Macro. Returns 1 if the loaded xmlsec library version exactly matches 
 * the one used to compile the caller, 0 if it does not or a negative
 * value if an error occurs.
 */
#define xmlSecCheckVersionExact()	\
    xmlSecCheckVersionExt(XMLSEC_VERSION_MAJOR, XMLSEC_VERSION_MINOR, XMLSEC_VERSION_SUBMINOR, xmlSecCheckVersionExact)

/** 
 * xmlSecCheckVersion:
 *
 * Macro. Returns 1 if the loaded xmlsec library version ABI compatible with
 * the one used to compile the caller, 0 if it does not or a negative
 * value if an error occurs.
 */
#define xmlSecCheckVersion()	\
    xmlSecCheckVersionExt(XMLSEC_VERSION_MAJOR, XMLSEC_VERSION_MINOR, XMLSEC_VERSION_SUBMINOR, xmlSecCheckVersionABICompatible)

/**
 * xmlSecCheckVersionMode:
 * @xmlSecCheckVersionExact:		the version should match exactly.
 * @xmlSecCheckVersionABICompatible:	the version should be ABI compatible.
 *
 * The xmlsec library version mode.
 */
typedef enum {
    xmlSecCheckVersionExact = 0,
    xmlSecCheckVersionABICompatible
} xmlSecCheckVersionMode;

XMLSEC_EXPORT int	xmlSecCheckVersionExt	(int major, 
						 int minor, 
						 int subminor, 
						 xmlSecCheckVersionMode mode);

/**
 * ATTRIBUTE_UNUSED:
 *
 * Macro used to signal to GCC unused function parameters
 */
#ifdef __GNUC__
#ifdef HAVE_ANSIDECL_H
#include <ansidecl.h>
#endif
#ifndef ATTRIBUTE_UNUSED
#define ATTRIBUTE_UNUSED
#endif
#else
#define ATTRIBUTE_UNUSED
#endif

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __XMLSEC_H__ */


