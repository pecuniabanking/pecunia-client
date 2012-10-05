/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Fri May 07 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef GWEN_URLFNS_H
#define GWEN_URLFNS_H

#include <gwenhywfar/url.h>
#include <gwenhywfar/buffer.h>

#ifdef __cplusplus
extern "C" {
#endif


/**
 * Parses the given string and returns an URL object (if the string is ok).
 */
GWENHYWFAR_API
GWEN_URL *GWEN_Url_fromString(const char *str);
GWENHYWFAR_API
int GWEN_Url_toString(const GWEN_URL *url, GWEN_BUFFER *buf);

GWENHYWFAR_API
GWEN_URL *GWEN_Url_fromCommandString(const char *str);
GWENHYWFAR_API
int GWEN_Url_toCommandString(const GWEN_URL *url, GWEN_BUFFER *buf);

#ifdef __cplusplus
} /* __cplusplus */
#endif


#endif /* HTTPURLFNS_H */
