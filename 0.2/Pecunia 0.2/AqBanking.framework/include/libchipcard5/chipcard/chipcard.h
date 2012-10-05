/***************************************************************************
    begin       : Tue Dec 23 2003
    copyright   : (C) 2003 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CHIPCARD_H
#define CHIPCARD_CHIPCARD_H

#define CHIPCARD_SYS_IS_WINDOWS 0


#ifdef LCC_IS_SUBPROJECT
# define CHIPCARD_API
# define CHIPCARD_EXPORT
# define CHIPCARD_NOEXPORT
#else
# ifdef BUILDING_CHIPCARD
   /* building Gwenhywfar */
#  if CHIPCARD_SYS_IS_WINDOWS
     /* for windows */
#    ifdef __declspec
#      define CHIPCARD_API __declspec (dllexport)
#    else /* if __declspec */
#      define CHIPCARD_API
#    endif /* if NOT __declspec */
#  else
     /* for non-win32 */
#    ifdef GCC_WITH_VISIBILITY_ATTRIBUTE
#      define CHIPCARD_API __attribute__((visibility("default")))
#    else
#      define CHIPCARD_API
#    endif
#  endif
# else
   /* not building Gwenhywfar */
#  if CHIPCARD_SYS_IS_WINDOWS
     /* for windows */
#    ifdef __declspec
#      define CHIPCARD_API __declspec (dllimport)
#    else /* if __declspec */
#      define CHIPCARD_API
#    endif /* if NOT __declspec */
#  else
     /* for non-win32 */
#    define CHIPCARD_API
#  endif
# endif

# ifdef GCC_WITH_VISIBILITY_ATTRIBUTE
#  define CHIPCARD_EXPORT __attribute__((visibility("default")))
#  define CHIPCARD_NOEXPORT __attribute__((visibility("hidden")))
# else
#  define CHIPCARD_EXPORT
#  define CHIPCARD_NOEXPORT
# endif
#endif


#if CHIPCARD_SYS_IS_WINDOWS
# define CHIPCARD_CB __stdcall
#else
# define CHIPCARD_CB
#endif


#ifndef CHIPCARD_NOWARN_DEPRECATED
# ifdef __GNUC__
#  define CHIPCARD_DEPRECATED __attribute((__deprecated__))
# else
#  define CHIPCARD_DEPRECATED
# endif
# else
#  define CHIPCARD_DEPRECATED
#endif

#include <gwenhywfar/db.h>
#include <gwenhywfar/xml.h>

#include <inttypes.h>


#define LC_DEFAULT_PORT 7392 /* FIXME: make this adjustable by configure */
#define LC_DEFAULT_UDS_SOCK "/var/run/chipcard.comm"

/** Error codes */
/*@{*/
#define LC_ERROR_NONE                  0x00000000
#define LC_ERROR_GENERIC               0x00000001
#define LC_ERROR_INVALID               0x00000002
#define LC_ERROR_CARD_REMOVED          0x00000003
#define LC_ERROR_CARD_NOT_OWNED        0x00000004
#define LC_ERROR_NOT_SUPPORTED         0x00000005
#define LC_ERROR_SETUP                 0x00000006
#define LC_ERROR_NO_DATA               0x00000007
#define LC_ERROR_LOCKED_BY_OTHER       0x00000008
#define LC_ERROR_NOT_LOCKED            0x00000009

#define LC_ERROR_BAD_RESPONSE          0x0000000a
#define LC_ERROR_NO_SLOTS_CONNECTED    0x0000000b
#define LC_ERROR_NO_SLOTS_DISCONNECTED 0x0000000c
#define LC_ERROR_NO_SLOTS_AVAILABLE    0x0000000d
#define LC_ERROR_BAD_PIN               0x0000000e
#define LC_ERROR_USER_ABORTED          0x0000000f
#define LC_ERROR_CARD_DESTROYED        0x00000010
#define LC_ERROR_READER_REMOVED        0x00000011
#define LC_ERROR_TIMEOUT               0x00000012
#define LC_ERROR_IPC                   0x00000013
#define LC_ERROR_BUFFER_OVERFLOW       0x00000014
/*@}*/
const char *LC_Error_toString(uint32_t err);


