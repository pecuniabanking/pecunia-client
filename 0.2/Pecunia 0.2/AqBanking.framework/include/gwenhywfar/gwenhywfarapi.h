/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Wed Sep 02 2002
    copyright   : (C) 2002 by Martin Preuss
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

#ifndef GWENHYWFARAPI_H
#define GWENHYWFARAPI_H

#include <gwenhywfar/types.h>

#ifdef GWENHYWFAR_IS_SUBPROJECT
# define GWENHYWFAR_API
# define GWENHYWFAR_EXPORT
# define GWENHYWFAR_NOEXPORT
# define GWEN_UNUSED
#else
# ifdef BUILDING_GWENHYWFAR
   /* building Gwenhywfar */
#  if GWENHYWFAR_SYS_IS_WINDOWS
     /* for windows */
#    ifdef __declspec
#      define GWENHYWFAR_API __declspec (dllexport)
#    else /* if __declspec */
#      define GWENHYWFAR_API
#    endif /* if NOT __declspec */
#  else
     /* for non-win32 */
#    ifdef GCC_WITH_VISIBILITY_ATTRIBUTE
#      define GWENHYWFAR_API __attribute__((visibility("default")))
#    else
#      define GWENHYWFAR_API
#    endif
#  endif
# else
   /* not building Gwenhywfar */
#  if GWENHYWFAR_SYS_IS_WINDOWS
     /* for windows */
#    ifdef __declspec
#      define GWENHYWFAR_API __declspec (dllimport)
#    else /* if __declspec */
#      define GWENHYWFAR_API
#    endif /* if NOT __declspec */
#  else
     /* for non-win32 */
#    define GWENHYWFAR_API
#  endif
# endif

# ifdef GCC_WITH_VISIBILITY_ATTRIBUTE
#  define GWENHYWFAR_EXPORT __attribute__((visibility("default")))
#  define GWENHYWFAR_NOEXPORT __attribute__((visibility("hidden")))
# else
#  define GWENHYWFAR_EXPORT
#  define GWENHYWFAR_NOEXPORT
# endif

# ifdef __GNUC__
#  define GWEN_UNUSED __attribute__((unused))
# else
#  define GWEN_UNUSED
# endif
#endif

#if GWENHYWFAR_SYS_IS_WINDOWS
# define GWENHYWFAR_CB __stdcall
#else
# define GWENHYWFAR_CB
#endif

#if GWENHYWFAR_SYS_IS_WINDOWS
# define GWEN_DIR_SEPARATOR           '\\'
# define GWEN_DIR_SEPARATOR_S         "\\"
# define GWEN_SEARCHPATH_SEPARATOR    ';'
# define GWEN_SEARCHPATH_SEPARATOR_S  ";"
#else
/** The directory separator character. This is '/' on UNIX
    machines and '\' under Windows. Since gwenhywfar-2.5.4. */
# define GWEN_DIR_SEPARATOR           '/'
/** The directory separator as a string. This is "/" on UNIX
    machines and "\" under Windows. Since gwenhywfar-2.5.4. */
# define GWEN_DIR_SEPARATOR_S         "/"
/** The search path separator character. This is ':' on UNIX
    machines and ';' under Windows. Since gwenhywfar-2.5.4. */
# define GWEN_SEARCHPATH_SEPARATOR    ':'
/** The search path separator as a string. This is ":" on UNIX
    machines and ";" under Windows. Since gwenhywfar-2.5.4. */
# define GWEN_SEARCHPATH_SEPARATOR_S  ":"
#endif


/* Convenience macros to test the versions of glibc and gcc. Taken
   from <features.h> which does not contain this on MinGW systems.  */
#ifndef __GNUC_PREREQ
# if defined __GNUC__ && defined __GNUC_MINOR__
#  define __GNUC_PREREQ(maj, min) \
        ((__GNUC__ << 16) + __GNUC_MINOR__ >= ((maj) << 16) + (min))
# else
#  define __GNUC_PREREQ(maj, min) 0
# endif
#endif /* __GNUC_PREREQ */


/* Taken from <sys/cdefs.h> which does not contain this on MinGW
   systems.  */
#ifndef __STRING
# define __STRING(x)     #x
#endif /* __STRING */


/* This is needed for PalmOS, because it define some functions needed */
#include <string.h>
#include <gwenhywfar/system.h>


#if __GNUC_PREREQ(3, 0)
/* Only available in gcc >= 3.0.x */
# define DEPRECATED __attribute__((deprecated))
# define GWEN_LIKELY(cond) __builtin_expect(!!(cond), 1)
# define GWEN_UNLIKELY(cond) __builtin_expect(!!(cond), 0)
#else
# define DEPRECATED
# define GWEN_LIKELY(cond) (!!(cond))
# define GWEN_UNLIKELY(cond) (!!(cond))
#endif /* __GNUC__ */


#define GWEN_TIMEOUT_NONE    (0)
#define GWEN_TIMEOUT_FOREVER (-1)


#endif


