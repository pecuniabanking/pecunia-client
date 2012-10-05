/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
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

/** @file list2.h
 *
 * @short This file contains some macros concerning lists.
 *
 */


#ifndef GWENHYWFAR_LIST2_H
#define GWENHYWFAR_LIST2_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/misc.h>
#include <gwenhywfar/list.h>
#include <gwenhywfar/refptr.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#ifdef __cplusplus
extern "C" {
#endif

  /*
   * This macro should be used in libraries with the
   * __declspec(dllexport) declaration as the @c decl argument.
   */
#define GWEN_LIST2_FUNCTION_LIB_DEFS(t, pr, decl) \
  typedef struct t##_LIST2 t##_LIST2; \
  typedef struct t##_LIST2_ITERATOR t##_LIST2_ITERATOR; \
  typedef t* (t##_LIST2_FOREACH)(t *element, void *user_data); \
  \
  decl t##_LIST2 *pr##_List2_new(); \
  decl void pr##_List2_free(t##_LIST2 *l); \
  decl t##_LIST2 *pr##_List2_dup(const t##_LIST2 *l); \
  decl void pr##_List2_Unshare(t##_LIST2 *l); \
  decl void pr##_List2_Dump(t##_LIST2 *l, FILE *f, unsigned int indent); \
  decl void pr##_List2_PushBack(t##_LIST2 *l, t *p); \
  decl void pr##_List2_PushFront(t##_LIST2 *l, t *p); \
  decl t *pr##_List2_GetFront(const t##_LIST2 *l); \
  decl t *pr##_List2_GetBack(const t##_LIST2 *l); \
  decl void pr##_List2_Erase(t##_LIST2 *l, t##_LIST2_ITERATOR *it); \
  decl void pr##_List2_Remove(t##_LIST2 *l, const t *p); \
  decl unsigned int pr##_List2_GetSize(const t##_LIST2 *l); \
  decl int pr##_List2_IsEmpty(const t##_LIST2 *l); \
  decl void pr##_List2_PopBack(t##_LIST2 *l); \
  decl void pr##_List2_PopFront(t##_LIST2 *l); \
  decl void pr##_List2_Clear(t##_LIST2 *l); \
  decl t##_LIST2_ITERATOR *pr##_List2_First(const t##_LIST2 *l); \
  decl t##_LIST2_ITERATOR *pr##_List2_Last(const t##_LIST2 *l); \
  decl t##_LIST2_ITERATOR *pr##_List2Iterator_new(t##_LIST2 *l); \
  decl void pr##_List2Iterator_free(t##_LIST2_ITERATOR *li); \
  decl t *pr##_List2Iterator_Previous(t##_LIST2_ITERATOR *li); \
  decl t *pr##_List2Iterator_Next(t##_LIST2_ITERATOR *li); \
  decl t *pr##_List2Iterator_Data(t##_LIST2_ITERATOR *li); \
  decl void pr##_List2Iterator_IncLinkCount(t##_LIST2_ITERATOR *li); \
  decl unsigned int pr##_List2Iterator_GetLinkCount(const t##_LIST2_ITERATOR *li); \
  decl t##_LIST2_ITERATOR *pr##_List2_FindIter(t##_LIST2 *l, const t *p); \
  decl const t *pr##_List2_Contains(t##_LIST2 *l, const t *p); \
  decl t *pr##_List2_ForEach(t##_LIST2 *l, t##_LIST2_FOREACH, void *user_data);

  /** This macro should be used in applications, not in libraries. In
   * libraries please use the macro @ref GWEN_LIST2_FUNCTION_LIB_DEFS. */
#define GWEN_LIST2_FUNCTION_DEFS(t, pr) \
  GWEN_LIST2_FUNCTION_LIB_DEFS(t, pr, GWEN_DUMMY_EMPTY_ARG)


  /** This macro actually implements the functions. Please use it in your
   * source file (*.c) after the includes.
   */
#define GWEN_LIST2_FUNCTIONS(t, pr) \
  t##_LIST2 *pr##_List2_new() { \
    return (t##_LIST2*)GWEN_List_new(); \
  } \
  \
  void pr##_List2_free(t##_LIST2 *l) { \
    GWEN_List_free((GWEN_LIST*)l); \
  } \
  \
  t##_LIST2 *pr##_List2_dup(const t##_LIST2 *l) {\
    return (t##_LIST2*)GWEN_List_dup((const GWEN_LIST*)l); \
  }\
  \
  void pr##_List2_Unshare(t##_LIST2 *l) { \
    GWEN_List_Unshare((GWEN_LIST*)l); \
  } \
  \
  void pr##_List2_Dump(t##_LIST2 *l, FILE *f, unsigned int indent) { \
    GWEN_List_Dump((GWEN_LIST*) l, f, indent); \
  } \
  \
  void pr##_List2_PushBack(t##_LIST2 *l, t *p) { \
    GWEN_List_PushBack((GWEN_LIST*) l, p); \
  } \
  \
  void pr##_List2_PushFront(t##_LIST2 *l, t *p) { \
    GWEN_List_PushFront((GWEN_LIST*) l, p); \
  } \
  \
  t *pr##_List2_GetFront(const t##_LIST2 *l) { \
  return (t*) GWEN_List_GetFront((const GWEN_LIST*) l); \
  }\
  \
  t *pr##_List2_GetBack(const t##_LIST2 *l) { \
  return (t*) GWEN_List_GetBack((const GWEN_LIST*) l); \
  } \
  \
  void pr##_List2_Erase(t##_LIST2 *l, t##_LIST2_ITERATOR *it) { \
    GWEN_List_Erase((GWEN_LIST*) l, (GWEN_LIST_ITERATOR*) it); \
  } \
  \
  void pr##_List2_Remove(t##_LIST2 *l, const t *p){ \
    GWEN_List_Remove((GWEN_LIST*) l, p); \
  } \
  \
  unsigned int pr##_List2_GetSize(const t##_LIST2 *l){ \
    return GWEN_List_GetSize((const GWEN_LIST*) l); \
  }\
  \
  int pr##_List2_IsEmpty(const t##_LIST2 *l){ \
    return GWEN_List_IsEmpty((const GWEN_LIST*) l); \
  }\
  \
  void pr##_List2_PopBack(t##_LIST2 *l){ \
    GWEN_List_PopBack((GWEN_LIST*) l); \
  }\
  \
  void pr##_List2_PopFront(t##_LIST2 *l){ \
    GWEN_List_PopFront((GWEN_LIST*) l); \
  }\
  \
  void pr##_List2_Clear(t##_LIST2 *l){ \
    GWEN_List_Clear((GWEN_LIST*) l); \
  }\
  \
  \
  t##_LIST2_ITERATOR *pr##_List2_First(const t##_LIST2 *l) { \
    return (t##_LIST2_ITERATOR*) GWEN_List_First((const GWEN_LIST*) l); \
  }\
  \
  t##_LIST2_ITERATOR *pr##_List2_Last(const t##_LIST2 *l) { \
    return (t##_LIST2_ITERATOR*) GWEN_List_Last((const GWEN_LIST*) l); \
  }\
  \
  t##_LIST2_ITERATOR *pr##_List2Iterator_new(t##_LIST2 *l) { \
    return (t##_LIST2_ITERATOR*) GWEN_ListIterator_new((GWEN_LIST*) l); \
  }\
  \
  void pr##_List2Iterator_free(t##_LIST2_ITERATOR *li) {\
    GWEN_ListIterator_free((GWEN_LIST_ITERATOR*)li); \
  } \
  \
  t *pr##_List2Iterator_Previous(t##_LIST2_ITERATOR *li) { \
    return (t*) GWEN_ListIterator_Previous((GWEN_LIST_ITERATOR*)li); \
  }\
  \
  t *pr##_List2Iterator_Next(t##_LIST2_ITERATOR *li) { \
    return (t*) GWEN_ListIterator_Next((GWEN_LIST_ITERATOR*)li); \
  }\
  \
  t *pr##_List2Iterator_Data(t##_LIST2_ITERATOR *li) { \
    return (t*) GWEN_ListIterator_Data((GWEN_LIST_ITERATOR*)li); \
  } \
  \
  void pr##_List2Iterator_IncLinkCount(t##_LIST2_ITERATOR *li) { \
    GWEN_ListIterator_IncLinkCount((GWEN_LIST_ITERATOR*)li); \
  } \
  \
  unsigned int pr##_List2Iterator_GetLinkCount(const t##_LIST2_ITERATOR *li){\
    return GWEN_ListIterator_GetLinkCount((const GWEN_LIST_ITERATOR*)li); \
  } \
  \
  t##_LIST2_ITERATOR *pr##_List2_FindIter(t##_LIST2 *l, const t *p){ \
    return (t##_LIST2_ITERATOR*) GWEN_List_FindIter((GWEN_LIST *)l, p); \
  } \
  \
  const t *pr##_List2_Contains(t##_LIST2 *l, const t *p){ \
    return (const t*) GWEN_List_Contains((GWEN_LIST*)l, p); \
  } \
  \
  t *pr##_List2_ForEach(t##_LIST2 *l, t##_LIST2_FOREACH fn, void *user_data){ \
    t##_LIST2_ITERATOR *it; \
    t *el; \
    if (!l) return 0; \
    \
    it=pr##_List2_First(l); \
    if (!it) \
      return 0; \
    el=pr##_List2Iterator_Data(it); \
    while(el) { \
      el=fn(el, user_data); \
      if (el) { \
        pr##_List2Iterator_free(it); \
        return el; \
      } \
      el=pr##_List2Iterator_Next(it); \
      } \
    pr##_List2Iterator_free(it); \
    return 0; \
  }

  /*
   * This macro should be used in libraries with the
   * __declspec(dllexport) declaration as the @c decl argument.
   */
