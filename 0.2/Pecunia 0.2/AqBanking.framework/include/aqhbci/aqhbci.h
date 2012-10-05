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


#ifndef AQHBCI_AQHBCI_H
#define AQHBCI_AQHBCI_H

#include <aqbanking/system.h>


#ifdef BUILDING_AQHBCI
# /* building AqHBCI */
# if AQBANKING_SYS_IS_WINDOWS
#   /* for windows */
#   ifdef __declspec
#     define AQHBCI_API __declspec (dllexport)
#   else /* if __declspec */
#     define AQHBCI_API
#   endif /* if NOT __declspec */
# else
#   /* for non-win32 */
#   ifdef GCC_WITH_VISIBILITY_ATTRIBUTE
#     define AQHBCI_API __attribute__((visibility("default")))
#   else
#     define AQHBCI_API
#   endif
# endif
#else
# /* not building AqHBCI */
# if AQBANKING_SYS_IS_WINDOWS
#   /* for windows */
#   ifdef __declspec
#     define AQHBCI_API __declspec (dllimport)
#   else /* if __declspec */
#     define AQHBCI_API
#   endif /* if NOT __declspec */
# else
#   /* for non-win32 */
#   define AQHBCI_API
# endif
#endif


#define AH_PROVIDER_NAME "AQHBCI"

#define AQHBCI_LOGDOMAIN "aqhbci"


typedef enum {
  AH_CryptMode_Unknown=-1,
  /** No type.  */
  AH_CryptMode_None=0,
  /** DES-DES-Verfahren  */
  AH_CryptMode_Ddv,
  /** PIN/TAN mode  */
  AH_CryptMode_Pintan,
  /** RSA-DES-Hybridverfahren  */
  AH_CryptMode_Rdh
} AH_CRYPT_MODE;
AQHBCI_API
AH_CRYPT_MODE AH_CryptMode_fromString(const char *s);
AQHBCI_API
const char *AH_CryptMode_toString(AH_CRYPT_MODE v);


#endif /* AQHBCI_AQHBCI_H */

