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


#ifndef AQBANKING_ERROR_H
#define AQBANKING_ERROR_H

#include <aqbanking/system.h>
#include <gwenhywfar/error.h>

#ifdef AQBANKING_IS_SUBPROJECT
# define AQBANKING_API
# define AQBANKING_EXPORT
# define AQBANKING_NOEXPORT
#else

# ifdef BUILDING_AQBANKING
#  /* building AqBanking */
#  if AQBANKING_SYS_IS_WINDOWS
#    /* for windows */
#    ifdef __declspec
#      define AQBANKING_API __declspec (dllexport)
#    else /* if __declspec */
#      define AQBANKING_API
#    endif /* if NOT __declspec */
#  else
#    /* for non-win32 */
#    ifdef GCC_WITH_VISIBILITY_ATTRIBUTE
#      define AQBANKING_API __attribute__((visibility("default")))
#    else
#      define AQBANKING_API
#    endif
#  endif
# else
#  /* not building AqBanking */
#  if AQBANKING_SYS_IS_WINDOWS
#    /* for windows */
#    ifdef __declspec
#      define AQBANKING_API __declspec (dllimport)
#    else /* if __declspec */
#      define AQBANKING_API
#    endif /* if NOT __declspec */
#  else
#    /* for non-win32 */
#    define AQBANKING_API
#  endif
# endif

# ifdef GCC_WITH_VISIBILITY_ATTRIBUTE
#  define AQBANKING_EXPORT __attribute__((visibility("default")))
#  define AQBANKING_NOEXPORT __attribute__((visibility("hidden")))
# else
#  define AQBANKING_EXPORT
#  define AQBANKING_NOEXPORT
# endif
#endif


#ifndef AQBANKING_NOWARN_DEPRECATED
# ifdef __GNUC__
#  define AQBANKING_DEPRECATED __attribute((__deprecated__))
# else
#  define AQBANKING_DEPRECATED
# endif
# else
#  define AQBANKING_DEPRECATED
#endif

#define AQBANKING_LOGDOMAIN "aqbanking"


/** @defgroup AB_ERROR Error Codes
 * @ingroup G_AB_C_INTERFACE
 */
/*@{*/

#define AB_ERROR_OFFSET GWEN_ERROR_USEROFFSET

#define AB_ERROR_BAD_CONFIG_FILE (AB_ERROR_OFFSET-1)
#define AB_ERROR_NETWORK         (AB_ERROR_OFFSET-2)
#define AB_ERROR_EMPTY           (AB_ERROR_OFFSET-3)

#define AB_ERROR_INDIFFERENT     (AB_ERROR_OFFSET-4)
#define AB_ERROR_UNKNOWN_ACCOUNT (AB_ERROR_OFFSET-5)

#define AB_ERROR_NOT_INIT        (AB_ERROR_OFFSET-6)
#define AB_ERROR_SECURITY        (AB_ERROR_OFFSET-7)
#define AB_ERROR_PLUGIN_MISSING  (AB_ERROR_OFFSET-8)

#define AB_ERROR_USER1           (AB_ERROR_OFFSET-50)
#define AB_ERROR_USER2           (AB_ERROR_OFFSET-51)
#define AB_ERROR_USER3           (AB_ERROR_OFFSET-52)
#define AB_ERROR_USER4           (AB_ERROR_OFFSET-53)

#define AB_ERROR_USEROFFSET      (AB_ERROR_OFFSET-100)

/*@}*/




#endif /* AQBANKING_ERROR_H */


