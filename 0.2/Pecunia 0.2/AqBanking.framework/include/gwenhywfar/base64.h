/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Thu May 06 2004
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


#ifndef GWENHYWFAR_BASE64_H
#define GWENHYWFAR_BASE64_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/buffer.h>


#ifdef __cplusplus
extern "C" {
#endif


/**
 * Encodes the given bytes and stores the result in a GWEN_BUFFER.
 * @return 0 if ok, !=0 on error
 * @param src src buffer
 * @param size number of bytes in the source buffer
 * @param dst destination buffer
 * @param maxLineLength after this number of bytes a line break is inserted
 *  (if 0 then no line break is inserted)
 */
GWENHYWFAR_API
int GWEN_Base64_Encode(const unsigned char *src, unsigned int size,
                       GWEN_BUFFER *dst,
                       unsigned int maxLineLength);

/**
 * Decodes base64 encoded data and stores the result in a GWEN_BUFFER.
 * @return 0 if ok, !=0 on error
 * @param src src buffer
 * @param size number of bytes to store in the GWEN_BUFFER (this is NOT
 *   the number of bytes stored in the source buffer, that buffer must
 *   hold more bytes because base64 encoding inflates the data to 4/3).
 * @param dst destination buffer
 */
GWENHYWFAR_API
int GWEN_Base64_Decode(const unsigned char *src, unsigned int size,
                       GWEN_BUFFER *dst);

#ifdef __cplusplus
}
#endif

#endif /* GWENHYWFAR_BASE64_H */


