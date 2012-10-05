/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CARD_MEMORYCARD_H
#define CHIPCARD_CARD_MEMORYCARD_H

#include <chipcard/card.h>


#ifdef __cplusplus
extern "C" {
#endif


/** @defgroup chipcardc_cards_mem Memory Cards
 * @ingroup chipcardc_cards
 *
 */
/*@{*/

/** @name Extending Basic Card Object
 *
 */
/*@{*/
/**
 * Extends a basic card type thus making functions of this group available.
 * This stores some memory-card-related data with the given card object.
 */
CHIPCARD_API
int LC_MemoryCard_ExtendCard(LC_CARD *card);

/**
 * Unextend a card object which has previously been extended using
 * @ref LC_MemoryCard_ExtendCard. This functions releases all
 * memory-card-related ressources.
 */
CHIPCARD_API
int LC_MemoryCard_UnextendCard(LC_CARD *card);
/*@}*/


/** @name Reading And Writing
 *
 * Normally read-/write operations are limited to about 256 bytes, so
 * these functions encapsulate the ISO functions to allow for transfers of an
 * arbitrary number of bytes.
 */
/*@{*/
/**
 * Read data from the card.
 * @param card card object
 * @param offset offset of the memory area on the card
 * @param size number of bytes to read
 * @param buf GWEN_BUFFER to receive the data read
 */
CHIPCARD_API
LC_CLIENT_RESULT LC_MemoryCard_ReadBinary(LC_CARD *card,
                                          int offset,
                                          int size,
                                          GWEN_BUFFER *buf);

/**
 * Write data to the card.
 * @param card card object
 * @param offset offset of the memory area on the card
 * @param ptr pointer to the data to be written
 * @param size number of bytes to write
 */
CHIPCARD_API
LC_CLIENT_RESULT LC_MemoryCard_WriteBinary(LC_CARD *card,
                                           int offset,
                                           const char *ptr,
                                           unsigned int size);
/*@}*/

/** @name Informational Functions
 *
 */
/*@{*/
/**
 * Returns the capacity of the card in bytes. For some cards the capacity
 * can not be determined, in which case this function returns 0.
 */
CHIPCARD_API
unsigned int LC_MemoryCard_GetCapacity(const LC_CARD *card);
/*@}*/

/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif



#endif /* CHIPCARD_CARD_MEMORYCARD_H */


