/***************************************************************************
 begin       : Fri Jul 16 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef HTMLIMAGE_BE_H
#define HTMLIMAGE_BE_H

#include <gwenhywfar/list1.h>
#include <gwenhywfar/inherit.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef struct HTML_IMAGE HTML_IMAGE;
GWEN_INHERIT_FUNCTION_LIB_DEFS(HTML_IMAGE, GWENHYWFAR_API)
GWEN_LIST_FUNCTION_LIB_DEFS(HTML_IMAGE, HtmlImage, GWENHYWFAR_API)


GWENHYWFAR_API 
HTML_IMAGE *HtmlImage_new();

GWENHYWFAR_API 
void HtmlImage_free(HTML_IMAGE *img);

GWENHYWFAR_API 
void HtmlImage_Attach(HTML_IMAGE *img);


GWENHYWFAR_API 
const char *HtmlImage_GetImageName(const HTML_IMAGE *img);

GWENHYWFAR_API 
void HtmlImage_SetImageName(HTML_IMAGE *img, const char *s);

GWENHYWFAR_API 
int HtmlImage_GetWidth(const HTML_IMAGE *img);

GWENHYWFAR_API 
void HtmlImage_SetWidth(HTML_IMAGE *img, int i);


GWENHYWFAR_API 
int HtmlImage_GetHeight(const HTML_IMAGE *img);

GWENHYWFAR_API 
void HtmlImage_SetHeight(HTML_IMAGE *img, int i);


#ifdef __cplusplus
}
#endif


#endif

