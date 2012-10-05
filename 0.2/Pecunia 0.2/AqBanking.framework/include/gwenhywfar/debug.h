/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Thu Nov 28 2002
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


#ifndef GWEN_DEBUG_H
#define GWEN_DEBUG_H

#include <stdio.h>
#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/logger.h>
#include <gwenhywfar/error.h>
#include <gwenhywfar/types.h>

#ifdef __cplusplus
extern "C" {
#endif

#if (defined HAVE_FUNC && (DEBUGMODE>10))
# define DBG_ENTER fprintf(stderr,"Enter \""__func__"\" \n")
# define DBG_LEAVE fprintf(stderr,"Leave \""__func__"\" \n")
#else
# define DBG_ENTER
# define DBG_LEAVE
#endif

#define GWEN_MEMORY_DEBUG_MODE_ALL      0
#define GWEN_MEMORY_DEBUG_MODE_OPEN     1
#define GWEN_MEMORY_DEBUG_MODE_DETAILED 2
#define GWEN_MEMORY_DEBUG_MODE_SHORT    3

typedef struct GWEN_MEMORY_DEBUG_OBJECT GWEN_MEMORY_DEBUG_OBJECT;

GWENHYWFAR_API
void GWEN_MemoryDebug_Increment(const char *name,
                                const char *wFile,
                                int wLine,
                                int attach);
GWENHYWFAR_API
void GWEN_MemoryDebug_Decrement(const char *name,
                                const char *wFile,
                                int wLine);

GWENHYWFAR_API
void GWEN_MemoryDebug_Dump(uint32_t mode);

GWENHYWFAR_API
void GWEN_MemoryDebug_DumpObject(const char *name,
                                 uint32_t mode);

GWENHYWFAR_API
long int GWEN_MemoryDebug_GetObjectCount(const char *name);

GWENHYWFAR_API
void GWEN_MemoryDebug_CleanUp();


#ifdef GWEN_MEMORY_DEBUG
# define DBG_MEM_INC(o, attach)\
  GWEN_MemoryDebug_Increment(o, __FILE__, __LINE__, attach)
# define DBG_MEM_DEC(o)\
  GWEN_MemoryDebug_Decrement(o, __FILE__, __LINE__)
#else
# define DBG_MEM_INC(o, attach)
# define DBG_MEM_DEC(o)
#endif

GWENHYWFAR_API
uint32_t GWEN_Debug_Snprintf(char *buffer,
                                     uint32_t size,
                                     const char *fmt, ...);

#ifndef NO_VARIADIC_MACROS
# define DBG_ERROR(dbg_logger, format, args...) if (1){\
  char dbg_buffer[256]; \
  snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
  __FILE__":%5d: " format  , __LINE__ , ## args); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Error, dbg_buffer);};
#else /* #ifndef NO_VARIADIC_MACROS */
GWENHYWFAR_API 
void DBG_ERROR(const char *logdomain, const char *format, ...);
#endif /* #ifndef NO_VARIADIC_MACROS */

#define DBG_ERROR_ERR(dbg_logger, dbg_err) {\
 char dbg_buffer[256]; \
 char dbg_errbuff[256]; \
 GWEN_Error_ToString(dbg_err,dbg_errbuff, sizeof(dbg_errbuff)); \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: %s" , __LINE__ , dbg_errbuff); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Error, dbg_buffer);};

#ifndef NO_VARIADIC_MACROS
# define DBG_WARN(dbg_logger, format, args...) {\
  char dbg_buffer[256]; \
  snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
  __FILE__":%5d: " format  , __LINE__ , ## args); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Warning, dbg_buffer);};
#else /* #ifndef NO_VARIADIC_MACROS */
GWENHYWFAR_API 
void DBG_WARN(const char *logdomain, const char *format, ...);
#endif /* #ifndef NO_VARIADIC_MACROS */

#define DBG_WARN_ERR(dbg_logger, dbg_err) {\
 char dbg_buffer[256]; \
 char dbg_errbuff[256]; \
 GWEN_Error_ToString(dbg_err,dbg_errbuff, sizeof(dbg_errbuff)); \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: %s" , __LINE__ , dbg_errbuff); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Warning, dbg_buffer);};


#ifndef NO_VARIADIC_MACROS
# define DBG_NOTICE(dbg_logger, format, args...) \
 if (GWEN_Logger_GetLevel(dbg_logger)>=GWEN_LoggerLevel_Notice) {\
 char dbg_buffer[256]; \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: " format  , __LINE__ , ## args); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Notice, dbg_buffer);};
#else /* #ifndef NO_VARIADIC_MACROS */
GWENHYWFAR_API 
void DBG_NOTICE(const char *logdomain, const char *format, ...);
#endif /* #ifndef NO_VARIADIC_MACROS */

#define DBG_NOTICE_ERR(dbg_logger, dbg_err) \
 if (GWEN_Logger_GetLevel(dbg_logger)>=GWEN_LoggerLevel_Notice) {\
 char dbg_buffer[256]; \
 char dbg_errbuff[256]; \
 GWEN_Error_ToString(dbg_err,dbg_errbuff, sizeof(dbg_errbuff)); \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: %s" , __LINE__ , dbg_errbuff); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Notice, dbg_buffer);};


#ifndef NO_VARIADIC_MACROS
# define DBG_INFO(dbg_logger, format, args...) \
 if (GWEN_Logger_GetLevel(dbg_logger)>=GWEN_LoggerLevel_Info) {\
  char dbg_buffer[256]; \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: " format  , __LINE__ , ## args); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Info, dbg_buffer);};
#else /* #ifndef NO_VARIADIC_MACROS */
GWENHYWFAR_API 
void DBG_INFO(const char *logdomain, const char *format, ...);
#endif /* #ifndef NO_VARIADIC_MACROS */

#define DBG_INFO_ERR(dbg_logger, dbg_err) \
 if (GWEN_Logger_GetLevel(dbg_logger)>=GWEN_LoggerLevel_Info) {\
 char dbg_buffer[256]; \
 char dbg_errbuff[256]; \
 GWEN_Error_ToString(dbg_err,dbg_errbuff, sizeof(dbg_errbuff)); \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: %s" , __LINE__ , dbg_errbuff); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Info, dbg_buffer);};




#ifndef DISABLE_DEBUGLOG

# ifndef NO_VARIADIC_MACROS
#  define DBG_DEBUG(dbg_logger, format, args...) \
 if (GWEN_Logger_GetLevel(dbg_logger)>=GWEN_LoggerLevel_Debug) {\
 char dbg_buffer[256]; \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: " format  , __LINE__ , ## args); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Debug, dbg_buffer);};

#  define DBG_VERBOUS(dbg_logger, format, args...) \
 if (GWEN_Logger_GetLevel(dbg_logger)>=GWEN_LoggerLevel_Verbous) {\
 char dbg_buffer[256]; \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: " format  , __LINE__ , ## args); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Verbous, dbg_buffer);};
# endif /* #ifndef NO_VARIADIC_MACROS */

# define DBG_DEBUG_ERR(dbg_logger, dbg_err) \
 if (GWEN_Logger_GetLevel(dbg_logger)>=GWEN_LoggerLevel_Debug) {\
 char dbg_buffer[256]; \
 char dbg_errbuff[256]; \
 GWEN_Error_ToString(dbg_err,dbg_errbuff, sizeof(dbg_errbuff)); \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: %s" , __LINE__ , dbg_errbuff); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Debug, dbg_buffer);};

# define DBG_VERBOUS_ERR(dbg_logger, dbg_err) \
 if (GWEN_Logger_GetLevel(dbg_logger)>=GWEN_LoggerLevel_Verbous) {\
 char dbg_buffer[256]; \
 char dbg_errbuff[256]; \
 GWEN_Error_ToString(dbg_err,dbg_errbuff, sizeof(dbg_errbuff)); \
 snprintf(dbg_buffer, sizeof(dbg_buffer)-1,\
 __FILE__":%5d: %s" , __LINE__ , dbg_errbuff); \
  dbg_buffer[sizeof(dbg_buffer)-1]=0; \
 GWEN_Logger_Log(dbg_logger, GWEN_LoggerLevel_Verbous, dbg_buffer);};



#else

# ifndef NO_VARIADIC_MACROS
#  define DBG_DEBUG(dbg_logger, format, args...)
#  define DBG_VERBOUS(dbg_logger, format, args...)
# endif /* ifndef NO_VARIADIC_MACROS */

# define DBG_DEBUG_ERR(dbg_logger, dbg_err)
# define DBG_VERBOUS_ERR(dbg_logger, dbg_err)

#endif /* DISABLE_DEBUGLOG */

#ifdef NO_VARIADIC_MACROS
GWENHYWFAR_API 
void DBG_DEBUG(const char *logdomain, const char *format, ...);
GWENHYWFAR_API 
void DBG_VERBOUS(const char *logdomain, const char *format, ...);
#endif /* #ifdef NO_VARIADIC_MACROS */


#ifdef __cplusplus
}
#endif


#endif


