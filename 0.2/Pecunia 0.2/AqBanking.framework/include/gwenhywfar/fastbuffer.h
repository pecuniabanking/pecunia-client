/***************************************************************************
    begin       : Tue Apr 27 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_FASTBUFFER_H
#define GWEN_FASTBUFFER_H


#include <gwenhywfar/syncio.h>
#include <gwenhywfar/buffer.h>


#define GWEN_FAST_BUFFER_FLAGS_DOSMODE 0x00000001


/**
 * Do not use the fields of this struct directly!! Only use it via the functions and macros
 * in this module, because otherwise future versions of you application might not work.
 * Do not allocate such an object yourself, always use @ref GWEN_FastBuffer_new() otherwise
 * future versions of you application might not work!
 * This struct is not part of the API.
 */
typedef struct {
  GWEN_SYNCIO *io;
  uint32_t bufferSize;
  uint32_t bufferReadPos;
  uint32_t bufferWritePos;
  uint32_t flags;
  uint32_t bytesWritten;
  uint32_t bytesRead;
  uint8_t buffer[1];
} GWEN_FAST_BUFFER;



#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API GWEN_FAST_BUFFER *GWEN_FastBuffer_new(uint32_t bsize, GWEN_SYNCIO *io);

GWENHYWFAR_API void GWEN_FastBuffer_free(GWEN_FAST_BUFFER *fb);


GWENHYWFAR_API uint32_t GWEN_FastBuffer_GetFlags(const GWEN_FAST_BUFFER *fb);
GWENHYWFAR_API void GWEN_FastBuffer_SetFlags(GWEN_FAST_BUFFER *fb, uint32_t fl);
GWENHYWFAR_API void GWEN_FastBuffer_AddFlags(GWEN_FAST_BUFFER *fb, uint32_t fl);
GWENHYWFAR_API void GWEN_FastBuffer_SubFlags(GWEN_FAST_BUFFER *fb, uint32_t fl);

GWENHYWFAR_API uint32_t GWEN_FastBuffer_GetBytesWritten(const GWEN_FAST_BUFFER *fb);
GWENHYWFAR_API uint32_t GWEN_FastBuffer_GetBytesRead(const GWEN_FAST_BUFFER *fb);

GWENHYWFAR_API int GWEN_FastBuffer_ReadLine(GWEN_FAST_BUFFER *fb, uint8_t *p, int len);
GWENHYWFAR_API int GWEN_FastBuffer_ReadLineToBuffer(GWEN_FAST_BUFFER *fb, GWEN_BUFFER *buf);


#ifdef __cplusplus
}
#endif


/**
 * This macro peeks at the read buffer and returns the next available byte (if any).
 * Consecutive peeks will always return the same byte. Also, the next @ref GWEN_FASTBUFFER_READBYTE
 * will return the same byte as well.
 */
#define GWEN_FASTBUFFER_PEEKBYTE(fb, var) {\
    if (fb->bufferReadPos>=fb->bufferWritePos) { \
      int fb_peekbyte_rv; \
      \
      fb_peekbyte_rv=GWEN_SyncIo_Read(fb->io, fb->buffer, fb->bufferSize); \
      if (fb_peekbyte_rv<0) { \
        DBG_DEBUG(GWEN_LOGDOMAIN, "here (%d)", fb_peekbyte_rv); \
	var=fb_peekbyte_rv; \
      } \
      else if (fb_peekbyte_rv==0) { \
        DBG_DEBUG(GWEN_LOGDOMAIN, "EOF met"); \
	var=GWEN_ERROR_EOF; \
      } \
      else { \
	fb->bufferWritePos=fb_peekbyte_rv; \
	fb->bufferReadPos=0; \
	var=((int)((fb->buffer[fb->bufferReadPos])) & 0xff); \
      } \
    } \
    else { \
      var=((int)((fb->buffer[fb->bufferReadPos])) & 0xff); \
    } \
  }


/**
 * Returns the next byte from the buffer (if any). That byte will be placed into "var". In case of an error
 * var will contain an error code instead.
 */
#define GWEN_FASTBUFFER_READBYTE(fb, var) {\
    if (fb->bufferReadPos>=fb->bufferWritePos) { \
      int fb_readbyte_rv; \
      \
      fb_readbyte_rv=GWEN_SyncIo_Read(fb->io, fb->buffer, fb->bufferSize); \
      if (fb_readbyte_rv<0) { \
        DBG_DEBUG(GWEN_LOGDOMAIN, "here (%d)", fb_readbyte_rv); \
	var=fb_readbyte_rv; \
      } \
      else if (fb_readbyte_rv==0) { \
        DBG_DEBUG(GWEN_LOGDOMAIN, "EOF met"); \
	var=GWEN_ERROR_EOF; \
      } \
      else { \
	fb->bufferWritePos=fb_readbyte_rv; \
	fb->bufferReadPos=0; \
	var=((int)((fb->buffer[fb->bufferReadPos++])) & 0xff); \
        fb->bytesRead++; \
      } \
    } \
    else { \
      var=((int)((fb->buffer[fb->bufferReadPos++])) & 0xff); \
      fb->bytesRead++; \
    } \
  }


