/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id: jobgetbalance.h 1137 2007-01-19 19:48:38Z martin $
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_JOBLOADCELLPHONE_BE_H
#define AQBANKING_JOBLOADCELLPHONE_BE_H


#include <aqbanking/jobloadcellphone.h>

/** @addtogroup G_AB_JOBS_LOADCELLPHONE
 *
 */
/*@{*/

#ifdef __cplusplus
extern "C" {
#endif

/** @name Backend Functions
 *
 * Functions in this group are only to be called by banking backends.
 */
/*@{*/
/**
 * Set the list of supported cellphone prepaid card products. The list given MUST NOT be empty!
 * If you want to state that no products are supported use NULL as argument.
 * The jobs becomes the owner of the lst given (if any).
 */

AQBANKING_API void AB_JobLoadCellPhone_SetProductList(AB_JOB *j, AB_CELLPHONE_PRODUCT_LIST *l);

/*@}*/

#ifdef __cplusplus
}
#endif

/*@}*/ /* addtogroup */


#endif