#define GWEN_CONSTLIST2_FUNCTION_LIB_DEFS(t, pr, decl) \
  typedef struct t##_CONSTLIST2 t##_CONSTLIST2; \
  typedef struct t##_CONSTLIST2_ITERATOR t##_CONSTLIST2_ITERATOR; \
  typedef const t* (t##_CONSTLIST2_FOREACH)(const t *element, void *user_data); \
  \
  decl t##_CONSTLIST2 *pr##_ConstList2_new(); \
  decl void pr##_ConstList2_free(t##_CONSTLIST2 *l); \
  decl void pr##_ConstList2_PushBack(t##_CONSTLIST2 *l, const t *p); \
  decl void pr##_ConstList2_PushFront(t##_CONSTLIST2 *l, const t *p); \
  decl const t *pr##_ConstList2_GetFront(const t##_CONSTLIST2 *l); \
  decl const t *pr##_ConstList2_GetBack(const t##_CONSTLIST2 *l); \
  decl unsigned int pr##_ConstList2_GetSize(const t##_CONSTLIST2 *l); \
  decl int pr##_ConstList2_IsEmpty(const t##_CONSTLIST2 *l); \
  decl void pr##_ConstList2_PopBack(t##_CONSTLIST2 *l); \
  decl void pr##_ConstList2_PopFront(t##_CONSTLIST2 *l); \
  decl void pr##_ConstList2_Clear(t##_CONSTLIST2 *l); \
  decl t##_CONSTLIST2_ITERATOR *pr##_ConstList2_First(const t##_CONSTLIST2 *l); \
  decl t##_CONSTLIST2_ITERATOR *pr##_ConstList2_Last(const t##_CONSTLIST2 *l); \
  decl t##_CONSTLIST2_ITERATOR *pr##_ConstList2Iterator_new(t##_CONSTLIST2 *l); \
  decl void pr##_ConstList2Iterator_free(t##_CONSTLIST2_ITERATOR *li); \
  decl const t *pr##_ConstList2Iterator_Previous(t##_CONSTLIST2_ITERATOR *li); \
  decl const t *pr##_ConstList2Iterator_Next(t##_CONSTLIST2_ITERATOR *li); \
  decl const t *pr##_ConstList2Iterator_Data(t##_CONSTLIST2_ITERATOR *li); \
  decl t##_CONSTLIST2_ITERATOR *pr##_ConstList2_FindIter(t##_CONSTLIST2 *l, const t *p); \
  decl const t *pr##_ConstList2_Contains(t##_CONSTLIST2 *l, const t *p); \
  decl void pr##_ConstList2_Remove(t##_CONSTLIST2 *l, const t *p); \
  decl const t *pr##_ConstList2_ForEach(t##_CONSTLIST2 *l, t##_CONSTLIST2_FOREACH, void *user_data);

  /* This macro should be used in applications, not in libraries. In
   * libraries please use the macro @ref
   * GWEN_CONSTLIST2_FUNCTION_LIB_DEFS. */
#define GWEN_CONSTLIST2_FUNCTION_DEFS(t, pr) \
  GWEN_CONSTLIST2_FUNCTION_LIB_DEFS(t, pr, GWEN_DUMMY_EMPTY_ARG)


#define GWEN_CONSTLIST2_FUNCTIONS(t, pr) \
  t##_CONSTLIST2 *pr##_ConstList2_new() { \
    return (t##_CONSTLIST2*)GWEN_ConstList_new(); \
  } \
  \
  void pr##_ConstList2_free(t##_CONSTLIST2 *l) { \
    GWEN_ConstList_free((GWEN_CONSTLIST*)l); \
  } \
  \
  void pr##_ConstList2_PushBack(t##_CONSTLIST2 *l, const t *p) { \
    GWEN_ConstList_PushBack((GWEN_CONSTLIST*) l, p); \
  } \
  \
  void pr##_ConstList2_PushFront(t##_CONSTLIST2 *l, const t *p) { \
    GWEN_ConstList_PushFront((GWEN_CONSTLIST*) l, p); \
  } \
  \
  const t *pr##_ConstList2_GetFront(const t##_CONSTLIST2 *l) { \
  return (t*) GWEN_ConstList_GetFront((const GWEN_CONSTLIST*) l); \
  }\
  \
  const t *pr##_ConstList2_GetBack(const t##_CONSTLIST2 *l) { \
  return (t*) GWEN_ConstList_GetBack((const GWEN_CONSTLIST*) l); \
  } \
  \
  \
  unsigned int pr##_ConstList2_GetSize(const t##_CONSTLIST2 *l){ \
    return GWEN_ConstList_GetSize((const GWEN_CONSTLIST*) l); \
  }\
  \
  int pr##_ConstList2_IsEmpty(const t##_CONSTLIST2 *l){ \
    return GWEN_ConstList_IsEmpty((const GWEN_CONSTLIST*) l); \
  }\
  \
  void pr##_ConstList2_PopBack(t##_CONSTLIST2 *l){ \
    GWEN_ConstList_PopBack((GWEN_CONSTLIST*) l); \
  }\
  \
  void pr##_ConstList2_PopFront(t##_CONSTLIST2 *l){ \
    GWEN_ConstList_PopFront((GWEN_CONSTLIST*) l); \
  }\
  \
  void pr##_ConstList2_Clear(t##_CONSTLIST2 *l){ \
    GWEN_ConstList_Clear((GWEN_CONSTLIST*) l); \
  }\
  \
  \
  t##_CONSTLIST2_ITERATOR *pr##_ConstList2_First(const t##_CONSTLIST2 *l) { \
    return (t##_CONSTLIST2_ITERATOR*) GWEN_ConstList_First((const GWEN_CONSTLIST*) l); \
  }\
  \
  t##_CONSTLIST2_ITERATOR *pr##_ConstList2_Last(const t##_CONSTLIST2 *l) { \
    return (t##_CONSTLIST2_ITERATOR*) GWEN_ConstList_Last((const GWEN_CONSTLIST*) l); \
  }\
  \
  t##_CONSTLIST2_ITERATOR *pr##_ConstList2Iterator_new(t##_CONSTLIST2 *l) { \
    return (t##_CONSTLIST2_ITERATOR*) GWEN_ConstListIterator_new((GWEN_CONSTLIST*) l); \
  }\
  \
  void pr##_ConstList2Iterator_free(t##_CONSTLIST2_ITERATOR *li) {\
    GWEN_ConstListIterator_free((GWEN_CONSTLIST_ITERATOR*)li); \
  } \
  \
  const t *pr##_ConstList2Iterator_Previous(t##_CONSTLIST2_ITERATOR *li) { \
    return (t*) GWEN_ConstListIterator_Previous((GWEN_CONSTLIST_ITERATOR*)li); \
  }\
  \
  const t *pr##_ConstList2Iterator_Next(t##_CONSTLIST2_ITERATOR *li) { \
    return (t*) GWEN_ConstListIterator_Next((GWEN_CONSTLIST_ITERATOR*)li); \
  }\
  \
  const t *pr##_ConstList2Iterator_Data(t##_CONSTLIST2_ITERATOR *li) { \
    return (t*) GWEN_ConstListIterator_Data((GWEN_CONSTLIST_ITERATOR*)li); \
  } \
  \
  t##_CONSTLIST2_ITERATOR *pr##_ConstList2_FindIter(t##_CONSTLIST2 *l, const t *p){ \
    return (t##_CONSTLIST2_ITERATOR*) GWEN_ConstList_FindIter((GWEN_CONSTLIST *)l, p); \
  } \
  \
  const t *pr##_ConstList2_Contains(t##_CONSTLIST2 *l, const t *p){ \
    return (const t*) GWEN_ConstList_Contains((GWEN_CONSTLIST*)l, p); \
  } \
  \
  void pr##_ConstList2_Remove(t##_CONSTLIST2 *l, const t *p){ \
    GWEN_ConstList_Remove((GWEN_CONSTLIST*) l, p); \
  } \
  \
  const t *pr##_ConstList2_ForEach(t##_CONSTLIST2 *l, t##_CONSTLIST2_FOREACH fn, void *user_data){ \
    t##_CONSTLIST2_ITERATOR *it; \
    const t *el; \
    if (!l) return 0; \
    \
    it=pr##_ConstList2_First(l); \
    if (!it) \
      return 0; \
    el=pr##_ConstList2Iterator_Data(it); \
    while(el) { \
      el=fn(el, user_data); \
      if (el) { \
        pr##_ConstList2Iterator_free(it); \
        return el; \
      } \
      el=pr##_ConstList2Iterator_Next(it); \
      } \
    pr##_ConstList2Iterator_free(it); \
    return 0; \
  }


#ifdef __cplusplus
}
#endif


#endif /* GWENHYWFAR_LIST2_H */



