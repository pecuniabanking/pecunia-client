/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Wed Mar 24 2004
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


#ifndef GWEN_TIME_H
#define GWEN_TIME_H


#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/db.h>
#include <time.h>


#ifdef __cplusplus
extern "C" {
#endif

typedef struct GWEN_TIME GWEN_TIME;


GWENHYWFAR_API int GWEN_Time_toDb(const GWEN_TIME *t, GWEN_DB_NODE *db);
GWENHYWFAR_API GWEN_TIME *GWEN_Time_fromDb(GWEN_DB_NODE *db);


GWENHYWFAR_API GWEN_TIME *GWEN_CurrentTime(void);

GWENHYWFAR_API GWEN_TIME *GWEN_Time_new(int year,
                                        int month,
                                        int day,
                                        int hour,
                                        int min,
                                        int sec,
                                        int inUtc);

/**
 * <p>
 * Parses the data and time from the given string according to the template
 * string (quite similar to sscanf).
 * </p>
 * <p>
 * The string is expected to contain the date/time in local time.
 * </p>
 * The following characters are accepted in the template string:
 * <table border="1">
 *  <tr><td>Character</td><td>Meaning</td></tr>
 *  <tr><td>Y</td><td>digit of the year</td></tr>
 *  <tr><td>M</td><td>digit of the month</td></tr>
 *  <tr><td>D</td><td>digit of the day of month</td></tr>
 *  <tr><td>h</td><td>digit of the hour</td></tr>
 *  <tr><td>m</td><td>digit of the minute</td></tr>
 *  <tr><td>s</td><td>digit of the second</td></tr>
 * </table>
 * All other characters are ignored. <br>
 * Some examples of valid patterns follow:
 * <ul>
 *  <li>"YYYYMMDD"</li>
 *  <li>"YYMMDD"</li>
 *  <li>"YY/MM/DD"</li>
 *  <li>"YYYYMMDD hh:mm:ss"</li>
 *  <li>"YYYYMMDD hh:mm"</li>
 *  <li>"YYYYMMDD hhmmss"</li>
 *  <li>et cetera</li>
 * </ul>
 * @return 0 on error, a GWEN_TIME pointer otherwise
 * @param s string containing the date/time
 * @param tmpl template string
 */
GWENHYWFAR_API GWEN_TIME *GWEN_Time_fromString(const char *s,
                                               const char *tmpl);

GWENHYWFAR_API GWEN_TIME *GWEN_Time_fromUtcString(const char *s,
                                                  const char *tmpl);

GWENHYWFAR_API int GWEN_Time_toString(const GWEN_TIME *t,
                                      const char *tmpl,
                                      GWEN_BUFFER *buf);
GWENHYWFAR_API int GWEN_Time_toUtcString(const GWEN_TIME *t,
                                         const char *tmpl,
                                         GWEN_BUFFER *buf);


/**
 * Creates a GWEN_TIME object from the return value of @ref GWEN_Time_Seconds.
 */
GWENHYWFAR_API GWEN_TIME *GWEN_Time_fromSeconds(uint32_t s);
GWENHYWFAR_API void GWEN_Time_free(GWEN_TIME *t);
GWENHYWFAR_API GWEN_TIME *GWEN_Time_dup(const GWEN_TIME *t);

/**
 * Returns the time in seconds since the epoch (00:00:00 UTC Jan 1, 1970).
 */
GWENHYWFAR_API uint32_t GWEN_Time_Seconds(const GWEN_TIME *t);

/** returns the time in milliseconds */
GWENHYWFAR_API double GWEN_Time_Milliseconds(const GWEN_TIME *t);

/**
 * Returns the difference between t1 and t2 in milliseconds
 */
GWENHYWFAR_API double GWEN_Time_Diff(const GWEN_TIME *t1,
                                     const GWEN_TIME *t0);

/**
 * Returns the difference between t1 and t2 in seconds
 */
GWENHYWFAR_API double GWEN_Time_DiffSeconds(const GWEN_TIME *t1,
                                            const GWEN_TIME *t0);

/* Compare t1 and t0. Return 0 if both are equal, -1 if t1<t0 and
 * 1 if t1>t0
 */
GWENHYWFAR_API int GWEN_Time_Compare(const GWEN_TIME *t1, const GWEN_TIME *t0);

/**
 * Adds the given number of seconds to the given GWEN_TIME.
 * @return 0 if ok, !=0 on error (see @ref MOD_ERROR_SIMPLE)
 */
GWENHYWFAR_API int GWEN_Time_AddSeconds(GWEN_TIME *ti, uint32_t secs);

/**
 * Subs the given number of seconds from the given GWEN_TIME.
 * @return 0 if ok, !=0 on error (see @ref MOD_ERROR_SIMPLE)
 */
GWENHYWFAR_API int GWEN_Time_SubSeconds(GWEN_TIME *ti, uint32_t secs);


/**
 * Returns the broken down time as local time.
 */
GWENHYWFAR_API int GWEN_Time_GetBrokenDownTime(const GWEN_TIME *t,
                                               int *hours,
                                               int *mins,
                                               int *secs);

/**
 * Returns the broken down time as UTC time (Greenwhich Mean time).
 */
GWENHYWFAR_API int GWEN_Time_GetBrokenDownUtcTime(const GWEN_TIME *t,
                                                  int *hours,
                                                  int *mins,
                                                  int *secs);

/**
 * Returns the broken down date as local date.
 */
GWENHYWFAR_API int GWEN_Time_GetBrokenDownDate(const GWEN_TIME *t,
                                               int *days,
                                               int *month,
                                               int *year);

/**
 * Returns the broken down time as UTC date (Greenwhich Mean time).
 */
GWENHYWFAR_API int GWEN_Time_GetBrokenDownUtcDate(const GWEN_TIME *t,
                                                  int *days,
                                                  int *month,
                                                  int *year);

/**
 * Returns this date as a struct tm (see ctime(3)) in the local time
 * zone.
 */
GWENHYWFAR_API struct tm GWEN_Time_toTm(const GWEN_TIME *t);

/**
 * Returns this date as a time_t value (see time(2)).
 */
GWENHYWFAR_API time_t GWEN_Time_toTime_t(const GWEN_TIME *t);



#ifdef __cplusplus
}
#endif



#endif

