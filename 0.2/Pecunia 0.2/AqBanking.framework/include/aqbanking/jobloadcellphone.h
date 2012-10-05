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


#ifndef AQBANKING_JOBLOADCELLPHONE_H
#define AQBANKING_JOBLOADCELLPHONE_H


#include <aqbanking/job.h>
#include <aqbanking/cellphoneproduct.h>
#include <aqbanking/value.h>

/** @addtogroup G_AB_JOBS_LOADCELLPHONE
 *
 */
/*@{*/

#ifdef __cplusplus
extern "C" {
#endif

/** @name Constructor */
/*@{*/
AQBANKING_API AB_JOB *AB_JobLoadCellPhone_new(AB_ACCOUNT *a);
/*@}*/


/** @name Job Arguments */
/*@{*/
AQBANKING_API void AB_JobLoadCellPhone_SetCellPhoneProduct(AB_JOB *j,
							   const AB_CELLPHONE_PRODUCT *p);

AQBANKING_API const AB_CELLPHONE_PRODUCT *AB_JobLoadCellPhone_GetCellPhoneProduct(const AB_JOB *j);
AQBANKING_API void AB_JobLoadCellPhone_SetPhoneNumber(AB_JOB *j, const char *n);
AQBANKING_API const char *AB_JobLoadCellPhone_GetPhoneNumber(const AB_JOB *j);

AQBANKING_API void AB_JobLoadCellPhone_SetValue(AB_JOB *j, const AB_VALUE *v);
AQBANKING_API const AB_VALUE *AB_JobLoadCellPhone_GetValue(const AB_JOB *j);
/*@}*/


/** @name Job Parameters */
/*@{*/
/** Returns a list of supported cell phone products (prepaid cards)
 * The jobs remains the owner of the object returned (if any)
 */
AQBANKING_API const AB_CELLPHONE_PRODUCT_LIST*
AB_JobLoadCellPhone_GetCellPhoneProductList(const AB_JOB *j);
/*@}*/

#ifdef __cplusplus
}
#endif

/*@}*/ /* addtogroup */


#endif

