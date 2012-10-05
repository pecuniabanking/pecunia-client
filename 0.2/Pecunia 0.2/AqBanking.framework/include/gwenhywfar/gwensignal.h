/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id: stringlist_p.h 786 2005-07-09 13:38:17Z aquamaniac $
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

#ifndef GWENHYWFAR_SIGNAL_H
#define GWENHYWFAR_SIGNAL_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/list2.h>


#ifdef __cplusplus
extern "C" {
#endif

/**
 * @defgroup MOD_SIGNALSLOT Module for Signals and Slots
 * @ingroup MOD_BASE
 * @short Basic signal handling.
 *
 * This module introduces a simple signal-slot framework.
 * Signals have a fixed list of arguments:
 * <ul>
 *   <li>a void* pointer</li>
 *   <li>1st integer argument</li>
 *   <li>2nd integer argument</li>
 * </ul>
 * The actual type of the void pointer is defined by the signal and
 * corresponding slot(s): Gwen checks the type at runtime and refuses to
 * connect signals with slots which define this pointer to be of a different
 * type.
 * Any signal can be connected to any number of matching slots.
 *
 * The central object in this framework is @ref GWEN_SIGNALOBJECT. It holds
 * a list of signals and slots for a given object.
 *
 *
 */
/*@{*/

typedef struct GWEN_SIGNALOBJECT GWEN_SIGNALOBJECT;

typedef struct GWEN_SIGNAL GWEN_SIGNAL;

typedef struct GWEN_SLOT GWEN_SLOT;


/**
 * This is the prototype for the slot function. If there is a problem in the
 * function it should return 1, otherwise 0.
 */
typedef int (*GWEN_SLOT_FUNCTION)(GWEN_SLOT *slot,
                                  void *userData,
                                  void *pArg1,
                                  void *pArg2,
                                  int iArg3,
                                  int iArg4);


/** @name SignalObject
 *
 */
/*@{*/
GWENHYWFAR_API
GWEN_SIGNALOBJECT *GWEN_SignalObject_new();

GWENHYWFAR_API
void GWEN_SignalObject_free(GWEN_SIGNALOBJECT *so);

GWENHYWFAR_API
GWEN_SIGNAL *GWEN_SignalObject_FindSignal(const GWEN_SIGNALOBJECT *so,
                                          const char *name,
                                          const char *typeOfArg1,
                                          const char *typeOfArg2);

GWENHYWFAR_API
GWEN_SLOT *GWEN_SignalObject_FindSlot(const GWEN_SIGNALOBJECT *so,
                                      const char *name,
                                      const char *typeOfArg1,
                                      const char *typeOfArg2);

/**
 * This function removes all signals and slots for the given derived
 * type. This function can be used from within the FREEDATA function
 * of the GWEN_INHERIT framework.
 */
GWENHYWFAR_API
void GWEN_SignalObject_RemoveForDerivedType(GWEN_SIGNALOBJECT *so,
                                            const char *derivedType);


/**
 * @defgroup MOD_SIGNALSLOT_SIGNAL Signals
 * @short Signals
 *
 */
/*@{*/

GWENHYWFAR_API
GWEN_SIGNAL *GWEN_Signal_new(GWEN_SIGNALOBJECT *so,
                             const char *derivedType,
                             const char *name,
                             const char *typeOfArg1,
                             const char *typeOfArg2);

GWENHYWFAR_API
void GWEN_Signal_free(GWEN_SIGNAL *sig);


GWENHYWFAR_API
GWEN_SIGNALOBJECT *GWEN_Signal_GetSignalObject(const GWEN_SIGNAL *sig);


GWENHYWFAR_API
int GWEN_Signal_Connect(GWEN_SIGNAL *sig, GWEN_SLOT *slot);

GWENHYWFAR_API
int GWEN_Signal_Disconnect(GWEN_SIGNAL *sig, GWEN_SLOT *slot);

/**
 * This function calls the slot function of all connected slots.
 * If any of the slot functions called returns with code 1 then
 * this function will return 1, too. Otherwise 0 is returned.
 * This means that this function will only return 0 if every called slot
 * function returns 0.
 */
GWENHYWFAR_API
int GWEN_Signal_Emit(GWEN_SIGNAL *sig,
                     void *pArg1, void *pArg2, int iArg3, int iArg4);
/*@}*/


/**
 * @defgroup MOD_SIGNALSLOT_SLOT Slots
 * @short Slots
 *
 */
/*@{*/

GWENHYWFAR_API
GWEN_SLOT *GWEN_Slot_new(GWEN_SIGNALOBJECT *so,
                         const char *derivedType,
                         const char *name,
                         const char *typeOfArg1,
                         const char *typeOfArg2,
                         GWEN_SLOT_FUNCTION fn,
                         void *userData);

GWENHYWFAR_API
void GWEN_Slot_free(GWEN_SLOT *slot);

GWENHYWFAR_API
GWEN_SIGNALOBJECT *GWEN_Slot_GetSignalObject(const GWEN_SLOT *slot);


/*@}*/ /* defgroup */


/*@}*/ /* defgroup */



#ifdef __cplusplus
} /* extern C */
#endif


#endif

