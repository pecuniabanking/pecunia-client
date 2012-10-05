/***************************************************************************
 begin       : Sat Feb 20 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef HTMLPROPS_BE_H
#define HTMLPROPS_BE_H


typedef struct HTML_PROPS HTML_PROPS;

#define HTML_PROPS_NOCOLOR 0xffffffff

#include <gwen-gui-fox16/html/htmlfont_be.h>


#ifdef __cplusplus
extern "C" {
#endif


HTML_PROPS *HtmlProps_new();
void HtmlProps_free(HTML_PROPS *pr);
void HtmlProps_Attach(HTML_PROPS *pr);
HTML_PROPS *HtmlProps_dup(const HTML_PROPS *pr);


HTML_FONT *HtmlProps_GetFont(const HTML_PROPS *pr);
void HtmlProps_SetFont(HTML_PROPS *pr, HTML_FONT *fnt);

uint32_t HtmlProps_GetForegroundColor(const HTML_PROPS *pr);
void HtmlProps_SetForegroundColor(HTML_PROPS *pr, uint32_t c);

uint32_t HtmlProps_GetBackgroundColor(const HTML_PROPS *pr);
void HtmlProps_SetBackgroundColor(HTML_PROPS *pr, uint32_t c);


#ifdef __cplusplus
}
#endif


#endif

