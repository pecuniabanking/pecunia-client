/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id: card.h 163 2006-02-15 19:31:45Z aquamaniac $
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CLIENT_CARD_IMP_H
#define CHIPCARD_CLIENT_CARD_IMP_H


/** @addtogroup chipcardc_card_cd
 */
/*@{*/

#include <chipcard/card.h>

#ifdef __cplusplus
extern "C" {
#endif

GWEN_LIST_FUNCTION_LIB_DEFS(LC_CARD, LC_Card, CHIPCARD_API)

/** @name Prototypes of Virtual Functions
 *
 */
/*@{*/
typedef LC_CLIENT_RESULT CHIPCARD_CB (*LC_CARD_OPEN_FN)(LC_CARD *card);
typedef LC_CLIENT_RESULT CHIPCARD_CB (*LC_CARD_CLOSE_FN)(LC_CARD *card);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_GETPINSTATUS_FN)(LC_CARD *card,
                             unsigned int pid,
                             int *maxErrors,
                             int *currentErrors);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_GETINITIALPIN_FN)(LC_CARD *card,
                              int id,
                              unsigned char *buffer,
                              unsigned int maxLen,
                              unsigned int *pinLength);


typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOREADBINARY_FN)(LC_CARD *card,
                              uint32_t flags,
                              int offset,
                              int size,
                              GWEN_BUFFER *buf);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOWRITEBINARY_FN)(LC_CARD *card,
                               uint32_t flags,
                               int offset,
                               const char *ptr,
                               unsigned int size);


typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOUPDATEBINARY_FN)(LC_CARD *card,
                                uint32_t flags,
                                int offset,
                                const char *ptr,
                                unsigned int size);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOERASEBINARY_FN)(LC_CARD *card,
                               uint32_t flags,
                               int offset,
                               unsigned int size);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOREADRECORD_FN)(LC_CARD *card,
                              uint32_t flags,
                              int recNum,
                              GWEN_BUFFER *buf);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOWRITERECORD_FN)(LC_CARD *card,
                               uint32_t flags,
                               int recNum,
                               const char *ptr,
                               unsigned int size);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOAPPENDRECORD_FN)(LC_CARD *card,
                                uint32_t flags,
                                const char *ptr,
                                unsigned int size);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOUPDATERECORD_FN)(LC_CARD *card,
                                uint32_t flags,
                                int recNum,
                                const char *ptr,
                                unsigned int size);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOVERIFYPIN_FN)(LC_CARD *card,
                             uint32_t flags,
                             const LC_PININFO *pi,
                             const unsigned char *ptr,
                             unsigned int size,
                             int *triesLeft);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOMODIFYPIN_FN)(LC_CARD *card,
                             uint32_t flags,
                             const LC_PININFO *pi,
                             const unsigned char *oldptr,
                             unsigned int oldsize,
                             const unsigned char *newptr,
                             unsigned int newsize,
                             int *triesLeft);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOPERFORMVERIFICATION_FN)(LC_CARD *card,
                                       uint32_t flags,
                                       const LC_PININFO *pi,
                                       int *triesLeft);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOPERFORMMODIFICATION_FN)(LC_CARD *card,
                                       uint32_t flags,
                                       const LC_PININFO *pi,
                                       int *triesLeft);


typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOMANAGESE_FN)(LC_CARD *card,
                            int tmpl,
                            int kids, int kidp,
                            int ar);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOSIGN_FN)(LC_CARD *card,
                        const char *ptr,
                        unsigned int size,
                        GWEN_BUFFER *sigBuf);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOVERIFY_FN)(LC_CARD *card,
                          const char *dptr,
                          unsigned int dsize,
                          const char *sigptr,
                          unsigned int sigsize);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISOENCIPHER_FN)(LC_CARD *card,
                            const char *ptr,
                            unsigned int size,
                            GWEN_BUFFER *codeBuf);

typedef LC_CLIENT_RESULT CHIPCARD_CB
  (*LC_CARD_ISODECIPHER_FN)(LC_CARD *card,
                            const char *ptr,
                            unsigned int size,
                            GWEN_BUFFER *codeBuf);

/*@}*/


CHIPCARD_API
void LC_Card_SetReaderType(LC_CARD *cd, const char *s);

CHIPCARD_API
void LC_Card_SetDriverType(LC_CARD *cd, const char *s);

CHIPCARD_API
void LC_Card_ResetCardId(LC_CARD *cd);

CHIPCARD_API
int LC_Card_AddCardType(LC_CARD *cd, const char *s);

