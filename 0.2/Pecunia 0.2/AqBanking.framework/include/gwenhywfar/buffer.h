/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Fri Sep 12 2003
    copyright   : (C) 2003 by Martin Preuss
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


#ifndef GWENHYWFAR_BUFFER_H
#define GWENHYWFAR_BUFFER_H

#include <gwenhywfar/gwenhywfarapi.h>
#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief A dynamically resizeable text buffer.
 *
 * @ingroup MOD_BUFFER
 */
typedef struct GWEN_BUFFER GWEN_BUFFER;
#ifdef __cplusplus
}
#endif

#include <gwenhywfar/types.h>
#include <gwenhywfar/syncio.h>


#include <stdio.h>
/* This is needed for PalmOS, because it define some functions needed */
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup MOD_BUFFER Buffer Management
 * @ingroup MOD_BASE
 *
 * @brief This file contains the definition of a GWEN_BUFFER, a
 * dynamically resizeable text buffer.
 *
 */
/*@{*/

#define GWEN_BUFFER_MAX_BOOKMARKS 64

#define GWEN_BUFFER_MODE_DYNAMIC          0x0001
#define GWEN_BUFFER_MODE_ABORT_ON_MEMFULL 0x0002
#define GWEN_BUFFER_MODE_USE_SYNCIO       0x0010
#define GWEN_BUFFER_MODE_READONLY         0x0020

#define GWEN_BUFFER_MODE_DEFAULT \
  (\
  GWEN_BUFFER_MODE_DYNAMIC | \
  GWEN_BUFFER_MODE_ABORT_ON_MEMFULL\
  )


/**
 * Creates a new GWEN_BUFFER, which is a dynamically resizeable
 * text buffer.
 *
 * @param buffer If non-NULL, then this buffer will be used as
 * actual storage space. Otherwise a new buffer will be allocated
 * (with @c size bytes)
 *
 * @param size If @c buffer was non-NULL, then this argument
 * <i>must</i> specifiy the size of that buffer. If @c buffer was
 * NULL, then this argument specifies the number of bytes that
 * will be allocated.
 *
 * @param used Number of bytes of the buffer actually used. This is
 * interesting when reading from a buffer.
 *
 * @param take_ownership If @c buffer was non-NULL and this
 * argument is nonzero, then the new GWEN_BUFFER object takes over
 * the ownership of the given @c buffer so that it will be freed
 * on GWEN_Buffer_free(). If this argument is zero, the given @c
 * buffer will not be freed. If @c buffer was NULL, this argument
 * has no effect.
 */
GWENHYWFAR_API
GWEN_BUFFER *GWEN_Buffer_new(char *buffer,
                             uint32_t size,
                             uint32_t used,
                             int take_ownership);

/** Frees the given buffer. 
 *
 * If the internal storage was allocated for this new buffer, then
 * it will freed here. If the internal storage is used from a
 * different @c buffer, then it will only be freed if the argument
 * @c take_ownership of GWEN_Buffer_new() was nonzero. */
GWENHYWFAR_API
void GWEN_Buffer_free(GWEN_BUFFER *bf);


/** Create a new copy as a duplicate of the buffer @c bf. */
GWENHYWFAR_API
GWEN_BUFFER *GWEN_Buffer_dup(GWEN_BUFFER *bf);


/** This function relinquishes ownership of the internal buffer
 * if possible. It returns an error if this object does not own the
 * buffer (it can't give you what it doesn't possess) or if the
 * internal pointer to the memory allocated does not match the internal
 * pointer to the current start of the buffer (this can be the case
 * when @ref GWEN_Buffer_ReserveBytes() of @ref GWEN_Buffer_Crop()
 * have been called).
 */
GWENHYWFAR_API
int GWEN_Buffer_Relinquish(GWEN_BUFFER *bf);

/**
 * Returns the current mode of the buffer
 * (such as  @ref GWEN_BUFFER_MODE_DYNAMIC).
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetMode(GWEN_BUFFER *bf);

/**
 * Changes the current mode of the buffer
 * (such as  @ref GWEN_BUFFER_MODE_DYNAMIC).
 */
GWENHYWFAR_API
void GWEN_Buffer_SetMode(GWEN_BUFFER *bf, uint32_t mode);

