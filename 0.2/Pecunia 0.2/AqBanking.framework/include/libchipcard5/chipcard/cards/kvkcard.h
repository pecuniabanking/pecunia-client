/***************************************************************************
    begin       : Sun Jun 13 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CARD_KVKCARD_H
#define CHIPCARD_CARD_KVKCARD_H

#include <chipcard/card.h>
#include <chipcard/cards/hipersonaldata.h>
#include <chipcard/cards/hiinsurancedata.h>


#ifdef __cplusplus
extern "C" {
#endif


/** @defgroup chipcardc_cards_kvk German Health Insurance Cards (KVK)
 * @ingroup chipcardc_cards
 *
 * <p>
 * KVK cards are issued by German health insurance companies to their
 * members.
 * </p>
 * <p>
 * Such a card contains information about the member (such as name,
 * date of birth, postal address, insurance company etc).
 * It does <b>not</b> contain any medical data.
 * </p>
 */
/*@{*/

/** @name Extending Basic Card Object
 *
 */
/*@{*/
/**
 * Extends a basic card type thus making functions of this group available.
 * This stores some KVK-related data with the given card object.
 * This function internally calls @ref LC_MemoryCard_ExtendCard.
 */
CHIPCARD_API
int LC_KVKCard_ExtendCard(LC_CARD *card);

/**
 * Unextend a card object which has previously been extended using
 * @ref LC_KVKCard_ExtendCard. This functions releases all KVK-related
 * ressources.
 * This function internally calls @ref LC_MemoryCard_UnextendCard.
 */
CHIPCARD_API
int LC_KVKCard_UnextendCard(LC_CARD *card);

/**
 * This function is called from within LC_Card_Open for cards which have been
 * extended using @ref LC_KVKCard_ExtendCard. However, if a card extended
 * after opening you can call this function here to let the card do some
 * necessary work before other functions of this group can be used.
 */
CHIPCARD_API
LC_CLIENT_RESULT LC_KVKCard_Reopen(LC_CARD *card);
/*@}*/


/** @name KVK-specific Data
 *
 */
/*@{*/
/**
 * Returns the content of the card parsed into a GWEN_DB.
 * The card object remains the owner od the object returned (if any), so you
 * must not manipulate or destroy it.
 */
CHIPCARD_API CHIPCARD_DEPRECATED
GWEN_DB_NODE *LC_KVKCard_GetCardData(const LC_CARD *card);

CHIPCARD_API
LC_CLIENT_RESULT LC_KvkCard_ReadCardData(LC_CARD *card,
					 LC_HI_PERSONAL_DATA **pPersonal,
					 LC_HI_INSURANCE_DATA **pInsurance);

CHIPCARD_API
const char *LC_KvkCard_GetCardNumber(const LC_CARD *card);

/*@}*/

/*@}*/ /* defgroup */

#ifdef __cplusplus
}
#endif


#endif /* CHIPCARD_CARD_KVKCARD_P_H */




