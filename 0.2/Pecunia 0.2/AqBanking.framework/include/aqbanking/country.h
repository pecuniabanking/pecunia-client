/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_COUNTRY_H
#define AQBANKING_COUNTRY_H

#include <gwenhywfar/list2.h>
#include <aqbanking/error.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef struct AB_COUNTRY AB_COUNTRY;
GWEN_CONSTLIST2_FUNCTION_LIB_DEFS(AB_COUNTRY, AB_Country, AQBANKING_API)

#include <aqbanking/banking.h>

/**
 * Returns the untranslated name of the given country.
 */
AQBANKING_API 
const char *AB_Country_GetName(const AB_COUNTRY *cntry);

/**
 * Returns the ISO-3166-1 2-character code of the given country.
 */
AQBANKING_API 
const char *AB_Country_GetCode(const AB_COUNTRY *cntry);

/**
 * Returns the ISO-3166-1 numeric code of the given country.
 */
AQBANKING_API 
int AB_Country_GetNumericCode(const AB_COUNTRY *cntry);

/**
 * Returns a localized version of the name of the given country.
 * If no localized version is available (i.e. because there is no translation)
 * then the untranslated version is returned.
 */
AQBANKING_API 
const char *AB_Country_GetLocalName(const AB_COUNTRY *cntry);



/**
 * Returns the ISO 4217 name of the currency used in the given
 * country.
 */
AQBANKING_API 
const char *AB_Country_GetCurrencyName(const AB_COUNTRY *cntry);

/**
 * Returns the 3-character ISO 4217 code of the currency used in the given
 * country.
 */
AQBANKING_API 
const char *AB_Country_GetCurrencyCode(const AB_COUNTRY *cntry);

/**
 * Returns a localized version of the ISO 4217 name of the currency used in
 * the given country.
 */
AQBANKING_API 
const char *AB_Country_GetLocalCurrencyName(const AB_COUNTRY *cntry);



#ifdef __cplusplus
}
#endif


#endif /* AQBANKING_COUNTRY_H */
