/***************************************************************************
 begin       : Mon Feb 22 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef HTMLXMLCTX_BE_H
#define HTMLXMLCTX_BE_H

#include <gwenhywfar/htmlfont_be.h>
#include <gwenhywfar/htmlobject_be.h>
#include <gwenhywfar/htmlimage_be.h>

#include <gwenhywfar/xmlctx.h>
#include <gwenhywfar/stringlist.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef int (*HTMLCTX_GET_TEXT_WIDTH_FN)(GWEN_XML_CONTEXT *ctx,
					 HTML_FONT *fnt,
					 const char *s);

typedef int (*HTMLCTX_GET_TEXT_HEIGHT_FN)(GWEN_XML_CONTEXT *ctx,
					  HTML_FONT *fnt,
					  const char *s);


typedef uint32_t (*HTMLCTX_GET_COLOR_FROM_NAME_FN)(const GWEN_XML_CONTEXT *ctx, const char *s);


typedef HTML_FONT* (*HTMLCTX_GET_FONT_FN)(GWEN_XML_CONTEXT *ctx,
					  const char *fontName,
					  int fontSize,
					  uint32_t fontFlags);

typedef HTML_IMAGE* (*HTMLCTX_GET_IMAGE_FN)(GWEN_XML_CONTEXT *ctx, const char *imageName);



GWENHYWFAR_API
GWEN_XML_CONTEXT *HtmlCtx_new(uint32_t flags);

GWENHYWFAR_API 
void HtmlCtx_SetText(GWEN_XML_CONTEXT *ctx, const char *s);

GWENHYWFAR_API 
int HtmlCtx_Layout(GWEN_XML_CONTEXT *ctx, int width, int height);

GWENHYWFAR_API 
HTML_OBJECT *HtmlCtx_GetRootObject(const GWEN_XML_CONTEXT *ctx);


GWENHYWFAR_API 
HTML_FONT *HtmlCtx_GetFont(GWEN_XML_CONTEXT *ctx,
			   const char *fontName,
			   int fontSize,
			   uint32_t fontFlags);

/**
 * The implementation must set width and height in the image returned.
 */
GWENHYWFAR_API 
HTML_IMAGE *HtmlCtx_GetImage(GWEN_XML_CONTEXT *ctx, const char *imageName);

GWENHYWFAR_API 
HTML_PROPS *HtmlCtx_GetStandardProps(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API 
void HtmlCtx_SetStandardProps(GWEN_XML_CONTEXT *ctx, HTML_PROPS *pr);


GWENHYWFAR_API 
int HtmlCtx_GetWidth(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API 
int HtmlCtx_GetHeight(const GWEN_XML_CONTEXT *ctx);


GWENHYWFAR_API 
int HtmlCtx_GetResolutionX(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API 
void HtmlCtx_SetResolutionX(GWEN_XML_CONTEXT *ctx, int i);

GWENHYWFAR_API 
int HtmlCtx_GetResolutionY(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API 
void HtmlCtx_SetResolutionY(GWEN_XML_CONTEXT *ctx, int i);


GWENHYWFAR_API 
GWEN_STRINGLIST *HtmlCtx_GetMediaPaths(const GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API 
void HtmlCtx_AddMediaPath(GWEN_XML_CONTEXT *ctx, const char *s);


GWENHYWFAR_API 
HTMLCTX_GET_TEXT_WIDTH_FN HtmlCtx_SetGetTextWidthFn(GWEN_XML_CONTEXT *ctx,
						    HTMLCTX_GET_TEXT_WIDTH_FN fn);

GWENHYWFAR_API 
HTMLCTX_GET_TEXT_HEIGHT_FN HtmlCtx_SetGetTextHeightFn(GWEN_XML_CONTEXT *ctx,
						      HTMLCTX_GET_TEXT_HEIGHT_FN fn);


GWENHYWFAR_API 
HTMLCTX_GET_COLOR_FROM_NAME_FN HtmlCtx_SetGetColorFromNameFn(GWEN_XML_CONTEXT *ctx,
							     HTMLCTX_GET_COLOR_FROM_NAME_FN fn);

GWENHYWFAR_API 
HTMLCTX_GET_FONT_FN HtmlCtx_SetGetFontFn(GWEN_XML_CONTEXT *ctx,
					 HTMLCTX_GET_FONT_FN fn);

GWENHYWFAR_API 
HTMLCTX_GET_IMAGE_FN HtmlCtx_SetGetImageFn(GWEN_XML_CONTEXT *ctx, HTMLCTX_GET_IMAGE_FN fn);

#ifdef __cplusplus
}
#endif

#endif

