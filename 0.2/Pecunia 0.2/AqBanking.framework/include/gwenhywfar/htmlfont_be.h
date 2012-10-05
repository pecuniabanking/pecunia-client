/***************************************************************************
 begin       : Sat Feb 20 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef HTMLFONT_BE_H
#define HTMLFONT_BE_H

#include <gwenhywfar/list1.h>
#include <gwenhywfar/inherit.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef struct HTML_FONT HTML_FONT;
GWEN_INHERIT_FUNCTION_LIB_DEFS(HTML_FONT, GWENHYWFAR_API)
GWEN_LIST_FUNCTION_LIB_DEFS(HTML_FONT, HtmlFont, GWENHYWFAR_API)


#define HTML_FONT_FLAGS_NONE       0x00000000
#define HTML_FONT_FLAGS_STRONG     0x00000001
#define HTML_FONT_FLAGS_ITALIC     0x00000002
#define HTML_FONT_FLAGS_UNDERLINE  0x00000004


GWENHYWFAR_API 
HTML_FONT *HtmlFont_new();

GWENHYWFAR_API 
void HtmlFont_free(HTML_FONT *fnt);

GWENHYWFAR_API 
void HtmlFont_Attach(HTML_FONT *fnt);


GWENHYWFAR_API 
const char *HtmlFont_GetFontName(const HTML_FONT *fnt);

GWENHYWFAR_API 
void HtmlFont_SetFontName(HTML_FONT *fnt, const char *s);

GWENHYWFAR_API 
int HtmlFont_GetFontSize(const HTML_FONT *fnt);

GWENHYWFAR_API 
void HtmlFont_SetFontSize(HTML_FONT *fnt, int i);


GWENHYWFAR_API 
uint32_t HtmlFont_GetFontFlags(const HTML_FONT *fnt);

GWENHYWFAR_API 
void HtmlFont_SetFontFlags(HTML_FONT *fnt, uint32_t i);

GWENHYWFAR_API 
void HtmlFont_AddFontFlags(HTML_FONT *fnt, uint32_t i);

GWENHYWFAR_API 
void HtmlFont_SubFontFlags(HTML_FONT *fnt, uint32_t i);

#ifdef __cplusplus
}
#endif


#endif

