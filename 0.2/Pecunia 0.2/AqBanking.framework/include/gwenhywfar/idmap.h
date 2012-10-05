/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
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

#ifndef GWENHYWFAR_IDMAP_H
#define GWENHYWFAR_IDMAP_H


#include <gwenhywfar/types.h>

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif


typedef struct GWEN_IDMAP GWEN_IDMAP;

typedef enum {
  GWEN_IdMapResult_Ok=0,
  GWEN_IdMapResult_NoFit,
  GWEN_IdMapResult_NotFound
} GWEN_IDMAP_RESULT;


typedef enum {
  GWEN_IdMapAlgo_Unknown=0,
  GWEN_IdMapAlgo_Hex4
} GWEN_IDMAP_ALGO;


/** @name Macros for Typesafe ID maps
 *
 */
/*@{*/
#ifndef GWEN_DUMMY_EMPTY_ARG
/** Necessary for MSVC compiler because it does not accept a left-out
    macro argument. */
# define GWEN_DUMMY_EMPTY_ARG
#endif


#define GWEN_IDMAP_FUNCTION_LIB_DEFS(t, pr, decl) \
  typedef GWEN_IDMAP t##_IDMAP;                                       \
                                                                      \
  decl t##_IDMAP *pr##_IdMap_new(GWEN_IDMAP_ALGO algo);               \
  decl void pr##_IdMap_free(t##_IDMAP *l);                            \
  decl void pr##_IdMap_freeAll(t##_IDMAP *l);                         \
  decl void pr##_IdMap_FreeItems(t##_IDMAP *l);                       \
  decl GWEN_IDMAP_RESULT pr##_IdMap_Insert(t##_IDMAP *l,              \
                                           uint32_t id,       \
                                           t* ptr);                   \
  decl GWEN_IDMAP_RESULT pr##_IdMap_Remove(t##_IDMAP *l,              \
                                           uint32_t id);      \
  decl t* pr##_IdMap_Find(t##_IDMAP *l, uint32_t id);         \
  decl GWEN_IDMAP_RESULT pr##_IdMap_GetFirst(const t##_IDMAP *map,    \
                                              uint32_t *pid); \
  decl GWEN_IDMAP_RESULT pr##_IdMap_GetNext(const t##_IDMAP *map,     \
                                             uint32_t *pid);  \
  decl uint32_t pr##_IdMap_GetSize(const GWEN_IDMAP *map);    \
  decl void pr##_IdMap_Clear(GWEN_IDMAP *l);


#define GWEN_IDMAP_FUNCTION_DEFS(t, pr) \
  GWEN_IDMAP_FUNCTION_LIB_DEFS(t, pr, GWEN_DUMMY_EMPTY_ARG)


#define GWEN_IDMAP_FUNCTIONS(t, pr) \
  t##_IDMAP *pr##_IdMap_new(GWEN_IDMAP_ALGO algo) {                  \
    return (t##_IDMAP*)GWEN_IdMap_new(algo);                         \
  }                                                                  \
                                                                     \
  void pr##_IdMap_free(t##_IDMAP *l) {                               \
    GWEN_IdMap_free((GWEN_IDMAP*)l);                                 \
  }                                                                  \
                                                                     \
  void pr##_IdMap_freeAll(t##_IDMAP *l) {                            \
    GWEN_IDMAP_RESULT res;                                           \
    uint32_t id;                                             \
					      		             \
    res=pr##_IdMap_GetFirst(l, &id);                                 \
    while(res==GWEN_IdMapResult_Ok) {                                \
      uint32_t nextId;                                       \
      t *ptr;                                                        \
								     \
      nextId=id;						     \
      res=pr##_IdMap_GetNext(l, &nextId);                            \
      ptr=pr##_IdMap_Find(l, id);                                    \
      if (ptr)                                                       \
	pr##_free(ptr);                                              \
      id=nextId;                                                     \
    }                                                                \
    pr##_IdMap_free(l);                                              \
  }                                                                  \
                                                                     \
  void pr##_IdMap_FreeItems(t##_IDMAP *l) {                          \
    GWEN_IDMAP_RESULT res;                                           \
    uint32_t id;                                             \
					      		             \
    res=pr##_IdMap_GetFirst(l, &id);                                 \
    while(res==GWEN_IdMapResult_Ok) {                                \
      uint32_t nextId;                                       \
      t *ptr;                                                        \
                                                                     \
      nextId=id;                                                     \
      res=pr##_IdMap_GetNext(l, &nextId);                            \
      ptr=pr##_IdMap_Find(l, id);                                    \
      if (ptr)                                                       \
	pr##_free(ptr);                                              \
      pr##_IdMap_Remove(l, id);          			     \
      id=nextId;                                                     \
    }                                                                \
  }                                                                  \
                                                                     \
  GWEN_IDMAP_RESULT pr##_IdMap_Insert(t##_IDMAP *l,                  \
                                      uint32_t id,           \
                                      t* ptr) {                      \
    return GWEN_IdMap_Insert((GWEN_IDMAP*)l, id, (void*) ptr);       \
  }                                                                  \
                                                                     \
  GWEN_IDMAP_RESULT pr##_IdMap_Remove(t##_IDMAP *l,                  \
                                      uint32_t id){          \
    return GWEN_IdMap_Remove((GWEN_IDMAP*)l, id);                    \
  }                                                                  \
