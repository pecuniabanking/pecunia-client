/***************************************************************************
 begin       : Sat Jun 28 2003
 copyright   : (C) 2003-2010 by Martin Preuss
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

/** @file src/base/misc.h
 *
 * @short This file contains some macros concerning lists and inheritance.
 *
 * <p>
 * FIRST: Yes, I DO know, macros are very, very bad.
 * When writing these macros I spent much time debugging them, because the
 * compiler is not much of a help here.
 * The validity of a macro is only checked upon invocation,
 * so if you never use a macro it will never be checked.
 * </p>
 * <p>
 * However, these macros do work just fine and they make some tasks
 * much easier to handle.
 * </p>
 * <p>
 * The reason for using macros is the lack of templates in C.
 * When writing Gwenhywfar I often faced the fact that some functions always
 * appear with many structs defined. The only difference is the name of those
 * functions and the type of the arguments.
 * </p>
 * <p>
 * The best example is the handling of lists of structs.
 * In most listable structs there was a variable called @b next which pointed
 * to the next object in the list. There were also functions like TYPE_next(),
 * TYPE_add(), TYPE_del() etc for list handling. Whenever I improved the list
 * mechanism I had to change ALL code files in order to improve them all.
 * </p>
 * <p>
 * These macros are now used to facilitate improvements in list or inheritance
 * handling code in C.
 * </p>
 * <p>
 * @b NOTE: Please do not change these macros unless you know exactly what you
 * are doing!
 * Bugs in the macros will most probably lead to nearly undebuggable results
 * in code files using them.<br>
 * You have been warned ;-)
 * </p>
 *
 */

#ifndef GWENHYWFAR_MISC_H
#define GWENHYWFAR_MISC_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


#ifdef __cplusplus
extern "C" {
#endif

#define GWEN_LIST_ADD(typ, sr, head) {\
  typ *curr;                \
                            \
  assert(sr);               \
                            \
  curr=*head;               \
  if (!curr) {              \
    *head=sr;               \
  }                         \
  else {                    \
    while(curr->next) {     \
      curr=curr->next;      \
    }                       \
    curr->next=sr;          \
  }\
  }


#define GWEN_LIST_INSERT(typ, sr, head) {\
  typ *curr;                \
                            \
  assert(sr);               \
                            \
  curr=*head;               \
  if (!curr) {              \
    *head=sr;               \
  }                         \
  else {                    \
    sr->next=curr;\
    *head=sr;\
  }\
  }


#define GWEN_LIST_DEL(typ, sr, head) {\
  typ *curr;                   \
                               \
  assert(sr);                  \
  curr=*head;                  \
  if (curr) {                  \
    if (curr==sr) {            \
      *head=curr->next;        \
    }                          \
    else {                     \
      while(curr->next!=sr) {  \
	curr=curr->next;       \
      }                        \
      if (curr)                \
	curr->next=sr->next;   \
    }                          \
  }                            \
  sr->next=0;\
  }



  /*@}*/ /* defgroup */

#ifdef __cplusplus
}
#endif


#include <gwenhywfar/memory.h>
#include <gwenhywfar/list1.h>




#endif