/**
 * Writes a byte into the buffer (flushing it if necessary) and returns the result of this operation
 * in "var".
 */
#define GWEN_FASTBUFFER_WRITEBYTE(fb, var, chr) {\
    if (fb->bufferWritePos>=fb->bufferSize) { \
      int fb_writeByte_rv; \
      \
      fb_writeByte_rv=GWEN_SyncIo_WriteForced(fb->io, fb->buffer, fb->bufferWritePos); \
      if (fb_writeByte_rv<(int)(fb->bufferWritePos)) { \
        DBG_INFO(GWEN_LOGDOMAIN, "here (%d)", fb_writeByte_rv); \
	var=fb_writeByte_rv; \
      } \
      else { \
        var=0; \
	fb->bufferWritePos=0; \
	fb->buffer[fb->bufferWritePos++]=chr; \
        fb->bytesWritten++; \
      } \
    } \
    else { \
      var=0; \
      fb->buffer[fb->bufferWritePos++]=chr; \
      fb->bytesWritten++; \
    } \
  }


/**
 * Flushes the write buffer (i.e. write all remaining bytes from the buffer to the io layer with
 * the flag @ref GWEN_IO_REQUEST_FLAGS_FLUSH set).
 */
#define GWEN_FASTBUFFER_FLUSH(fb, var) {\
    int fb_flush_rv; \
    \
    fb_flush_rv=GWEN_SyncIo_WriteForced(fb->io, fb->buffer, fb->bufferWritePos); \
    if (fb_flush_rv<(int)(fb->bufferWritePos)) { \
      DBG_INFO(GWEN_LOGDOMAIN, "here (%d)", fb_flush_rv); \
      var=fb_flush_rv; \
    } \
    else { \
      var=0; \
      fb->bufferWritePos=0; \
    } \
  }


/**
 * Reads a number of bytes from the buffer and stores it at the given memory location.
 * @param fb fast buffer
 * @param var variable to receive the result (<0: error code, number of bytes read otherwise)
 * @param p pointer to the location to read the bytes to
 * @param len number of bytes to read
 */
#define GWEN_FASTBUFFER_READBYTES(fb, var, p, len) { \
  int fb_readbyte_bytes;\
  \
  var=0; \
  if (fb->bufferReadPos>=fb->bufferWritePos) { \
    int fb_readbyte_rv; \
    \
    fb_readbyte_rv=GWEN_SyncIo_Read(fb->io, fb->buffer, fb->bufferSize); \
    if (fb_readbyte_rv<0) { \
      DBG_DEBUG(GWEN_LOGDOMAIN, "here (%d)", fb_readbyte_rv); \
      var=fb_readbyte_rv; \
    } \
    else {\
      fb->bufferWritePos=fb_readbyte_rv; \
      fb->bufferReadPos=0; \
    }\
  }\
  if (var==0) {\
    fb_readbyte_bytes=fb->bufferWritePos-fb->bufferReadPos;\
    if (fb_readbyte_bytes>len)\
      fb_readbyte_bytes=len;\
    if (fb_readbyte_bytes) {\
      memmove(p, fb->buffer+fb->bufferReadPos, fb_readbyte_bytes);\
      fb->bufferReadPos+=fb_readbyte_bytes;\
      fb->bytesRead+=fb_readbyte_bytes; \
    }\
    var=fb_readbyte_bytes;\
  }\
}



#define GWEN_FASTBUFFER_READLINE(fb, var, p, len) {\
  int fb_readline_bytes;\
  \
  var=0;\
  if (fb->bufferReadPos>=fb->bufferWritePos) {\
    int fb_readline_rv;\
    \
    fb_readline_rv=GWEN_SyncIo_Read(fb->io, fb->buffer, fb->bufferSize);\
    if (fb_readline_rv<0) {\
      DBG_DEBUG(GWEN_LOGDOMAIN, "here (%d)", fb_readline_rv);\
      var=fb_readline_rv;\
    }\
    else {\
      fb->bufferWritePos=fb_rv; \
      fb->bufferReadPos=0; \
    }\
  }\
  if (var==0) {\
    fb_readline_bytes=fb->bufferWritePos-fb->bufferReadPos;\
    if (fb_readline_bytes>len)\
      fb_readline_bytes=len;\
    if (fb_readline_bytes) {\
      uint8_t *fb_readline_p;\
      \
      fb_readline_p=(uint8_t*)p;\
      \
      while(fb_readline_bytes) {\
	uint8_t c;\
        \
	c=fb->buffer[fb->bufferReadPos++];\
        fb->bytesRead++; \
	fb_readline_bytes--;\
        if (c==10) {\
	  *(fb_readline_p++)=c;\
	  var++;\
	  break;\
        }\
	else if (c!=13) {\
	  *(fb_readline_p++)=c;\
	  var++;\
	}\
      }\
    }\
  }\
}



