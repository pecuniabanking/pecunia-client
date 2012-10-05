/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Mon Apr 05 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AB_VALUE_H
#define AB_VALUE_H

#include <gwenhywfar/buffer.h>
#include <gwenhywfar/db.h>
#include <gwenhywfar/list.h>
#include <gwenhywfar/types.h>

#include <aqbanking/error.h>

#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif

typedef struct AB_VALUE AB_VALUE;
GWEN_LIST_FUNCTION_LIB_DEFS(AB_VALUE, AB_Value, AQBANKING_API)

/** Creates a deep copy of an AB_VALUE_LIST object
 *
 */
AQBANKING_API AB_VALUE_LIST *AB_Value_List_dup(const AB_VALUE_LIST *vl);


AQBANKING_API AB_VALUE *AB_Value_new(void);
AQBANKING_API AB_VALUE *AB_Value_dup(const AB_VALUE *ov);
AQBANKING_API void AB_Value_free(AB_VALUE *v);

/**
 * This function reads a AB_VALUE from a string. Strings suitable as
 * arguments are those created by @ref AB_Value_toString or simple
 * floating point string (as in "123.45" or "-123.45").
 */
AQBANKING_API AB_VALUE *AB_Value_fromString(const char *s);

/**
 * This function exports the value in a format which can be recognized
 * by the function @ref AB_Value_fromString. You should not make any
 * assumption about the format of the string created here.
 */
AQBANKING_API void AB_Value_toString(const AB_VALUE *v, GWEN_BUFFER *buf);

AQBANKING_API void AB_Value_toHumanReadableString(const AB_VALUE *v,
						  GWEN_BUFFER *buf,
						  int prec);

AQBANKING_API void AB_Value_toHumanReadableString2(const AB_VALUE *v,
						   GWEN_BUFFER *buf,
						   int prec,
						   int withCurrency);

AQBANKING_API AB_VALUE *AB_Value_fromDouble(double i);


/** Create a value from the given GWEN_DB. */
AQBANKING_API AB_VALUE *AB_Value_fromDb(GWEN_DB_NODE *db);

/** Write the given value into the given GWEN_DB. */
AQBANKING_API int AB_Value_toDb(const AB_VALUE *v, GWEN_DB_NODE *db);

/** Write the given value into the given GWEN_DB (uses float instead of rational). */
AQBANKING_API int AB_Value_toDbFloat(const AB_VALUE *v, GWEN_DB_NODE *db);

/**
 * This function returns the value as a double.
 * You should not feed another AB_VALUE from this double, because the
 * conversion from an AB_VALUE to a double might be lossy!
 */
AQBANKING_API double AB_Value_GetValueAsDouble(const AB_VALUE *v);


/**
 * You should not use a double retrieved via
 * @ref AB_Value_GetValueAsDouble as an argument to this function, because
 * the conversion from AB_VALUE to double to AB_VALUE might change the
 * real value.
 */
AQBANKING_API void AB_Value_SetValueFromDouble(AB_VALUE *v, double i);

/**
 * Write the value (without the currency) in nominator/denominator
 * form into the given buffer if possibly.
 * This form looks like "12345/6789" (nominator/denominator).
 */
AQBANKING_API int AB_Value_GetNumDenomString(const AB_VALUE *v,
					     char *buffer,
					     uint32_t buflen);

AQBANKING_API void AB_Value_SetZero(AB_VALUE *v);

AQBANKING_API int AB_Value_IsZero(const AB_VALUE *v);
AQBANKING_API int AB_Value_IsNegative(const AB_VALUE *v);
AQBANKING_API int AB_Value_IsPositive(const AB_VALUE *v);
AQBANKING_API int AB_Value_Compare(const AB_VALUE *v1, const AB_VALUE *v2);

AQBANKING_API int AB_Value_AddValue(AB_VALUE *v1, const AB_VALUE *v2);
AQBANKING_API int AB_Value_SubValue(AB_VALUE *v1, const AB_VALUE *v2);
AQBANKING_API int AB_Value_MultValue(AB_VALUE *v1, const AB_VALUE *v2);
AQBANKING_API int AB_Value_DivValue(AB_VALUE *v1, const AB_VALUE *v2);

AQBANKING_API int AB_Value_Negate(AB_VALUE *v);


AQBANKING_API const char *AB_Value_GetCurrency(const AB_VALUE *v);
AQBANKING_API void AB_Value_SetCurrency(AB_VALUE *v, const char *s);


AQBANKING_API void AB_Value_Dump(const AB_VALUE *v, FILE *f, unsigned int indent);

#ifdef __cplusplus
}
#endif


#endif /* AB_VALUE_H */








