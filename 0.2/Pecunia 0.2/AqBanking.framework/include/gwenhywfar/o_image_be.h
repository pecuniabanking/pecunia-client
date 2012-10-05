/***************************************************************************
 begin       : Mon Feb 22 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef HTMLOBJECT_IMAGE_BE_H
#define HTMLOBJECT_IMAGE_BE_H


#include <gwenhywfar/htmlobject_be.h>
#include <gwenhywfar/htmlimage_be.h>


#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API HTML_OBJECT *HtmlObject_Image_new(GWEN_XML_CONTEXT *ctx);

GWENHYWFAR_API int HtmlObject_Image_GetScaledWidth(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_Image_SetScaledWidth(HTML_OBJECT *o, int i);

GWENHYWFAR_API int HtmlObject_Image_GetScaledHeight(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_Image_SetScaledHeight(HTML_OBJECT *o, int i);

GWENHYWFAR_API int HtmlObject_Image_GetOriginalWidth(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_Image_SetOriginalWidth(HTML_OBJECT *o, int i);

GWENHYWFAR_API int HtmlObject_Image_GetOriginalHeight(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_Image_SetOriginalHeight(HTML_OBJECT *o, int i);

GWENHYWFAR_API HTML_IMAGE *HtmlObject_Image_GetImage(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_Image_SetImage(HTML_OBJECT *o, HTML_IMAGE *img);


#ifdef __cplusplus
}
#endif


#endif