#define GWEN_FASTBUFFER_READLINEFORCED(fb, var, p, len) {\
  int fb_readlineforced_len;\
  uint8_t *fb_readlineforced_p;\
  \
  fb_readlineforced_len=len;\
  fb_readlineforced_p=(uint8_t*)p;\
  var=0;\
  while(fb_readlineforced_len && var==0) {\
    int fb_readlineforced_rv;\
    \
    GWEN_FASTBUFFER_READLINE(fb, fb_readlineforced_rv, fb_readlineforced_p, fb_readlineforced_len);\
    if (fb_readlineforced_rv<0) {\
      var=fb_readlineforced_rv;\
      break;\
    }\
    else if (fb_readlineforced_rv==0) {\
      var=GWEN_ERROR_EOF;\
      break;\
    }\
    else {\
      if (fb_readlineforced_p[fb_readlineforced_rv-1]==10) {\
        fb_readlineforced_p[fb_readlineforced_rv-1]=0;\
        var=fb_readlineforced_rv;\
        break;\
      }\
      fb_readlineforced_len-=fb_readlineforced_rv;\
      fb_readlineforced_p+=fb_readlineforced_rv;\
    }\
  }\
  if (var==0) {\
    DBG_INFO(GWEN_LOGDOMAIN, "No line within %d bytes", len);\
    var=GWEN_ERROR_BAD_SIZE;\
  }\
}



#define GWEN_FASTBUFFER_READFORCED(fb, var, p, len) {\
  int fb_readforced_len;\
  uint8_t *fb_readforced_p;\
  \
  fb_readforced_len=len;\
  fb_readforced_p=(uint8_t*)p;\
  var=0;\
  while(fb_readforced_len && var==0) {\
    int fb_readforced_rv;\
    \
    GWEN_FASTBUFFER_READBYTES(fb, fb_readforced_rv, fb_readforced_p, fb_readforced_len);\
    if (fb_readforced_rv<0) {\
      var=fb_readforced_rv;\
      break;\
    }\
    else if (fb_readforced_rv==0) {\
      var=GWEN_ERROR_EOF;\
      break;\
    }\
    else {\
      fb_readforced_len-=fb_readforced_rv;\
      fb_readforced_p+=fb_readforced_rv;\
    }\
  }\
}



/**
 * Write a number of bytes to the buffer and stores it at the given memory location.
 * @param fb fast buffer
 * @param var variable to receive the result (<0: error code, number of bytes read otherwise)
 * @param p pointer to the location to write the bytes from
 * @param len number of bytes to write
 */
#define GWEN_FASTBUFFER_WRITEBYTES(fb, var, p, len) {\
  int fb_writebytes_bytes;\
  int fb_writebytes_len;\
  \
  fb_writebytes_len=len;\
  if (fb_writebytes_len==-1)\
    fb_writebytes_len=strlen((const char*)p);\
  var=0; \
  if (fb->bufferWritePos>=fb->bufferSize) { \
    int fb_writebytes_rv; \
    \
    fb_writebytes_rv=GWEN_SyncIo_WriteForced(fb->io, fb->buffer, fb->bufferWritePos); \
    if (fb_writebytes_rv<(int)(fb->bufferWritePos)) { \
      DBG_DEBUG(GWEN_LOGDOMAIN, "here (%d)", fb_writebytes_rv); \
      var=fb_writebytes_rv; \
    } \
    else {\
      fb->bufferWritePos=0; \
    }\
  }\
  if (var==0) {\
    fb_writebytes_bytes=fb->bufferSize-fb->bufferWritePos;\
    if (fb_writebytes_bytes>fb_writebytes_len)\
      fb_writebytes_bytes=fb_writebytes_len;\
    if (fb_writebytes_bytes) {\
      memmove(fb->buffer+fb->bufferWritePos, p, fb_writebytes_bytes);\
      fb->bufferWritePos+=fb_writebytes_bytes;\
      fb->bytesWritten+=fb_writebytes_bytes; \
    }\
    var=fb_writebytes_bytes;\
  }\
}


/**
 * Write a number of bytes to the buffer and make sure that @b all bytes are written.
 * @param fb fast buffer
 * @param var variable to receive the result (<0: error code, 0 on success)
 * @param p pointer to the location to write the bytes from
 * @param len number of bytes to write
 */
