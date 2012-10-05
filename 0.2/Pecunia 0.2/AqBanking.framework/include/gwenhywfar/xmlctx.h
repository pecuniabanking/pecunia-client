/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id: xsd.h 898 2005-11-03 09:51:39Z cstim $
 begin       : Sat Jun 28 2003
 copyright   : (C) 2003 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *                                                                         *
 *   This library is free software; you can redistribute it and/or         *
 *   modify it under the terms of the GNU Lesser General Public            *
 *   License as published by the Free Software Foundation; either          *
 *   version 2.1 of the License, or (at your option) any later version.    *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   Lesser General Public License for more details.                       *
 *                                                                         *
 *   You should have received a copy of the GNU Lesser General Public      *
 *   License along with this library; if not, write to the Free Software   *
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston,                 *
 *   MA  02111-1307  USA                                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef GWENHYWFAR_XMLCTX_H
#define GWENHYWFAR_XMLCTX_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/inherit.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GWEN_XML_CONTEXT GWEN_XML_CONTEXT;
GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_XML_CONTEXT, GWENHYWFAR_API)


#include <gwenhywfar/xml.h>



typedef int (*GWEN_XMLCTX_STARTTAG_FN)(GWEN_XML_CONTEXT *ctx,
				       const char *tagName);
typedef int (*GWEN_XMLCTX_ENDTAG_FN)(GWEN_XML_CONTEXT *ctx, int closing);
typedef int (*GWEN_XMLCTX_ADDDATA_FN)(GWEN_XML_CONTEXT *ctx,
				      const char *data);
typedef int (*GWEN_XMLCTX_ADDCOMMENT_FN)(GWEN_XML_CONTEXT *ctx,
					 const char *data);
typedef int (*GWEN_XMLCTX_ADDATTR_FN)(GWEN_XML_CONTEXT *ctx,
				      const char *attrName,
				      const char *attrData);



GWENHYWFAR_API GWEN_XML_CONTEXT *GWEN_XmlCtx_new(uint32_t flags);
GWENHYWFAR_API void GWEN_XmlCtx_free(GWEN_XML_CONTEXT *ctx);
GWENHYWFAR_API void GWEN_XmlCtx_Attach(GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API
uint32_t GWEN_XmlCtx_GetFlags(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_XmlCtx_SetFlags(GWEN_XML_CONTEXT *ctx, uint32_t f);


GWENHYWFAR_API
uint32_t GWEN_XmlCtx_GetFinishedElement(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_XmlCtx_IncFinishedElement(GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_XmlCtx_ResetFinishedElement(GWEN_XML_CONTEXT *ctx);


GWENHYWFAR_API
int GWEN_XmlCtx_GetDepth(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_XmlCtx_SetDepth(GWEN_XML_CONTEXT *ctx, int i);

GWENHYWFAR_API
void GWEN_XmlCtx_IncDepth(GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API
int GWEN_XmlCtx_DecDepth(GWEN_XML_CONTEXT *ctx);


GWENHYWFAR_API 
void GWEN_XmlCtx_SetCurrentNode(GWEN_XML_CONTEXT *ctx, GWEN_XMLNODE *n);

GWENHYWFAR_API 
GWEN_XMLNODE *GWEN_XmlCtx_GetCurrentNode(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API 
void GWEN_XmlCtx_SetCurrentHeader(GWEN_XML_CONTEXT *ctx, GWEN_XMLNODE *n);

GWENHYWFAR_API 
GWEN_XMLNODE *GWEN_XmlCtx_GetCurrentHeader(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API 
GWEN_XMLCTX_STARTTAG_FN GWEN_XmlCtx_SetStartTagFn(GWEN_XML_CONTEXT *ctx,
						  GWEN_XMLCTX_STARTTAG_FN f);

GWENHYWFAR_API 
GWEN_XMLCTX_ENDTAG_FN GWEN_XmlCtx_SetEndTagFn(GWEN_XML_CONTEXT *ctx,
					      GWEN_XMLCTX_ENDTAG_FN f);

GWENHYWFAR_API 
GWEN_XMLCTX_ADDDATA_FN GWEN_XmlCtx_SetAddDataFn(GWEN_XML_CONTEXT *ctx,
						GWEN_XMLCTX_ADDDATA_FN f);

GWENHYWFAR_API 
GWEN_XMLCTX_ADDCOMMENT_FN
  GWEN_XmlCtx_SetAddCommentFn(GWEN_XML_CONTEXT *ctx,
			      GWEN_XMLCTX_ADDCOMMENT_FN f);

GWENHYWFAR_API 
GWEN_XMLCTX_ADDATTR_FN GWEN_XmlCtx_SetAddAttrFn(GWEN_XML_CONTEXT *ctx,
						GWEN_XMLCTX_ADDATTR_FN f);





GWENHYWFAR_API 
GWEN_XML_CONTEXT *GWEN_XmlCtxStore_new(GWEN_XMLNODE *n, uint32_t flags);


#ifdef __cplusplus
}
#endif


#endif

