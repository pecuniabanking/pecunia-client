/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Mon Jan 05 2004
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

#ifndef GWEN_PADD_H
#define GWEN_PADD_H

#include <gwenhywfar/buffer.h>
#include <gwenhywfar/paddalgo.h>
#include <gwenhywfar/mdigest.h>

#ifdef __cplusplus
extern "C" {
#endif


/** @defgroup MOD_CRYPT_PADD Padding Functions
 * @ingroup MOD_CRYPT
 * These functions are used for padding when encrypting/decrypting data
 * using 2-key-triple-DES or when signing data.
 * The original code (in C++) has been written by
 * <strong>Fabian Kaiser</strong> for <strong>OpenHBCI</strong>
 * (file rsakey.cpp). Translated to C and slightly modified by me
 * (Martin Preuss)
 */
/*@{*/

/**
 * This function padds the given buffer according to ISO9796.
 * The given buffer is expected to contain a 20 byte hash created using
 * RIPEMD 160. This is padded to 96 bytes according to ISO 9796 (including
 * appendix A4).
 */
GWENHYWFAR_API
int GWEN_Padd_PaddWithISO9796(GWEN_BUFFER *src);

/**
 * This function padds according to ISO 8786-2.
 */
GWENHYWFAR_API
int GWEN_Padd_PaddWithIso9796_2(GWEN_BUFFER *buf, int dstSize);


GWENHYWFAR_API
int GWEN_Padd_UnpaddWithIso9796_2(GWEN_BUFFER *buf);

/**
 * This is a compatibility function
 * (calls @ref GWEN_Padd_PaddWithAnsiX9_23ToMultipleOf with param y=8).
 */
GWENHYWFAR_API
int GWEN_Padd_PaddWithAnsiX9_23(GWEN_BUFFER *src);

/**
 * This is a compatibility function
 * (calls @ref GWEN_Padd_UnpaddWithAnsiX9_23FromMultipleOf with param y=8).
 */
GWENHYWFAR_API
int GWEN_Padd_UnpaddWithAnsiX9_23(GWEN_BUFFER *src);


/**
 * This function is used to pad the plain text data to a multiple of 8 bytes
 * size before encrypting it.
 * This is done by adding bytes to the buffer until its length is multiple of
 * Y bytes. The byte added is the number of padding bytes appended.
 * Example: Y is 8, buffer initially contains 5 bytes, so 3 bytes are needed to make
 * the buffer length a multiple of 8. So the number "3" is added three times.
 * Please note that if the buffer initially has a multiple of Y bytes then
 * Y bytes are added (this is needed to make sure the unpadd function can
 * always recover data padded in this manner).
 *
 */
GWENHYWFAR_API
int GWEN_Padd_PaddWithAnsiX9_23ToMultipleOf(GWEN_BUFFER *src, int y);

/**
 * This function is used to remove padding from plain text data after
 * decrypting it.
 */
GWENHYWFAR_API
int GWEN_Padd_UnpaddWithAnsiX9_23FromMultipleOf(GWEN_BUFFER *src, int y);


GWENHYWFAR_API
int GWEN_Padd_PaddWithPkcs1Bt1(GWEN_BUFFER *src, int dstSize);

GWENHYWFAR_API
int GWEN_Padd_UnpaddWithPkcs1Bt1(GWEN_BUFFER *src);

GWENHYWFAR_API
int GWEN_Padd_PaddWithPkcs1Bt2(GWEN_BUFFER *src, int dstSize);

GWENHYWFAR_API
int GWEN_Padd_UnpaddWithPkcs1Bt2(GWEN_BUFFER *src);


GWENHYWFAR_API
int GWEN_Padd_MGF1(uint8_t *pDestBuffer,
		   uint32_t lDestBuffer,
		   const uint8_t *pSeed,
		   uint32_t lSeed,
		   GWEN_MDIGEST *md);

/**
 * @param nbits number of actual bits of the modulus
 */
GWENHYWFAR_API
int GWEN_Padd_AddPkcs1Pss(uint8_t *pDestBuffer,
			  uint32_t lDestBuffer,
			  uint32_t nbits,
			  const uint8_t *pHash,
			  uint32_t lHash,
			  uint32_t lSalt,
			  GWEN_MDIGEST *md);

GWENHYWFAR_API
int GWEN_Padd_VerifyPkcs1Pss(const uint8_t *pSrcBuffer,
			     uint32_t lSrcBuffer,
			     uint32_t nbits,
			     const uint8_t *pHash,
			     uint32_t lHash,
			     uint32_t lSalt,
			     GWEN_MDIGEST *md);


GWENHYWFAR_API
int GWEN_Padd_ApplyPaddAlgo(const GWEN_CRYPT_PADDALGO *a, GWEN_BUFFER *src);

GWENHYWFAR_API
int GWEN_Padd_UnapplyPaddAlgo(const GWEN_CRYPT_PADDALGO *a, GWEN_BUFFER *buf);

/*@}*/

#ifdef __cplusplus
}
#endif



#endif /* GWEN_PADD_H */