/**
 * Adds the give mode to the current mode of the buffer
 * (such as  @ref GWEN_BUFFER_MODE_DYNAMIC).
 */
GWENHYWFAR_API
void GWEN_Buffer_AddMode(GWEN_BUFFER *bf, uint32_t mode);

/**
 * Removes the give mode from the current mode of the buffer
 * (such as  @ref GWEN_BUFFER_MODE_DYNAMIC).
 */
GWENHYWFAR_API
void GWEN_Buffer_SubMode(GWEN_BUFFER *bf, uint32_t mode);

/**
 * Returns the hard limit. This is the maximum size of a GWEN_BUFFER in
 * dynamic mode.
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetHardLimit(GWEN_BUFFER *bf);

/**
 * Changes the hard limit. This is the maximum size of a GWEN_BUFFER in
 * dynamic mode.
 */
GWENHYWFAR_API
void GWEN_Buffer_SetHardLimit(GWEN_BUFFER *bf, uint32_t l);


/**
 * In dynamic mode, whenever there is new data to allocate then this value
 * specifies how much data to allocate in addition.
 * The allocated data in total for this buffer will be aligned to this value.
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetStep(GWEN_BUFFER *bf);

/**
 * In dynamic mode, whenever there is new data to allocate then this value
 * specifies how much data to allocate in addition.
 * The allocated data in total for this buffer will be aligned to this value.
 * 1024 is a reasonable value. This value NEEDS to be aligned 2^n (i.e.
 * only ONE bit must be set !)
 */
GWENHYWFAR_API
void GWEN_Buffer_SetStep(GWEN_BUFFER *bf, uint32_t step);


/**
 * Reserves the given amount of bytes at the beginning of the buffer.
 * Please note that this most likely results in a shift of the current
 * position inside the buffer, so after this call all pointers obtained
 * from this module (e.g. via @ref GWEN_Buffer_GetStart) are invalid !
 * You can use this function to save some memory copy actions when
 * inserting bytes at the beginning of the buffer.
 */
GWENHYWFAR_API
int GWEN_Buffer_ReserveBytes(GWEN_BUFFER *bf, uint32_t res);


/**
 * Returns the start of the buffer. You can use the function
 * @ref GWEN_Buffer_GetPos to navigate within the buffer.
 */
GWENHYWFAR_API
char *GWEN_Buffer_GetStart(GWEN_BUFFER *bf);


/**
 * Returns the size of the buffer (i.e. the number of bytes allocated).
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetSize(GWEN_BUFFER *bf);


/**
 * Returns the current position within the buffer. This pointer is adjusted
 * by the various read and write functions.
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetPos(GWEN_BUFFER *bf);

/**
 * @return 0 if ok, !=0 on error
 */
GWENHYWFAR_API
int GWEN_Buffer_SetPos(GWEN_BUFFER *bf, uint32_t i);

/**
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetUsedBytes(GWEN_BUFFER *bf);


/**
 * Returns the given bookmark
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetBookmark(GWEN_BUFFER *bf, unsigned int idx);


/**
 * Set a bookmark. These bookmarks are not used by the GWEN_BUFFER functions,
 * but may be usefull for an application.
 */
GWENHYWFAR_API
void GWEN_Buffer_SetBookmark(GWEN_BUFFER *bf, unsigned int idx,
                             uint32_t v);


/**
 * Copies the contents of the given buffer to this GWEN_BUFFER, if there is
 * enough room.
 * The position pointer is adjusted accordingly.
 * @return 0 if ok, !=0 on error
 */
GWENHYWFAR_API
int GWEN_Buffer_AppendBytes(GWEN_BUFFER *bf,
                            const char *buffer,
                            uint32_t size);

GWENHYWFAR_API
int GWEN_Buffer_FillWithBytes(GWEN_BUFFER *bf,
                              unsigned char c,
                              uint32_t size);

GWENHYWFAR_API
int GWEN_Buffer_FillLeftWithBytes(GWEN_BUFFER *bf,
                                  unsigned char c,
                                  uint32_t size);


/**
 * Appends a string to the buffer (without the trailing null char!)
 * The position pointer is adjusted accordingly.
 * @return 0 if ok, !=0 on error
 */
GWENHYWFAR_API
  int GWEN_Buffer_AppendString(GWEN_BUFFER *bf,
                               const char *buffer);


