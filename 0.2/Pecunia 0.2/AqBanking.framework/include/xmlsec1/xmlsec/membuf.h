/** 
 * XML Security Library (http://www.aleksey.com/xmlsec).
 *
 * Memory buffer transform
 *
 * This is free software; see Copyright file in the source
 * distribution for preciese wording.
 * 
 * Copyright (C) 2002-2003 Aleksey Sanin <aleksey@aleksey.com>
 */
#ifndef __XMLSEC_MEMBUF_H__
#define __XMLSEC_MEMBUF_H__    

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */ 

#include <libxml/tree.h>

#include <xmlsec/xmlsec.h>
#include <xmlsec/buffer.h>
#include <xmlsec/transforms.h>

/********************************************************************
 *
 * Memory Buffer transform 
 *
 *******************************************************************/
/**
 * xmlSecTransformMemBufId:
 * 
 * The Memory Buffer transform klass.
 */
#define xmlSecTransformMemBufId \
	xmlSecTransformMemBufGetKlass()
XMLSEC_EXPORT xmlSecTransformId	xmlSecTransformMemBufGetKlass		(void);
XMLSEC_EXPORT xmlSecBufferPtr	xmlSecTransformMemBufGetBuffer		(xmlSecTransformPtr transform);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __XMLSEC_MEMBUF_H__ */

