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


#ifndef AQOFXCONNECT_AQOFXCONNECT_H
#define AQOFXCONNECT_AQOFXCONNECT_H


#include <aqbanking/system.h>

#ifdef BUILDING_AQOFXCONNECT
# /* building AqOFXCONNECT */
# if AQBANKING_SYS_IS_WINDOWS
#   /* for windows */
#   ifdef __declspec
#     define AQOFXCONNECT_API __declspec (dllexport)
#   else /* if __declspec */
#     define AQOFXCONNECT_API
#   endif /* if NOT __declspec */
# else
#   /* for non-win32 */
#   ifdef GCC_WITH_VISIBILITY_ATTRIBUTE
#     define AQOFXCONNECT_API __attribute__((visibility("default")))
#   else
#     define AQOFXCONNECT_API
#   endif
# endif
#else
# /* not building AqOFXCONNECT */
# if AQBANKING_SYS_IS_WINDOWS
#   /* for windows */
#   ifdef __declspec
#     define AQOFXCONNECT_API __declspec (dllimport)
#   else /* if __declspec */
#     define AQOFXCONNECT_API
#   endif /* if NOT __declspec */
# else
#   /* for non-win32 */
#   define AQOFXCONNECT_API
# endif
#endif


#define AQOFXCONNECT_LOGDOMAIN "aqofxconnect"


#endif /* AQOFXCONNECT_AQOFXCONNECT_H */