/**
 * Appends a single byte to this GWEN_BUFFER, if there is
 * enough room.
 * The position pointer is adjusted accordingly.
 * @return 0 if ok, !=0 on error
 */
GWENHYWFAR_API
int GWEN_Buffer_AppendByte(GWEN_BUFFER *bf, char c);

/**
 * Inserts multiple bytes at the current position.
 * If the current position is 0 and there is reserved space at the beginning
 * of the buffer then that space will be used.
 * Otherwise the data at the current position will be moved out of the way
 * and the new bytes inserted.
 * The position pointer will not be altered, but all pointers obtained from
 * this module (e.g. via @ref GWEN_Buffer_GetStart) become invalid !
 */
GWENHYWFAR_API
int GWEN_Buffer_InsertBytes(GWEN_BUFFER *bf,
                            const char *buffer,
                            uint32_t size);

/**
 * This function makes room for the given number of bytes at the current
 * buffer position. It moves any existing data at the current position
 * out of the way.
 * The position pointer will not be altered, but after calling this function
 * at that position there is the begin of the newly inserted room.
 * All pointers obtained from this module (e.g. via
 * @ref GWEN_Buffer_GetStart) become invalid !
 * This function updates the bookmarks accordingly.
 */
GWENHYWFAR_API
int GWEN_Buffer_InsertRoom(GWEN_BUFFER *bf,
                           uint32_t size);

/**
 * This function removes the given number of bytes at the current
 * buffer position. It moves any existing bytes behind the area to be removed
 * to the current position.
 * The position pointer will not be altered, but after calling this function
 * at that position there is the begin of the data behind the removed area.
 * All pointers obtained from this module (e.g. via
 * @ref GWEN_Buffer_GetStart) become invalid !
 * This function updates the bookmarks accordingly.
 */
GWENHYWFAR_API
int GWEN_Buffer_RemoveRoom(GWEN_BUFFER *bf, uint32_t size);

/**
 * This function remplaces the given number of bytes at the current
 * buffer position with some new bytes. If the number of bytes to be replaced
 * does not equal the number of replacement bytes then the buffer is resized
 * accordingly (e.g. shrunk or extended).
 * The position pointer will not be altered.
 * All pointers obtained from this module (e.g. via
 * @ref GWEN_Buffer_GetStart) become invalid !
 * This function updates the bookmarks accordingly.
 */
GWENHYWFAR_API
int GWEN_Buffer_ReplaceBytes(GWEN_BUFFER *bf,
			     uint32_t rsize,
			     const char *buffer,
			     uint32_t size);


/**
 * Inserts the given string at the current position (without the trailing
 * null byte)
 * The position pointer will not be altered, but after calling this function
 * at that position there is the begin of the newly inserted string.
 * All pointers obtained from this module (e.g. via
 * @ref GWEN_Buffer_GetStart) become invalid !
 * This function updates the bookmarks accordingly.
 */
GWENHYWFAR_API
int GWEN_Buffer_InsertString(GWEN_BUFFER *bf,
                             const char *buffer);

/**
 * Inserts a byte at the current position.
 * If the current position is 0 and there is reserved space at the beginning
 * of the buffer then that space will be used.
 * Otherwise the data at the current position will be moved out of the way
 * and the new byte inserted.
 * The position pointer will not be altered, but after calling this function
 * at that position there is the begin of the newly inserted byte.
 * All pointers obtained from this module (e.g. via
 * @ref GWEN_Buffer_GetStart) become invalid !
 * This function updates the bookmarks accordingly.
 */
GWENHYWFAR_API
int GWEN_Buffer_InsertByte(GWEN_BUFFER *bf, char c);

/**
 * Returns the byte from the current position.
 * The position pointer is adjusted accordingly.
 * @return -1 on error, read char otherwise (in low byte)
 */
GWENHYWFAR_API
int GWEN_Buffer_ReadByte(GWEN_BUFFER *bf);


/**
 * Returns the bytes from the current position.
 * The position pointer is adjusted accordingly.
 * @return -1 on error, 0 if ok
 */
GWENHYWFAR_API
int GWEN_Buffer_ReadBytes(GWEN_BUFFER *bf,
                          char *buffer,
                          uint32_t *size);


/**
 * Returns the byte from the current position without changing the
 * position pointer. So multiple calls to this function will result
 * in returning the same character.
 * @return -1 on error, read char otherwise (in low byte)
 */