#define GWEN_FASTBUFFER_WRITEFORCED(fb, var, p, len) {\
  int fb_writeforced_len;\
  const uint8_t *fb_writeforced_p;\
  \
  fb_writeforced_len=len;\
  if (fb_writeforced_len==-1) \
    fb_writeforced_len=strlen((const char*)p);\
  fb_writeforced_p=(const uint8_t*)p;\
  var=0;\
  while(fb_writeforced_len && var==0) {\
    int fb_writeforced_rv;\
    \
    GWEN_FASTBUFFER_WRITEBYTES(fb, fb_writeforced_rv, fb_writeforced_p, fb_writeforced_len);\
    if (fb_writeforced_rv<0) {\
      var=fb_writeforced_rv;\
      break;\
    }\
    else if (fb_writeforced_rv==0) {\
      var=GWEN_ERROR_EOF;\
      break;\
    }\
    else {\
      fb_writeforced_len-=fb_writeforced_rv;\
      fb_writeforced_p+=fb_writeforced_rv;\
    }\
  }\
}



#define GWEN_FASTBUFFER_WRITELINE(fb, var, p) {\
  int fb_writeline_rv;\
  int fb_writeline_len=strlen((const char*)p);\
  \
  GWEN_FASTBUFFER_WRITEFORCED(fb, fb_writeline_rv, p, fb_writeline_len);\
  if (fb_writeline_rv<0)\
    var=fb_writeline_rv;\
  else {\
    if (fb->flags & GWEN_FAST_BUFFER_FLAGS_DOSMODE) {\
       GWEN_FASTBUFFER_WRITEFORCED(fb, fb_writeline_rv, "\r\n", 2);\
    }\
    else {\
       GWEN_FASTBUFFER_WRITEFORCED(fb, fb_writeline_rv, "\n", 1);\
    }\
    if (fb_writeline_rv<0)\
      var=fb_writeline_rv;\
    else\
      var=0;\
  }\
}



/**
 * Copy a number of bytes from one buffer to another one.
 * @param fb1 source fast buffer
 * @param fb2 destination fast buffer
 * @param var variable to receive the result (<0: error code, number of bytes read otherwise)
 * @param len number of bytes to copy
 */
#define GWEN_FASTBUFFER_COPYBYTES(fb1, fb2, var, len) { \
  int fb_copybytes_bytes;\
  \
  var=0; \
  if (fb1->bufferReadPos>=fb1->bufferWritePos) { \
    int fb_copybytes_rv; \
    \
    fb_copybytes_rv=GWEN_SyncIo_Read(fb1->io, fb1->buffer, fb1->bufferSize); \
    if (fb_copybytes_rv<0) { \
      DBG_DEBUG(GWEN_LOGDOMAIN, "here (%d)", fb_copybytes_rv); \
      var=fb_copybytes_rv; \
    } \
    else {\
      fb1->bufferWritePos=fb_copybytes_rv; \
      fb1->bufferReadPos=0; \
    }\
  }\
  if (var==0) {\
    fb_bytes=fb1->bufferWritePos-fb1->bufferReadPos;\
    if (fb_copybytes_bytes>len)\
      fb_copybytes_bytes=len;\
    if (fb_copybytes_bytes) {\
      int fb_copybytes_rv;\
      \
      GWEN_FASTBUFFER_WRITEBYTES(fb2, fb_copybytes_rv, (fb1->buffer+fb1->bufferReadPos), fb_bytes);\
      var=fb_copybytes_rv;\
      if (fb_copybytes_rv>0) {\
	fb1->bufferReadPos+=fb_copybytes_rv;\
        fb1->bytesRead+=fb_copybytes_rv; \
      }\
    }\
  }\
}



/**
 * Copy a number of bytes to the buffer and make sure that @b all bytes are copied.
 * @param fb1 source fast buffer
 * @param fb2 destination fast buffer
 * @param var variable to receive the result (<0: error code, 0 on success)
 * @param p pointer to the location to write the bytes from
 * @param len number of bytes to copy
 */
#define GWEN_FASTBUFFER_COPYFORCED(fb1, fb2, var, p, len) {\
  int fb_copyforced_len;\
  uint8_t *fb_copyforced_p;\
  \
  fb_copyforced_len=len;\
  fb_copyforced_p=(uint8_t*)p;\
  var=0;\
  while(fb_copyforced_len && var==0) {\
    int fb_copyforced_rv;\
    \
    GWEN_FASTBUFFER_COPYBYTES(fb1, fb2, fb_copyforced_rv, fb_copyforced_p, fb_copyforced_len);\
    if (fb_copyforced_rv<0) {\
      var=fb_copyforced_rv;\
      break;\
    }\
    else if (fb_copyforced_rv==0)\
      var=GWEN_ERROR_EOF;\
    else {\
      fb_len-=fb_copyforced_rv;\
      fb_p+=fb_copyforced_rv;\
    }\
  }\
}




#endif