#define LC_LOGDOMAIN "ccclient"

/** Reader flags */
/*@{*/
#define LC_READER_FLAGS_KEYPAD             0x00010000
#define LC_READER_FLAGS_DISPLAY            0x00020000
#define LC_READER_FLAGS_NOINFO             0x00040000
#define LC_READER_FLAGS_REMOTE             0x00080000
#define LC_READER_FLAGS_AUTO               0x00100000
#define LC_READER_FLAGS_SUSPENDED_CHECKS   0x00200000
#define LC_READER_FLAGS_DRIVER_HAS_VERIFY  0x00400000
#define LC_READER_FLAGS_KEEP_RUNNING       0x00800000
#define LC_READER_FLAGS_LOW_WRITE_BOUNDARY 0x01000000
#define LC_READER_FLAGS_NO_MEMORY_SW       0x02000000
/*@}*/

CHIPCARD_API
uint32_t LC_ReaderFlags_fromXml(GWEN_XMLNODE *node, const char *name);
CHIPCARD_API
uint32_t LC_ReaderFlags_fromDb(GWEN_DB_NODE *db, const char *name);
CHIPCARD_API void LC_ReaderFlags_toDb(GWEN_DB_NODE *db,
                                      const char *name,
                                      uint32_t fl);

/** driver is a remote driver, not started by the server */
#define LC_DRIVER_FLAGS_RUNTIME_MASK  0xffff0000
#define LC_DRIVER_FLAGS_AUTO          0x00010000
#define LC_DRIVER_FLAGS_REMOTE        0x00020000
#define LC_DRIVER_FLAGS_CONFIG        0x00040000

#define LC_DRIVER_FLAGS_HAS_VERIFY_FN 0x00000001
#define LC_DRIVER_FLAGS_HAS_MODIFY_FN 0x00000002

CHIPCARD_API
uint32_t LC_DriverFlags_fromDb(GWEN_DB_NODE *db, const char *name);

CHIPCARD_API
int LC_DriverFlags_toDb(GWEN_DB_NODE *db,
                        const char *name,
                        uint32_t flags);


/** service provided by a client */
#define LC_SERVICE_FLAGS_RUNTIME_MASK (\
    LC_SERVICE_FLAGS_CLIENT \
    )
#define LC_SERVICE_FLAGS_CLIENT   0x00000001
#define LC_SERVICE_FLAGS_AUTOLOAD 0x00000002
#define LC_SERVICE_FLAGS_SILENT   0x00000004

CHIPCARD_API
uint32_t LC_ServiceFlags_fromDb(GWEN_DB_NODE *db, const char *name);
CHIPCARD_API void LC_ServiceFlags_toDb(GWEN_DB_NODE *db,
                                       const char *name,
                                       uint32_t fl);


/** Notification flags */
/*@{*/
#define LC_NOTIFY_FLAGS_DRIVER_MASK      0x0000003f
#define LC_NOTIFY_FLAGS_DRIVER_START     0x00000001
#define LC_NOTIFY_FLAGS_DRIVER_UP        0x00000002
#define LC_NOTIFY_FLAGS_DRIVER_DOWN      0x00000004
#define LC_NOTIFY_FLAGS_DRIVER_ERROR     0x00000008
#define LC_NOTIFY_FLAGS_DRIVER_ADD       0x00000010
#define LC_NOTIFY_FLAGS_DRIVER_DEL       0x00000020

