/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004 by Martin Preuss
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

/** @file idlist.h
 * @short A list of uint32_t objects
 */


#ifndef GWENHYWFAR_IDLIST_H
#define GWENHYWFAR_IDLIST_H

#ifdef __cplusplus
extern "C" {
#endif
typedef struct GWEN_IDLIST GWEN_IDLIST;
#ifdef __cplusplus
}
#endif

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @defgroup MOD_IDLIST ID list module
 * @ingroup MOD_BASE
 * @short A list of uint32_t objects
 *
 * This is basically a list for uint32_t objects,
 * but since it uses tables instead of those list objects normally used
 * throughout Gwen it is less memory consuming.
 */
/*@{*/
/**
 * Constructor.
 */
GWENHYWFAR_API
GWEN_IDLIST *GWEN_IdList_new();

/**
 * Destructor.
 */
GWENHYWFAR_API
void GWEN_IdList_free(GWEN_IDLIST *idl);


/**
 * Returns a new id list which contains all the ids of the given list
 * in the same order. However, the list returned is compact (i.e. it has no
 * wholes).
 */
GWENHYWFAR_API
GWEN_IDLIST *GWEN_IdList_dup(const GWEN_IDLIST *idl);


/**
 * Removes all ids from the list thus leaving it empty.
 */
GWENHYWFAR_API
void GWEN_IdList_Clear(GWEN_IDLIST *idl);

/**
 * Adds an id to the list. This function does no doublecheck.
 */
GWENHYWFAR_API
int GWEN_IdList_AddId(GWEN_IDLIST *idl, uint32_t id);

/**
 * Removes the first occurrence of the given id.
 * @return 0 if deleted, !=0 if the id wasn't found
 */
GWENHYWFAR_API
int GWEN_IdList_DelId(GWEN_IDLIST *idl, uint32_t id);

/**
 * Checks whether the given id exists in the idlist.
 * @return 0 if found, !=0 otherwise
 */
GWENHYWFAR_API
int GWEN_IdList_HasId(const GWEN_IDLIST *idl, uint32_t id);

/**
 * Returns the first id from the list.
 */
GWENHYWFAR_API
uint32_t GWEN_IdList_GetFirstId(GWEN_IDLIST *idl);

GWENHYWFAR_API
uint32_t GWEN_IdList_GetNextId(GWEN_IDLIST *idl);

/**
 * This function returns the first id stored in the list. It can also
 * be used with const GWEN_IDLIST.
 * @param hdl pointer to a 32 bit value to receive a handle
 *   to be used by @ref GWEN_IdList_GetNextId2. This handle is only valid
 *   as longs as no ids are removed from the list.
 */
GWENHYWFAR_API
uint32_t GWEN_IdList_GetFirstId2(const GWEN_IDLIST *idl,
                                         uint32_t *hdl);

/**
 * This function returns the next id stored in the list. It can also
 * be used with const GWEN_IDLIST.
 * @param hdl pointer to a 32 bit value to receive a handle
 *   to be used by @ref GWEN_IdList_GetNextId2. This handle is only valid
 *   as longs as no ids are removed from the list.
 */
GWENHYWFAR_API
uint32_t GWEN_IdList_GetNextId2(const GWEN_IDLIST *idl,
                                        uint32_t *hdl);


/**
 * Sorts the ids in ascending order
 */
GWENHYWFAR_API
int GWEN_IdList_Sort(GWEN_IDLIST *idl);

/*@}*/


#ifdef __cplusplus
}
#endif


#endif /* GWENHYWFAR_IDLIST_H */


