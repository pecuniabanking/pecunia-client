/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Sun Jan 25 2004
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


#ifndef GWEN_RINGBUFFER_H
#define GWEN_RINGBUFFER_H

#include <gwenhywfar/types.h>
#include <gwenhywfar/gwenhywfarapi.h>

#ifdef __cplusplus
extern "C" {
#endif


/** @defgroup MOD_RINGBUFFER Ringbuffer Management
 * @ingroup MOD_BASE
 *
 * @brief This file contains the definition of a GWEN_RINGBUFFER.
 *
 */
/*@{*/

typedef struct GWEN_RINGBUFFER GWEN_RINGBUFFER;


/** @name Constructor And Destructor
 *
 */
/*@{*/
/**
 * Creates a new ring buffer
 * @param size maximum size of the ring buffer
 */
GWENHYWFAR_API
GWEN_RINGBUFFER *GWEN_RingBuffer_new(unsigned int size);

/**
 * Destructor.
 */
GWENHYWFAR_API
void GWEN_RingBuffer_free(GWEN_RINGBUFFER *rb);


/** @name Reading And Writing
 *
 */
/*@{*/
/**
 * Writes the given bytes into the ring buffer.
 * @param rb ring buffer
 * @param buffer pointer to bytes to write
 * @param size pointer to a variable that contains the number of bytes
 * to write. Upon return this variable contains the number of bytes actually
 * copied.
 */
GWENHYWFAR_API
int GWEN_RingBuffer_WriteBytes(GWEN_RINGBUFFER *rb,
                               const char *buffer,
                               uint32_t *size);

/**
 * Writes a single byte to the ring buffer.
 */
GWENHYWFAR_API
int GWEN_RingBuffer_WriteByte(GWEN_RINGBUFFER *rb, char c);


/**
 * Read bytes from the ring buffer.
 * @param rb ring buffer
 * @param buffer pointer to the destination buffer
 * @param size pointer to a variable that contains the number of bytes
 * to read. Upon return this variable contains the number of bytes actually
 * copied.
 */
GWENHYWFAR_API
int GWEN_RingBuffer_ReadBytes(GWEN_RINGBUFFER *rb,
                              char *buffer,
                              uint32_t *size);

/**
 * Reads a single byte from the ring buffer.
 */
GWENHYWFAR_API
int GWEN_RingBuffer_ReadByte(GWEN_RINGBUFFER *rb);
/*@}*/


/** @name Informational Functions
 *
 */
/*@{*/
/**
 * Returns the number of bytes stored inside the ring buffer.
 */
GWENHYWFAR_API
uint32_t GWEN_RingBuffer_GetUsedBytes(const GWEN_RINGBUFFER *rb);

/**
 * Returns the number of bytes which still can be stored inside the ring
 * buffer.
 */
GWENHYWFAR_API
uint32_t GWEN_RingBuffer_GetBytesLeft(const GWEN_RINGBUFFER *rb);

/**
 * Returns the size of the ring buffer.
 */
GWENHYWFAR_API
uint32_t GWEN_RingBuffer_GetBufferSize(const GWEN_RINGBUFFER *rb);
/*@}*/



/** @name Statistical Functions
 *
 */
/*@{*/
/**
 * Returns the number of times the buffer was empty.
 */
GWENHYWFAR_API
uint32_t GWEN_RingBuffer_GetEmptyCounter(const GWEN_RINGBUFFER *rb);

GWENHYWFAR_API
void GWEN_RingBuffer_ResetEmptyCounter(GWEN_RINGBUFFER *rb);


/**
 * Returns the number of times the buffer was full.
 */
GWENHYWFAR_API
uint32_t GWEN_RingBuffer_GetFullCounter(const GWEN_RINGBUFFER *rb);

GWENHYWFAR_API
void GWEN_RingBuffer_ResetFullCounter(GWEN_RINGBUFFER *rb);


/**
 * Returns the number of bytes which have passed through this buffer (i.e.
 * bytes that have been written to <strong>and</strong> read from the buffer.
 */
GWENHYWFAR_API
uint32_t GWEN_RingBuffer_GetThroughput(GWEN_RINGBUFFER *rb);

/**
 * Resets the buffers throughput counter to zero.
 */
GWENHYWFAR_API
void GWEN_RingBuffer_ResetThroughput(GWEN_RINGBUFFER *rb);



/**
 * Returns the maximum number of bytes which has been stored in the buffer.
 */
GWENHYWFAR_API
uint32_t GWEN_RingBuffer_GetMaxUsedBytes(const GWEN_RINGBUFFER *rb);

/**
 * Resets the counter for the maximum number of bytes stored in the
 * buffer.
 */
GWENHYWFAR_API
void GWEN_RingBuffer_ResetMaxUsedBytes(GWEN_RINGBUFFER *rb);

GWENHYWFAR_API
void GWEN_RingBuffer_Reset(GWEN_RINGBUFFER *rb);


/*@}*/ /* name */



/** @name Functions For Direct Manipulation Of The Buffer
 *
 * Please use these functions with care. These function are supported in order
 * to avoid unnecessary copying.
 */
/*@{*/
/**
 * Returns the maximum number of bytes which can be read with a following
 * call to @ref GWEN_RingBuffer_ReadBytes. This value (if not 0) can be
 * used for @ref GWEN_RingBuffer_SkipBytesRead.
 */
GWENHYWFAR_API
uint32_t
  GWEN_RingBuffer_GetMaxUnsegmentedRead(GWEN_RINGBUFFER *rb);

/**
 * Returns the maximum number of bytes which can be written with a following
 * call to @ref GWEN_RingBuffer_WriteBytes. This value (if not 0) can be
 * used for @ref GWEN_RingBuffer_SkipBytesWrite.
 */
GWENHYWFAR_API
uint32_t
  GWEN_RingBuffer_GetMaxUnsegmentedWrite(GWEN_RINGBUFFER *rb);

/**
 * Adjusts the internal pointers and statistical data as if
 * @ref GWEN_RingBuffer_ReadBytes had been called. Please note that the
 * size value given here MUST be <= the value returned by
 * @ref GWEN_RingBuffer_GetMaxUnsegmentedRead !
 */
GWENHYWFAR_API
void GWEN_RingBuffer_SkipBytesRead(GWEN_RINGBUFFER *rb,
                                   uint32_t psize);

/**
 * Adjusts the internal pointers and statistical data as if
 * @ref GWEN_RingBuffer_WriteBytes had been called. Please note that the
 * size value given here MUST be <= the value returned by
 * @ref GWEN_RingBuffer_GetMaxUnsegmentedWrite !
 */
GWENHYWFAR_API
void GWEN_RingBuffer_SkipBytesWrite(GWEN_RINGBUFFER *rb,
                                    uint32_t psize);

/**
 * Returne the current read pointer. Please note that the return value of
 * @ref GWEN_RingBuffer_GetMaxUnsegmentedRead indicates the maximum number
 * of bytes at this position available! Trying to access bytes beyond that
 * boundary will most likely result in segmentation faults.
 * Please make sure that you call @ref GWEN_RingBuffer_SkipBytesRead after
 * taking data from the buffer in order to keep the internal structure
 * intact.
 */
GWENHYWFAR_API
const char *GWEN_RingBuffer_GetReadPointer(const GWEN_RINGBUFFER *rb);

/**
 * Returne the current write pointer. Please note that the return value of
 * @ref GWEN_RingBuffer_GetMaxUnsegmentedWrite indicates the maximum number
 * of bytes at this position available! Trying to access bytes beyond that
 * boundary will most likely result in segmentation faults.
 * Please make sure that you call @ref GWEN_RingBuffer_SkipBytesWrite after
 * writing data to the buffer in order to keep the internal structure
 * intact.
 */
GWENHYWFAR_API
char *GWEN_RingBuffer_GetWritePointer(const GWEN_RINGBUFFER *rb);

/*@}*/ /* name */


/*@}*/ /* group */

#ifdef __cplusplus
}
#endif


#endif /* GWEN_RINGBUFFER_H */