#define LC_NOTIFY_FLAGS_READER_MASK      0x00000fc0
#define LC_NOTIFY_FLAGS_READER_START     0x00000040
#define LC_NOTIFY_FLAGS_READER_UP        0x00000080
#define LC_NOTIFY_FLAGS_READER_DOWN      0x00000100
#define LC_NOTIFY_FLAGS_READER_ERROR     0x00000200
#define LC_NOTIFY_FLAGS_READER_ADD       0x00000400
#define LC_NOTIFY_FLAGS_READER_DEL       0x00000800

#define LC_NOTIFY_FLAGS_SERVICE_MASK     0x0000f000
#define LC_NOTIFY_FLAGS_SERVICE_START    0x00001000
#define LC_NOTIFY_FLAGS_SERVICE_UP       0x00002000
#define LC_NOTIFY_FLAGS_SERVICE_DOWN     0x00004000
#define LC_NOTIFY_FLAGS_SERVICE_ERROR    0x00008000

#define LC_NOTIFY_FLAGS_CARD_MASK        0x000f0000
#define LC_NOTIFY_FLAGS_CARD_INSERTED    0x00010000
#define LC_NOTIFY_FLAGS_CARD_REMOVED     0x00020000
#define LC_NOTIFY_FLAGS_CARD_RFU1        0x00040000
#define LC_NOTIFY_FLAGS_CARD_RFU2        0x00080000

#define LC_NOTIFY_FLAGS_CLIENT_MASK      0xfff00000
#define LC_NOTIFY_FLAGS_CLIENT_UP        0x00100000
#define LC_NOTIFY_FLAGS_CLIENT_DOWN      0x00200000
#define LC_NOTIFY_FLAGS_CLIENT_STARTWAIT 0x00400000
#define LC_NOTIFY_FLAGS_CLIENT_STOPWAIT  0x00800000
#define LC_NOTIFY_FLAGS_CLIENT_TAKECARD  0x01000000
#define LC_NOTIFY_FLAGS_CLIENT_GOTCARD   0x02000000

#define LC_NOTIFY_FLAGS_CLIENT_CMDSEND   0x04000000
#define LC_NOTIFY_FLAGS_CLIENT_CMDRECV   0x08000000

#define LC_NOTIFY_FLAGS_SINGLESHOT       0x80000000

#define LC_NOTIFY_FLAGS_PRIVILEGED (\
  LC_NOTIFY_FLAGS_CLIENT_CMDSEND |\
  LC_NOTIFY_FLAGS_CLIENT_CMDRECV)

CHIPCARD_API
uint32_t LC_NotifyFlags_fromDb(GWEN_DB_NODE *db, const char *name);
CHIPCARD_API void LC_NotifyFlags_toDb(GWEN_DB_NODE *db,
                                      const char *name,
                                      uint32_t fl);


/*@}*/


/** @name Notify Types/Codes
 *
 *
 */
/*@{*/
#define LC_NOTIFY_TYPE_DRIVER           "driver"
#define LC_NOTIFY_CODE_DRIVER_START     "start"
#define LC_NOTIFY_CODE_DRIVER_UP        "up"
#define LC_NOTIFY_CODE_DRIVER_DOWN      "down"
#define LC_NOTIFY_CODE_DRIVER_ERROR     "error"
#define LC_NOTIFY_CODE_DRIVER_ADD       "add"
#define LC_NOTIFY_CODE_DRIVER_DEL       "del"

#define LC_NOTIFY_TYPE_READER           "reader"
#define LC_NOTIFY_CODE_READER_START     "start"
#define LC_NOTIFY_CODE_READER_UP        "up"
#define LC_NOTIFY_CODE_READER_DOWN      "down"
#define LC_NOTIFY_CODE_READER_ERROR     "error"
#define LC_NOTIFY_CODE_READER_ADD       "add"
#define LC_NOTIFY_CODE_READER_DEL       "del"

