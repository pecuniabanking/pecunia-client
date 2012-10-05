/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CARD_PROCESSORCARD_H
#define CHIPCARD_CARD_PROCESSORCARD_H

#include <chipcard/card.h>

#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup chipcardc_cards_proc Processor Cards
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
 * This stores some processor-card-related data with the given card object.
 */
CHIPCARD_API
int LC_ProcessorCard_ExtendCard(LC_CARD *card);

/**
 * Unextend a card object which has previously been extended using
 * @ref LC_ProcessorCard_ExtendCard. This functions releases all
 * processor-card-related ressources.
 */
CHIPCARD_API
int LC_ProcessorCard_UnextendCard(LC_CARD *card);
/*@}*/


/*@}*/ /* defgroup */

#ifdef __cplusplus
}
#endif

#endif /* CHIPCARD_CARD_PROCESSORCARD_H */


