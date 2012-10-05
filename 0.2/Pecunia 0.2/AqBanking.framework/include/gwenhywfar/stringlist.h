/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Thu Apr 03 2003
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

#ifndef GWENHYWFAR_STRINGLIST_H
#define GWENHYWFAR_STRINGLIST_H

#include <gwenhywfar/gwenhywfarapi.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef enum {
  /** case-insensitive, i.e. using strcasecmp(3). */
  GWEN_StringList_SortModeNoCase=0,
  /** case-sensitive, i.e. using strcmp(3). */
  GWEN_StringList_SortModeCase,
  /** handle string list entries as integers (-> correct sorting of ASCII
   * coded values like "10", "1") */
  GWEN_StringList_SortModeInt
} GWEN_STRINGLIST_SORT_MODE;


typedef struct GWEN_STRINGLISTENTRYSTRUCT GWEN_STRINGLISTENTRY;


typedef struct GWEN_STRINGLISTSTRUCT GWEN_STRINGLIST;


GWENHYWFAR_API GWEN_STRINGLIST *GWEN_StringList_new();

GWENHYWFAR_API GWEN_STRINGLIST *GWEN_StringList_fromTabString(const char *s, int checkDup);

GWENHYWFAR_API void GWEN_StringList_free(GWEN_STRINGLIST *sl);
GWENHYWFAR_API
  GWEN_STRINGLIST *GWEN_StringList_dup(const GWEN_STRINGLIST *sl);
GWENHYWFAR_API void GWEN_StringList_Clear(GWEN_STRINGLIST *sl);

/** Returns the number of elements in this list. */
GWENHYWFAR_API
  unsigned int GWEN_StringList_Count(const GWEN_STRINGLIST *sl);

GWENHYWFAR_API GWEN_STRINGLISTENTRY *GWEN_StringListEntry_new(const char *s,
                                                              int take);
GWENHYWFAR_API void GWEN_StringListEntry_ReplaceString(GWEN_STRINGLISTENTRY *e,
                                                       const char *s,
                                                       int take);
GWENHYWFAR_API void GWEN_StringListEntry_free(GWEN_STRINGLISTENTRY *sl);
GWENHYWFAR_API void GWEN_StringList_AppendEntry(GWEN_STRINGLIST *sl,
                                                GWEN_STRINGLISTENTRY *se);
GWENHYWFAR_API void GWEN_StringList_RemoveEntry(GWEN_STRINGLIST *sl,
                                                GWEN_STRINGLISTENTRY *se);
GWENHYWFAR_API
  GWEN_STRINGLISTENTRY *GWEN_StringList_FirstEntry(const GWEN_STRINGLIST *sl);
GWENHYWFAR_API
  GWEN_STRINGLISTENTRY *GWEN_StringListEntry_Next(const GWEN_STRINGLISTENTRY *se);

GWENHYWFAR_API
  const char *GWEN_StringListEntry_Data(const GWEN_STRINGLISTENTRY *se);

GWENHYWFAR_API
  void GWEN_StringListEntry_SetData(GWEN_STRINGLISTENTRY *se,
                                    const char *s);

/**
 * Normally this group of functions ignores cases when comparing two strings.
 * You can change this behaviour here.
 * @param sl string list
 * @param i if 0 then cases are ignored
 */
GWENHYWFAR_API
void GWEN_StringList_SetSenseCase(GWEN_STRINGLIST *sl, int i);

/**
 * Normally this group of functions ignores reference counters on stringlist
 * entries when removing a string via @ref GWEN_StringList_RemoveString.
 * You can change this behaviour here.
 * @param sl string list
 * @param i if 0 then reference counters are honoured
 */
GWENHYWFAR_API
void GWEN_StringList_SetIgnoreRefCount(GWEN_STRINGLIST *sl, int i);

/**
 * Appends a string.
 * @return 0 if not appended, !=0 if appended
 * @param take if true then the StringList takes over ownership of the string
 * @param checkDouble if true the the string will only be appended if it
 * does not already exist
 */
GWENHYWFAR_API int GWEN_StringList_AppendString(GWEN_STRINGLIST *sl,
                                                const char *s,
                                                int take,
                                                int checkDouble);

/**
 * Inserts a string.
 * @return 0 if not inserted, !=0 if inserted
 * @param take if true then the StringList takes over ownership of the string
 * @param checkDouble if true the the string will only be appended if it
 * does not already exist
 */
GWENHYWFAR_API int GWEN_StringList_InsertString(GWEN_STRINGLIST *sl,
                                                const char *s,
                                                int take,
                                                int checkDouble);

/**
 * Removes a given string from the stringlist.
 * @return 0 if not found, !=0 if found and removed
 */
GWENHYWFAR_API int GWEN_StringList_RemoveString(GWEN_STRINGLIST *sl,
                                                const char *s);

/**
 * Checks whether the given string already exists within in the
 * string list.
 * @return !=0 if found, 0 otherwise
 */
GWENHYWFAR_API int GWEN_StringList_HasString(const GWEN_STRINGLIST *sl,
                                             const char *s);

/**
 * Returns the position of the given string within the stringlist.
 *
 * @return position, -1 if not found
 */
GWENHYWFAR_API int GWEN_StringList_GetStringPos(const GWEN_STRINGLIST *sl, const char *s);


/** Traverses the list, calling the callback function 'func' on
 * each list element.  Traversal will stop when 'func' returns a
 * non-NULL value, and the routine will return with that
 * value. Otherwise the routine will return NULL. 
 * @param l The list to traverse.
 * @param func The function to be called with each list element.
 * @param user_data A pointer passed on to the function 'func'.
 * @return The non-NULL pointer returned by 'func' as soon as it
 * returns one. Otherwise (i.e. 'func' always returns NULL)
 * returns NULL.
 */
GWENHYWFAR_API
void *GWEN_StringList_ForEach(const GWEN_STRINGLIST *l, 
			      void *(*func)(const char *s, void *u), 
			      void *user_data);

/** Returns the first string in this list. */
GWENHYWFAR_API
const char *GWEN_StringList_FirstString(const GWEN_STRINGLIST *l);

GWENHYWFAR_API
const char *GWEN_StringList_StringAt(const GWEN_STRINGLIST *l, int idx);


/** Sorts this list. Internally this uses qsort(3), so the sorting
 * should be reasonably fast even for large lists.
 *
 * @param l The list to sort.
 *
 * @param ascending If non-zero, the list is sorted ascending,
 * i.e. smallest string first, according to strcmp(3) rules. If zero,
 * the list is sorted descending.
 *
 * @param sortMode See @ref GWEN_StringList_SortModeNoCase and following
 */
GWENHYWFAR_API
void GWEN_StringList_Sort(GWEN_STRINGLIST *l,
                          int ascending,
                          GWEN_STRINGLIST_SORT_MODE sortMode);

GWENHYWFAR_API
GWEN_STRINGLIST *GWEN_StringList_fromString(const char *str, const char *delimiters, int checkDouble);

#ifdef __cplusplus
}
#endif

#endif


