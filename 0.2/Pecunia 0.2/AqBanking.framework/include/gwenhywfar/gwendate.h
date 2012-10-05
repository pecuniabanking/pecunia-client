/***************************************************************************
    begin       : Tue Jul 07 2009
    copyright   : (C) 2009 by Martin Preuss
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

#ifndef GWEN_DATE_H
#define GWEN_DATE_H


#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/buffer.h>


typedef struct GWEN_DATE GWEN_DATE;


#include <gwenhywfar/gwentime.h>


#ifdef __cplusplus
extern "C" {
#endif




/**
 * Create a date from the gregorian calender using year, month and day.
 * @param y year (e.g. 2009)
 * @param m month (1-12)
 * @param d day of month (1-31)
 */
GWENHYWFAR_API GWEN_DATE *GWEN_Date_fromGregorian(int y, int m, int d);

/**
 * Create a date from the julian calender.
 * @param julian date in julian calender
 */
GWENHYWFAR_API GWEN_DATE *GWEN_Date_fromJulian(int julian);

/**
 * Create a date from the current local date.
 */
GWENHYWFAR_API GWEN_DATE *GWEN_Date_CurrentDate();

GWENHYWFAR_API GWEN_DATE *GWEN_Date_fromString(const char *s);

GWENHYWFAR_API GWEN_DATE *GWEN_Date_dup(const GWEN_DATE *ogd);

GWENHYWFAR_API GWEN_DATE *GWEN_Date_fromTime(const GWEN_TIME *ti);

GWENHYWFAR_API GWEN_DATE *GWEN_Date_fromStringWithTemplate(const char *s, const char *tmpl);
GWENHYWFAR_API int GWEN_Date_toStringWithTemplate(const GWEN_DATE *t,
						  const char *tmpl,
						  GWEN_BUFFER *buf);


/**
 * Destructor.
 */
GWENHYWFAR_API void GWEN_Date_free(GWEN_DATE *gd);



GWENHYWFAR_API const char *GWEN_Date_GetString(const GWEN_DATE *gd);


GWENHYWFAR_API int GWEN_Date_DaysInMonth(const GWEN_DATE *gd);

GWENHYWFAR_API int GWEN_Date_DaysInYear(const GWEN_DATE *gd);

GWENHYWFAR_API int GWEN_Date_GetYear(const GWEN_DATE *gd);
GWENHYWFAR_API int GWEN_Date_GetMonth(const GWEN_DATE *gd);
GWENHYWFAR_API int GWEN_Date_GetDay(const GWEN_DATE *gd);
GWENHYWFAR_API int GWEN_Date_WeekDay(const GWEN_DATE *gd);
GWENHYWFAR_API int GWEN_Date_GetJulian(const GWEN_DATE *gd);


GWENHYWFAR_API int GWEN_Date_IsLeapYear(int y);
GWENHYWFAR_API int GWEN_Date_Compare(const GWEN_DATE *gd1, const GWEN_DATE *gd0);
GWENHYWFAR_API int GWEN_Date_Diff(const GWEN_DATE *gd1, const GWEN_DATE *gd0);




#ifdef __cplusplus
}
#endif



#endif


