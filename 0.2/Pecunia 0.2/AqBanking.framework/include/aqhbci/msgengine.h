/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef AH_MSGENGINE_H
#define AH_MSGENGINE_H

/** @defgroup G_AB_BE_AQHBCI_MSGENGINE HBCI Message Engine
 * @ingroup G_AB_BE_AQHBCI
 * @short HBCI-specific message engine extension
 * @author Martin Preuss<martin@libchipcard.de>
 *
 * This is an extension for @ref GWEN_MSGENGINE which additionally supports
 * some HBCI types (like date, time, DTAUS binary type, SWIFT binary type
 * etc).
 * It is used by AqHBCI internally and by the tool hbcixml2.
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif
typedef struct AH_MSGENGINE AH_MSGENGINE;
#ifdef __cplusplus
}
#endif

#include <aqhbci/aqhbci.h>
#include <aqbanking/user.h>
#include <gwenhywfar/msgengine.h>

#ifdef __cplusplus
extern "C" {
#endif

AQHBCI_API
GWEN_MSGENGINE *AH_MsgEngine_new();


#ifdef __cplusplus
}
#endif

/*@}*/


#endif /* AH_MSGENGINE_H */