\
  t* pr##_IdMap_Find(t##_IDMAP *l, uint32_t id) {            \
    return GWEN_IdMap_Find((GWEN_IDMAP*)l, id);                      \
  }                                                                  \
                                                                     \
  GWEN_IDMAP_RESULT pr##_IdMap_GetFirst(const t##_IDMAP *l,          \
                                        uint32_t *pid) {     \
    return GWEN_IdMap_GetFirst((const GWEN_IDMAP*)l, pid);           \
  }                                                                  \
                                                                     \
  GWEN_IDMAP_RESULT pr##_IdMap_GetNext(const t##_IDMAP *l,           \
                                       uint32_t *pid) {      \
    return GWEN_IdMap_GetNext((const GWEN_IDMAP*)l, pid);            \
  }                                                                  \
                                                                     \
  uint32_t pr##_IdMap_GetSize(const GWEN_IDMAP *l) {         \
    return GWEN_IdMap_GetSize((const GWEN_IDMAP*)l);                 \
  }                                                                  \
                                                                     \
  void pr##_IdMap_Clear(GWEN_IDMAP *l) {                             \
    GWEN_IdMap_Clear((GWEN_IDMAP*)l);                                \
  }
/*@}*/



GWENHYWFAR_API
GWEN_IDMAP *GWEN_IdMap_new(GWEN_IDMAP_ALGO algo);

GWENHYWFAR_API
void GWEN_IdMap_free(GWEN_IDMAP *map);

GWENHYWFAR_API
GWEN_IDMAP_RESULT GWEN_IdMap_Insert(GWEN_IDMAP *map,
				    uint32_t id,
				    void *ptr);

GWENHYWFAR_API
GWEN_IDMAP_RESULT GWEN_IdMap_Remove(GWEN_IDMAP *map,
                                    uint32_t id);

GWENHYWFAR_API
void *GWEN_IdMap_Find(GWEN_IDMAP *map, uint32_t id);


/**
 * Return the first id in the map.
 * @param map map to browse
 * @param pid pointer to a variable to receive the first id in the map.
 *   Upon return this variable will be updated to the first id in the map if
 *   the result is @ref GWEN_IdMapResult_Ok.
 */
GWENHYWFAR_API
GWEN_IDMAP_RESULT GWEN_IdMap_GetFirst(const GWEN_IDMAP *map,
                                      uint32_t *pid);

/**
 * Return the next id in the map.
 * @param map map to browse
 * @param pid pointer to the id retrieved via @ref GWEN_IdMap_GetFirst.
 *   Upon return this variable will be updated to the next id in the map if
 *   the result is @ref GWEN_IdMapResult_Ok.
 */
GWENHYWFAR_API
GWEN_IDMAP_RESULT GWEN_IdMap_GetNext(const GWEN_IDMAP *map,
                                     uint32_t *pid);

GWENHYWFAR_API
uint32_t GWEN_IdMap_GetSize(const GWEN_IDMAP *map);

GWENHYWFAR_API
void GWEN_IdMap_Clear(GWEN_IDMAP *map);


GWENHYWFAR_API
void GWEN_IdMap_Dump(GWEN_IDMAP *map, FILE *f, int indent);


#ifdef __cplusplus
}
#endif


#endif

