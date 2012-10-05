/***************************************************************************
    begin       : Mon Jul 14 2008
    copyright   : (C) 2008 by Martin Preuss
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

#ifndef GWENHYWFAR_MEMCACHE_H
#define GWENHYWFAR_MEMCACHE_H


#include <gwenhywfar/gwenhywfarapi.h>

#include <time.h>
#include <inttypes.h>



typedef struct GWEN_MEMCACHE_ENTRY GWEN_MEMCACHE_ENTRY;

typedef struct GWEN_MEMCACHE GWEN_MEMCACHE;


GWENHYWFAR_API 
void GWEN_MemCacheEntry_free(GWEN_MEMCACHE_ENTRY *me);

GWENHYWFAR_API 
uint32_t GWEN_MemCacheEntry_GetId(GWEN_MEMCACHE_ENTRY *me);


GWENHYWFAR_API
void *GWEN_MemCacheEntry_GetDataPtr(GWEN_MEMCACHE_ENTRY *me);

GWENHYWFAR_API 
size_t GWEN_MemCacheEntry_GetDataLen(GWEN_MEMCACHE_ENTRY *me);

GWENHYWFAR_API 
int GWEN_MemCacheEntry_GetIsValid(const GWEN_MEMCACHE_ENTRY *me);

GWENHYWFAR_API 
void GWEN_MemCacheEntry_BeginUse(GWEN_MEMCACHE_ENTRY *me);

GWENHYWFAR_API 
void GWEN_MemCacheEntry_EndUse(GWEN_MEMCACHE_ENTRY *me);




GWENHYWFAR_API 
GWEN_MEMCACHE *GWEN_MemCache_new(size_t maxCacheMemory,
				 uint32_t maxCacheEntries);

GWENHYWFAR_API 
void GWEN_MemCache_free(GWEN_MEMCACHE *mc);


/**
 * Returns the cache entry with the given id (if any).
 * If NULL is returned then there is no entry with the given id,
 * otherwise the use counter of the object returned is incremented.
 * Therefore the caller has to call @ref GWEN_MemCacheEntry_EndUse
 * after working with the object returned in order to release unused
 * cache entries.
 */
GWENHYWFAR_API 
GWEN_MEMCACHE_ENTRY *GWEN_MemCache_FindEntry(GWEN_MEMCACHE *mc,
					     uint32_t id);

/**
 * Creates a cache entry for the given id. If there already is an entry
 * of the given id that existing entry will first be invalidated.
 * The use counter of the new object returned is 1, so the caller must
 * call @ref GWEN_MemCacheEntry_EndUse after working with the object returned in
 * order to release unused cache entries.
 */
GWENHYWFAR_API 
GWEN_MEMCACHE_ENTRY *GWEN_MemCache_CreateEntry(GWEN_MEMCACHE *mc,
					       uint32_t id,
					       void *dataPtr,
					       size_t dataLen);

/**
 * This function invalidates a given cache entry (if it exists).
 * The data associated with that entry is not freed yet until all
 * users of that entry called @ref GWEN_MemCacheEntry_EndUse (i.e.
 * until the use counter of that entry reaches zero). However, the
 * entry will be removed from the cache index so that future calls
 * to @ref GWEN_MemCache_FindEntry will not return it.
 */
GWENHYWFAR_API 
void GWEN_MemCache_PurgeEntry(GWEN_MEMCACHE *mc,
			      uint32_t id);

/**
 * This function invalidates all entries whose ids match the given
 * id/mask pair. See @ref GWEN_MemCache_PurgeEntry for implementation
 * details and caveats.
 */
GWENHYWFAR_API 
void GWEN_MemCache_PurgeEntries(GWEN_MEMCACHE *mc,
				uint32_t id, uint32_t mask);

/**
 * This function invalidates all cache entries.
 * See @ref GWEN_MemCache_PurgeEntry for implementation
 * details and caveats.
 */
GWENHYWFAR_API 
void GWEN_MemCache_Purge(GWEN_MEMCACHE *mc);





#endif
