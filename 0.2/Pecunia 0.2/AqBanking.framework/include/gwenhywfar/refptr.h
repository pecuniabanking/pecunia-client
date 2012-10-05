/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Sun Jan 25 2004
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


#ifndef GWEN_REFPTR_H
#define GWEN_REFPTR_H


#include <gwenhywfar/types.h>
#include <gwenhywfar/gwenhywfarapi.h>


#define GWEN_REFPTR_FLAGS_AUTODELETE 0x00000001


#ifdef __cplusplus
extern "C" {
#endif

typedef struct GWEN_REFPTR_INFO GWEN_REFPTR_INFO;
typedef struct GWEN_REFPTR GWEN_REFPTR;


/** @defgroup MOD_REFPTR Pointer with Reference Counter
 * @ingroup MOD_BASE
 *
 * @brief This file contains functions which implement a smart pointer.
 *
 */
/*@{*/

/** @defgroup MOD_REFPTR_PTR Pointer Functions
 * @ingroup MOD_REFPTR
 *
 * @brief This group contains the definition of a GWEN_REFPTR.
 *
 */
/*@{*/


/** @name Constructor, Destructor, Copy, Duplicate functions
 *
 */
/*@{*/
GWENHYWFAR_API
GWEN_REFPTR *GWEN_RefPtr_new(void *dp, GWEN_REFPTR_INFO *rpi);
GWENHYWFAR_API
GWEN_REFPTR *GWEN_RefPtr_dup(const GWEN_REFPTR *rp);
GWENHYWFAR_API
GWEN_REFPTR *GWEN_RefPtr_copy(const GWEN_REFPTR *rp);
GWENHYWFAR_API
void GWEN_RefPtr_free(GWEN_REFPTR *rp);
/*@}*/

/** @name Data Functions
 *
 */
/*@{*/
GWENHYWFAR_API
void *GWEN_RefPtr_GetData(const GWEN_REFPTR *rp);
GWENHYWFAR_API
void GWEN_RefPtr_SetData(GWEN_REFPTR *rp, void *dp, GWEN_REFPTR_INFO *rpi);
/*@}*/


/** @name Getting and Setting Flags
 *
 */
/*@{*/
GWENHYWFAR_API
uint32_t GWEN_RefPtr_GetFlags(const GWEN_REFPTR *rp);
GWENHYWFAR_API
void GWEN_RefPtr_SetFlags(GWEN_REFPTR *rp, uint32_t fl);
GWENHYWFAR_API
void GWEN_RefPtr_AddFlags(GWEN_REFPTR *rp, uint32_t fl);
GWENHYWFAR_API
void GWEN_RefPtr_DelFlags(GWEN_REFPTR *rp, uint32_t fl);
/*@}*/

/*@}*/ /* defgroup */



/** @defgroup MOD_REFPTR_INFO Pointer Information Functions
 * @ingroup MOD_REFPTR
 *
 * @brief This group contains the definition of a GWEN_REFPTR_INFO object.
 *
 */
/*@{*/

/** @name Constructor, Destructor, Copy, Duplicate functions
 *
 */
/*@{*/
GWENHYWFAR_API
GWEN_REFPTR_INFO *GWEN_RefPtrInfo_new();
GWENHYWFAR_API
void GWEN_RefPtrInfo_free(GWEN_REFPTR_INFO *rpi);
GWENHYWFAR_API
void GWEN_RefPtrInfo_Attach(GWEN_REFPTR_INFO *rpi);
/*@}*/


/** @name Getting and Setting Flags
 *
 * These flags are used for newly created GWEN_REFPTR to provide a
 * default value. Please see @ref GWEN_REFPTR_FLAGS_AUTODELETE and
 * following.
 */
/*@{*/
GWENHYWFAR_API
uint32_t GWEN_RefPtrInfo_GetFlags(const GWEN_REFPTR_INFO *rpi);
GWENHYWFAR_API
void GWEN_RefPtrInfo_SetFlags(GWEN_REFPTR_INFO *rpi, uint32_t fl);
GWENHYWFAR_API
void GWEN_RefPtrInfo_AddFlags(GWEN_REFPTR_INFO *rpi, uint32_t fl);
GWENHYWFAR_API
void GWEN_RefPtrInfo_DelFlags(GWEN_REFPTR_INFO *rpi, uint32_t fl);
/*@}*/


/** @name Prototypes for Virtual Functions
 *
 */
/*@{*/
typedef void (*GWEN_REFPTR_INFO_FREE_FN)(void *dp);
typedef void* (*GWEN_REFPTR_INFO_DUP_FN)(void *dp);
/*@}*/


/** @name Setters for Virtual Functions
 *
 */
/*@{*/
GWENHYWFAR_API
void GWEN_RefPtrInfo_SetFreeFn(GWEN_REFPTR_INFO *rpi,
                               GWEN_REFPTR_INFO_FREE_FN f);
GWENHYWFAR_API
void GWEN_RefPtrInfo_SetDupFn(GWEN_REFPTR_INFO *rpi,
                              GWEN_REFPTR_INFO_DUP_FN f);

/*@}*/


/*@}*/ /* defgroup */

/*@}*/ /* defgroup */

#ifdef __cplusplus
}
#endif


#endif