GWENHYWFAR_API
int GWEN_Buffer_PeekByte(GWEN_BUFFER *bf);


/** Move the position pointer forward by the given number @c i. */
GWENHYWFAR_API
int GWEN_Buffer_IncrementPos(GWEN_BUFFER *bf, uint32_t i);

/** Move the position pointer backward by the given number @c i. */
GWENHYWFAR_API
int GWEN_Buffer_DecrementPos(GWEN_BUFFER *bf, uint32_t i);

/**
 * The functions @ref GWEN_Buffer_IncrementPos and @ref GWEN_Buffer_DecrementPos
 * only modify the internal position pointer.
 * This function here adjusts the number of used bytes to just before the internal
 * position pointer. This is often used to avoid copying, like in the following
 * example:
 * @code
 *
 * char *p;
 * int i;
 *
 * for (i=0; i<100; i++) {
 *   GWEN_Buffer_AllocRoom(buffer, 512);
 *   p=GWEN_Buffer_GetPosPtr(buffer);
 *   READ_512_BYTES_TO_P;
 *   GWEN_Buffer_IncrementPos(buffer, 512);
 *   GWEN_Buffer_AdjustUsedBytes(buffer);
 * }
 *
 * @endcode
 *
 */
GWENHYWFAR_API
int GWEN_Buffer_AdjustUsedBytes(GWEN_BUFFER *bf);


/** Insert the content of the buffer @c sf into the buffer @c bf
 * at the position of its current position pointer. The size of @c
 * bf will be increased accordingly. Returns zero on success or
 * nonzero if this failed (e.g. because of out of memory
 * error). */
GWENHYWFAR_API
int GWEN_Buffer_InsertBuffer(GWEN_BUFFER *bf,
                             GWEN_BUFFER *sf);

/** Append the content of the buffer @c sf at the end of the
 * buffer @c bf. The size of @c bf will be increased
 * accordingly. Returns zero on success or nonzero if this failed
 * (e.g. because of out of memory error). */
GWENHYWFAR_API
int GWEN_Buffer_AppendBuffer(GWEN_BUFFER *bf,
                             GWEN_BUFFER *sf);


/**
 * Returns the maximum number of bytes which can be written to the buffer
 * at once (i.e. without reallocation).
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetMaxUnsegmentedWrite(GWEN_BUFFER *bf);


/**
 * Returns the number of bytes from pos to the end of the used area.
 */
GWENHYWFAR_API
uint32_t GWEN_Buffer_GetBytesLeft(GWEN_BUFFER *bf);


/**
 * Returns a pointer to the current position within the buffer.
 */
GWENHYWFAR_API
char *GWEN_Buffer_GetPosPointer(GWEN_BUFFER *bf);


/**
 * Resets the position pointer and the byte counter.
 */
GWENHYWFAR_API
void GWEN_Buffer_Reset(GWEN_BUFFER *bf);

/**
 * Resets the pos pointer
 */
GWENHYWFAR_API
void GWEN_Buffer_Rewind(GWEN_BUFFER *bf);


/**
 * Make sure that the buffer has enough room for the given bytes.
 */
GWENHYWFAR_API
int GWEN_Buffer_AllocRoom(GWEN_BUFFER *bf, uint32_t size);


/* crops the buffer to the specified bytes */
GWENHYWFAR_API
int GWEN_Buffer_Crop(GWEN_BUFFER *bf,
                     uint32_t pos,
                     uint32_t l);


/**
 * Sets the syncio to be used as a source.
 * This io layer is used when a byte is to be returned while the buffer is
 * empty (or the end of the buffer is reached). In such a case the missing
 * bytes are read from this io layer if the mode contains
 * @ref GWEN_BUFFER_MODE_USE_SYNCIO.
 */
GWENHYWFAR_API
void GWEN_Buffer_SetSourceSyncIo(GWEN_BUFFER *bf,
				 GWEN_SYNCIO *sio,
				 int take);


/** Print the current content of buffer @c bf into the file @c f. */
GWENHYWFAR_API
void GWEN_Buffer_Dump(GWEN_BUFFER *bf, FILE *f, unsigned int insert);


/*@}*/

#ifdef __cplusplus
}
#endif

#endif