CHIPCARD_API
void LC_Card_SetLastResult(LC_CARD *cd,
                           const char *result,
                           const char *text,
                           int sw1, int sw2);




/** @name Setters for Virtual Functions
 *
 * Functions in this group set or get pointers for virtual functions and
 * will only be used by inheriting classes.
 */
/*@{*/

CHIPCARD_API
LC_CARD_OPEN_FN LC_Card_GetOpenFn(const LC_CARD *card);

CHIPCARD_API
void LC_Card_SetOpenFn(LC_CARD *card, LC_CARD_OPEN_FN fn);

CHIPCARD_API
LC_CARD_CLOSE_FN LC_Card_GetCloseFn(const LC_CARD *card);

CHIPCARD_API
void LC_Card_SetCloseFn(LC_CARD *card, LC_CARD_CLOSE_FN fn);

CHIPCARD_API
LC_CARD_OPEN_FN LC_Card_GetOpenFn(const LC_CARD *card);

CHIPCARD_API
void LC_Card_SetOpenFn(LC_CARD *card, LC_CARD_OPEN_FN fn);

CHIPCARD_API
LC_CARD_CLOSE_FN LC_Card_GetCloseFn(const LC_CARD *card);

CHIPCARD_API
void LC_Card_SetCloseFn(LC_CARD *card, LC_CARD_CLOSE_FN fn);

CHIPCARD_API
void LC_Card_SetGetInitialPinFn(LC_CARD *card, LC_CARD_GETINITIALPIN_FN fn);

CHIPCARD_API
void LC_Card_SetGetPinStatusFn(LC_CARD *card, LC_CARD_GETPINSTATUS_FN fn);

CHIPCARD_API
void LC_Card_SetIsoReadBinaryFn(LC_CARD *card, LC_CARD_ISOREADBINARY_FN f);

CHIPCARD_API
void LC_Card_SetIsoWriteBinaryFn(LC_CARD *card, LC_CARD_ISOWRITEBINARY_FN f);

CHIPCARD_API
void LC_Card_SetIsoUpdateBinaryFn(LC_CARD *card, LC_CARD_ISOUPDATEBINARY_FN f);

CHIPCARD_API
void LC_Card_SetIsoEraseBinaryFn(LC_CARD *card, LC_CARD_ISOERASEBINARY_FN f);

CHIPCARD_API
void LC_Card_SetIsoReadRecordFn(LC_CARD *card, LC_CARD_ISOREADRECORD_FN f);

CHIPCARD_API
void LC_Card_SetIsoWriteRecordFn(LC_CARD *card, LC_CARD_ISOWRITERECORD_FN f);

CHIPCARD_API
void LC_Card_SetIsoUpdateRecordFn(LC_CARD *card, LC_CARD_ISOUPDATERECORD_FN f);

CHIPCARD_API
void LC_Card_SetIsoAppendRecordFn(LC_CARD *card, LC_CARD_ISOAPPENDRECORD_FN f);

CHIPCARD_API
void LC_Card_SetIsoVerifyPinFn(LC_CARD *card, LC_CARD_ISOVERIFYPIN_FN f);

CHIPCARD_API
void LC_Card_SetIsoModifyPinFn(LC_CARD *card, LC_CARD_ISOMODIFYPIN_FN f);

CHIPCARD_API
void LC_Card_SetIsoPerformVerificationFn(LC_CARD *card,
                                         LC_CARD_ISOPERFORMVERIFICATION_FN f);

CHIPCARD_API
void LC_Card_SetIsoPerformModificationFn(LC_CARD *card,
                                         LC_CARD_ISOPERFORMMODIFICATION_FN f);

CHIPCARD_API
void LC_Card_SetIsoManageSeFn(LC_CARD *card, LC_CARD_ISOMANAGESE_FN f);

CHIPCARD_API
void LC_Card_SetIsoSignFn(LC_CARD *card, LC_CARD_ISOSIGN_FN f);

CHIPCARD_API
void LC_Card_SetIsoVerifyFn(LC_CARD *card, LC_CARD_ISOVERIFY_FN f);

CHIPCARD_API
void LC_Card_SetIsoEncipherFn(LC_CARD *card, LC_CARD_ISOENCIPHER_FN f);

CHIPCARD_API
void LC_Card_SetIsoDecipherFn(LC_CARD *card, LC_CARD_ISODECIPHER_FN f);
/*@}*/


/*@}*/


#ifdef __cplusplus
}
#endif

/*@}*/ /* addtogroup */

#endif /* CHIPCARD_CLIENT_CARD_IMP_H */

