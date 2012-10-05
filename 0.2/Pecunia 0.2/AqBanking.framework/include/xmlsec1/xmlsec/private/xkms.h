/** 
 * XML Security Library (http://www.aleksey.com/xmlsec).
 *
 * "XML Key Management Specification v 2.0" implementation
 *  http://www.w3.org/TR/xkms2/
 * 
 * This is free software; see Copyright file in the source
 * distribution for preciese wording.
 * 
 * Copyright (C) 2002-2003 Aleksey Sanin <aleksey@aleksey.com>
 */
#ifndef __XMLSEC_PRIVATE_XKMS_H__
#define __XMLSEC_PRIVATE_XKMS_H__    

#ifndef XMLSEC_PRIVATE
#error "xmlsec/private/xkms.h file contains private xmlsec definitions and should not be used outside xmlsec or xmlsec-<crypto> libraries"
#endif /* XMLSEC_PRIVATE */

#ifndef XMLSEC_NO_XKMS
	
#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */ 
#include <stdio.h>		

#include <libxml/tree.h>
#include <libxml/parser.h> 

#include <xmlsec/xmlsec.h>
#include <xmlsec/buffer.h>
#include <xmlsec/list.h>
#include <xmlsec/keys.h>
#include <xmlsec/keysmngr.h>
#include <xmlsec/keyinfo.h>
#include <xmlsec/transforms.h>
#include <xmlsec/xkms.h>

/************************************************************************
 *
 * XKMS RespondWith Klass
 *
 ************************************************************************/ 
typedef int  		(*xmlSecXkmsRespondWithNodeReadMethod)	(xmlSecXkmsRespondWithId id,
								 xmlSecXkmsServerCtxPtr ctx,
								 xmlNodePtr node);
typedef int  		(*xmlSecXkmsRespondWithNodeWriteMethod)	(xmlSecXkmsRespondWithId id,
								 xmlSecXkmsServerCtxPtr ctx,
								 xmlNodePtr node);
struct _xmlSecXkmsRespondWithKlass {
    const xmlChar*				valueName;
    const xmlChar*				valueNs;
    
    const xmlChar*				nodeName;
    const xmlChar*				nodeNs;
    
    xmlSecXkmsRespondWithNodeReadMethod		readNode;
    xmlSecXkmsRespondWithNodeWriteMethod	writeNode;

    void*					reserved1;
    void*					reserved2;
};

#define xmlSecXkmsRespondWithKlassGetName(id) \
	((((id) != NULL) && ((id)->valueName != NULL)) ? (id)->valueName : NULL)

/************************************************************************
 *
 * XKMS ServerRequest Klass
 *
 ************************************************************************/ 
typedef int  			(*xmlSecXkmsServerRequestNodeReadMethod)
								(xmlSecXkmsServerRequestId id,
								 xmlSecXkmsServerCtxPtr ctx,
								 xmlNodePtr node);
typedef int  			(*xmlSecXkmsServerRequestExecuteMethod)
								(xmlSecXkmsServerRequestId id,
								 xmlSecXkmsServerCtxPtr ctx);
typedef int  			(*xmlSecXkmsServerRequestNodeWriteMethod)
								(xmlSecXkmsServerRequestId id,
								 xmlSecXkmsServerCtxPtr ctx,
								 xmlNodePtr node);
struct _xmlSecXkmsServerRequestKlass {
    const xmlChar*				name;
    const xmlChar*				requestNodeName;
    const xmlChar*				requestNodeNs;
    const xmlChar*				resultNodeName;
    const xmlChar*				resultNodeNs;
    xmlSecBitMask				flags;
    
    xmlSecXkmsServerRequestNodeReadMethod	readNode;
    xmlSecXkmsServerRequestNodeWriteMethod	writeNode;
    xmlSecXkmsServerRequestExecuteMethod	execute;
    
    void*					reserved1;
    void*					reserved2;
};

#define xmlSecXkmsServerRequestKlassGetName(id) \
	((((id) != NULL) && ((id)->name != NULL)) ? (id)->name : NULL)


/************************************************************************
 *
 * XKMS ServerRequest Klass flags
 *
 ************************************************************************/ 
/**
 * XMLSEC_XKMS_SERVER_REQUEST_KLASS_ALLOWED_IN_COUMPOUND:
 *
 * The server request klass is allowed in xkms:CompoundRequest element.
 */
#define XMLSEC_XKMS_SERVER_REQUEST_KLASS_ALLOWED_IN_COUMPOUND   0x00000001

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* XMLSEC_NO_XKMS */

#endif /* __XMLSEC_PRIVATE_XKMS_H__ */

