/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CARD_GELDKARTE_H
#define CHIPCARD_CARD_GELDKARTE_H

#include <chipcard/card.h>
#include <chipcard/cards/geldkarte_blog.h>
#include <chipcard/cards/geldkarte_llog.h>
#include <chipcard/cards/geldkarte_values.h>


#ifdef __cplusplus
extern "C" {
#endif


/** @defgroup chipcardc_cards_geldkarte GeldKarte
 * @ingroup chipcardc_cards
 */
/*@{*/

/** @name Extending Basic Card Object
 *
 */
/*@{*/
/**
 * Extends a basic card type thus making functions of this group available.
 * This stores some GeldKarte-related data with the given card object.
 * This function internally calls @ref LC_ProcessorCard_ExtendCard.
 */
CHIPCARD_API int LC_GeldKarte_ExtendCard(LC_CARD *card);

/**
 * Unextend a card object which has previously been extended using
 * @ref LC_GeldKarte_ExtendCard. This functions releases all GeldKarte-related
 * ressources.
 * This function internally calls @ref LC_ProcessorCard_UnextendCard.
 */
CHIPCARD_API int LC_GeldKarte_UnextendCard(LC_CARD *card);

/**
 * This function is called from within LC_Card_Open for cards which have been
 * extended using @ref LC_GeldKarte_ExtendCard. However, if a card extended
 * after opening you can call this function here to let the card do some
 * necessary work before other functions of this group can be used.
 */
CHIPCARD_API LC_CLIENT_RESULT LC_GeldKarte_Reopen(LC_CARD *card);
/*@}*/


/** @name General Card Data
 *
 */
/*@{*/
/**
 * Returns the card data (EF_ID) parsed into a GWEN_DB.
 */
CHIPCARD_API GWEN_DB_NODE *LC_GeldKarte_GetCardDataAsDb(const LC_CARD *card);

/**
 * Returns the raw card data (content of EF_ID). The card object remains the
 * owner of the object returned (if any), so you must not manipulate or free
 * it.
 */
CHIPCARD_API
  GWEN_BUFFER *LC_GeldKarte_GetCardDataAsBuffer(const LC_CARD *card);

/**
 * Returns the card data (EF_BOERSE) parsed into a GWEN_DB.
 */
CHIPCARD_API
  GWEN_DB_NODE *LC_GeldKarte_GetAccountDataAsDb(const LC_CARD *card);

/**
 * Returns the raw card data (content of EF_BOERSE). The card object remains the
 * owner of the object returned (if any), so you must not manipulate or free
 * it.
 */
CHIPCARD_API
  GWEN_BUFFER *LC_GeldKarte_GetAccountDataAsBuffer(const LC_CARD *card);
/*@}*/


/** @name GeldKarte-specific Data
 *
 */
/*@{*/
/**
 * Read the stored values off the card (loaded amount, maximum amount,
 * transfer amount limit).
 */
CHIPCARD_API
  LC_CLIENT_RESULT LC_GeldKarte_ReadValues(LC_CARD *card,
                                           LC_GELDKARTE_VALUES *val);

/**
 * Read the BLOGs off the card.
 * BLOGs are merchant logs, e.g. they contain transactions in shops etc
 * (see @ref LC_GELDKARTE_BLOG).
 */
CHIPCARD_API
  LC_CLIENT_RESULT LC_GeldKarte_ReadBLogs(LC_CARD *card,
                                          LC_GELDKARTE_BLOG_LIST2 *bll);

/**
 * Read the LLOGs off the card.
 * LLOGs are load/unload logs, these are logs about loading/unloading of
 * the card at credit institutes
 * (see @ref LC_GELDKARTE_LLOG).
 */
CHIPCARD_API
  LC_CLIENT_RESULT LC_GeldKarte_ReadLLogs(LC_CARD *card,
                                          LC_GELDKARTE_LLOG_LIST2 *bll);
/*@}*/

/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif


#endif /* CHIPCARD_CARD_GELDKARTE_H */