#define LC_NOTIFY_TYPE_SERVICE          "service"
#define LC_NOTIFY_CODE_SERVICE_START    "start"
#define LC_NOTIFY_CODE_SERVICE_UP       "up"
#define LC_NOTIFY_CODE_SERVICE_DOWN     "down"
#define LC_NOTIFY_CODE_SERVICE_ERROR    "error"

#define LC_NOTIFY_TYPE_CARD             "card"
#define LC_NOTIFY_CODE_CARD_INSERTED    "inserted"
#define LC_NOTIFY_CODE_CARD_REMOVED     "removed"
#define LC_NOTIFY_CODE_CARD_RFU1        "rfu1"
#define LC_NOTIFY_CODE_CARD_RFU2        "rfu2"

#define LC_NOTIFY_TYPE_CLIENT           "client"
#define LC_NOTIFY_CODE_CLIENT_UP        "up"
#define LC_NOTIFY_CODE_CLIENT_DOWN      "down"
#define LC_NOTIFY_CODE_CLIENT_STARTWAIT "startwait"
#define LC_NOTIFY_CODE_CLIENT_STOPWAIT  "stopwait"
#define LC_NOTIFY_CODE_CLIENT_TAKECARD  "takecard"
#define LC_NOTIFY_CODE_CLIENT_GOTCARD   "gotcard"

#define LC_NOTIFY_CODE_CLIENT_CMDSEND   "cmdsend"
#define LC_NOTIFY_CODE_CLIENT_CMDRECV   "cmdrecv"
/*@}*/




typedef enum {
  LC_DriverStatusDown=0,
  LC_DriverStatusWaitForStart,
  LC_DriverStatusStarted,
  LC_DriverStatusUp,
  LC_DriverStatusStopping,
  LC_DriverStatusAborted,
  LC_DriverStatusDisabled,
  LC_DriverStatusUnknown=999
} LC_DRIVER_STATUS;

CHIPCARD_API LC_DRIVER_STATUS LC_DriverStatus_fromString(const char *s);
CHIPCARD_API const char *LC_DriverStatus_toString(LC_DRIVER_STATUS dst);


typedef enum {
  LC_ReaderStatusDown=0,
  LC_ReaderStatusWaitForStart,
  LC_ReaderStatusWaitForDriver,
  LC_ReaderStatusWaitForReaderUp,
  LC_ReaderStatusWaitForReaderDown,
  LC_ReaderStatusUp,
  LC_ReaderStatusAborted,
  LC_ReaderStatusDisabled,
  LC_ReaderStatusHwAdd=900,  /* internal status code */
  LC_ReaderStatusHwDel=901,  /* internal status code */
  LC_ReaderStatusUnknown=999
} LC_READER_STATUS;

CHIPCARD_API LC_READER_STATUS LC_ReaderStatus_fromString(const char *s);
CHIPCARD_API const char *LC_ReaderStatus_toString(LC_READER_STATUS rst);


typedef enum {
  LC_ServiceStatusDown=0,
  LC_ServiceStatusWaitForStart,
  LC_ServiceStatusStarted,
  LC_ServiceStatusUp,
  LC_ServiceStatusSilentRunning,
  LC_ServiceStatusStopping,
  LC_ServiceStatusAborted,
  LC_ServiceStatusDisabled,
  LC_ServiceStatusUnknown=999
} LC_SERVICE_STATUS;

CHIPCARD_API LC_SERVICE_STATUS LC_ServiceStatus_fromString(const char *s);
CHIPCARD_API const char *LC_ServiceStatus_toString(LC_SERVICE_STATUS st);


typedef enum {
  LC_CardStatusInserted=0,
  LC_CardStatusRemoved,
  LC_CardStatusOrphaned,

  LC_CardStatusUnknown=999
} LC_CARD_STATUS;


typedef enum {
  LC_CardTypeUnknown=0,
  LC_CardTypeProcessor,
  LC_CardTypeMemory
} LC_CARD_TYPE;


#endif /* CHIPCARD_CHIPCARD_H */
