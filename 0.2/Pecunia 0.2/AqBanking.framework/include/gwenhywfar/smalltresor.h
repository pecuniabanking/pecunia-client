/***************************************************************************
    begin       : Wed May 11 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_SMALLTRESOR_H
#define GWEN_SMALLTRESOR_H


#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/buffer.h>


#ifdef __cplusplus
extern "C" {
#endif


/**
 * This function encrypts the given data using the given password.
 * The key for encryption is derived from the given password using
 * the function @ref GWEN_MDigest_PKPDF2.
 */
GWENHYWFAR_API
int GWEN_SmallTresor_Encrypt(const uint8_t *src,
			     uint32_t slen,
			     const char *password,
			     GWEN_BUFFER *dst,
			     int passwordIterations,
			     int cryptIterations);


GWENHYWFAR_API
int GWEN_SmallTresor_Decrypt(const uint8_t *p,
			     uint32_t len,
			     const char *password,
			     GWEN_BUFFER *dst,
			     int passwordIterations,
			     int cryptIterations);



#ifdef __cplusplus
}
#endif


#endif

