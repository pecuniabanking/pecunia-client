/***************************************************************************
 begin       : Sat Feb 20 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef HTMLOBJECT_BE_H
#define HTMLOBJECT_BE_H


#include <gwenhywfar/tree.h>
#include <gwenhywfar/inherit.h>
#include <gwenhywfar/xmlctx.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef struct HTML_OBJECT HTML_OBJECT;
GWEN_TREE_FUNCTION_LIB_DEFS(HTML_OBJECT, HtmlObject, GWENHYWFAR_API)
GWEN_INHERIT_FUNCTION_LIB_DEFS(HTML_OBJECT, GWENHYWFAR_API)


#define HTML_OBJECT_FLAGS_START_ON_NEWLINE 0x00000001
#define HTML_OBJECT_FLAGS_END_WITH_NEWLINE 0x00000002

#define HTML_OBJECT_FLAGS_JUSTIFY_LEFT     0x00000000
#define HTML_OBJECT_FLAGS_JUSTIFY_RIGHT    0x00000004
#define HTML_OBJECT_FLAGS_JUSTIFY_HCENTER  0x00000008
#define HTML_OBJECT_FLAGS_JUSTIFY_TOP      0x00000000
#define HTML_OBJECT_FLAGS_JUSTIFY_BOTTOM   0x00000010
#define HTML_OBJECT_FLAGS_JUSTIFY_VCENTER  0x00000020


typedef int (*HTML_OBJECT_LAYOUT_FN)(HTML_OBJECT *o);

typedef enum {
  HtmlObjectType_Unknown=0,
  HtmlObjectType_Box,
  HtmlObjectType_Word,
  HtmlObjectType_OrderedList,
  HtmlObjectType_UnorderedList,
  HtmlObjectType_ListEntry,
  HtmlObjectType_Grid,
  HtmlObjectType_GridEntry,
  HtmlObjectType_Control,
  HtmlObjectType_Image,

  HtmlObjectType_Count
} HTML_OBJECT_TYPE;


#include <gwenhywfar/htmlprops_be.h>
#include <gwenhywfar/htmlctx_be.h>


GWENHYWFAR_API HTML_OBJECT *HtmlObject_new(GWEN_XML_CONTEXT *ctx, HTML_OBJECT_TYPE t);
GWENHYWFAR_API void HtmlObject_free(HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_Attach(HTML_OBJECT *o);

GWENHYWFAR_API GWEN_XML_CONTEXT *HtmlObject_GetXmlCtx(const HTML_OBJECT *o);

GWENHYWFAR_API HTML_OBJECT_TYPE HtmlObject_GetObjectType(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetObjectType(HTML_OBJECT *o, HTML_OBJECT_TYPE t);

GWENHYWFAR_API HTML_PROPS *HtmlObject_GetProperties(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetProperties(HTML_OBJECT *o, HTML_PROPS *pr);

GWENHYWFAR_API int HtmlObject_GetX(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetX(HTML_OBJECT *o, int i);

GWENHYWFAR_API int HtmlObject_GetY(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetY(HTML_OBJECT *o, int i);

GWENHYWFAR_API int HtmlObject_GetWidth(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetWidth(HTML_OBJECT *o, int i);

GWENHYWFAR_API int HtmlObject_GetHeight(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetHeight(HTML_OBJECT *o, int i);

GWENHYWFAR_API int HtmlObject_GetConfiguredWidth(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetConfiguredWidth(HTML_OBJECT *o, int i);

GWENHYWFAR_API int HtmlObject_GetConfiguredHeight(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetConfiguredHeight(HTML_OBJECT *o, int i);

GWENHYWFAR_API const char *HtmlObject_GetText(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetText(HTML_OBJECT *o, const char *s);

GWENHYWFAR_API int HtmlObject_Layout(HTML_OBJECT *o);

GWENHYWFAR_API uint32_t HtmlObject_GetFlags(const HTML_OBJECT *o);
GWENHYWFAR_API void HtmlObject_SetFlags(HTML_OBJECT *o, uint32_t fl);
GWENHYWFAR_API void HtmlObject_AddFlags(HTML_OBJECT *o, uint32_t fl);
GWENHYWFAR_API void HtmlObject_SubFlags(HTML_OBJECT *o, uint32_t fl);


GWENHYWFAR_API HTML_OBJECT_LAYOUT_FN HtmlObject_SetLayoutFn(HTML_OBJECT *o,
							  HTML_OBJECT_LAYOUT_FN fn);

#ifdef __cplusplus
}
#endif


#endif

