/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CARD_DDVCARD_H
#define CHIPCARD_CARD_DDVCARD_H

#include <chipcard/card.h>

#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup chipcardc_cards_ddv DDV Cards
 * @ingroup chipcardc_cards
 *
 * <p>
 * DDV cards are used for the German HBCI (<i>Homebanking Computer
 * Interface</i>).
 * </p>
 *
 * <p>
 * This class supports DDV0 and DDV1 cards.
 * </p>
 */
/*@{*/

/** @name Extending Basic Card Object
 *
 */
/*@{*/
/**
 * Extends a basic card type thus making functions of this group available.
 * This stores some DDV-related data with the given card object.
 * This function internally calls @ref LC_ProcessorCard_ExtendCard.
 */
CHIPCARD_API int LC_DDVCard_ExtendCard(LC_CARD *card);

/**
 * Unextend a card object which has previously been extended using
 * @ref LC_DDVCard_ExtendCard. This functions releases all DDV-related
 * ressources.
 * This function internally calls @ref LC_ProcessorCard_UnextendCard.
 */
CHIPCARD_API int LC_DDVCard_UnextendCard(LC_CARD *card);

/**
 * This function is called from within LC_Card_Open for cards which have been
 * extended using @ref LC_DDVCard_ExtendCard. However, if a card extended
 * after opening you can call this function here to let the card do some
 * necessary work before other functions of this group can be used.
 */
CHIPCARD_API LC_CLIENT_RESULT LC_DDVCard_Reopen(LC_CARD *card);
/*@}*/

/** @name Pin Verification
 *
 */
/*@{*/
/**
 * Verify the given pin.
 */
CHIPCARD_API LC_CLIENT_RESULT LC_DDVCard_VerifyPin(LC_CARD *card,
                                                   const char *pin);
/**
 * Secure pin verification. This can be used if the card's reader flags
 * indicate that the reader has a keypad.
 */
CHIPCARD_API LC_CLIENT_RESULT LC_DDVCard_SecureVerifyPin(LC_CARD *card);
/*@}*/

/** @name Crypto Functions
 *
 */
/*@{*/

/**
 * Let the card create an 8 byte random number.
 */
CHIPCARD_API LC_CLIENT_RESULT LC_DDVCard_GetChallenge(LC_CARD *card,
                                                      GWEN_BUFFER *mbuf);

/**
 * Let the card encrypt/decrypt exactly 8 bytes of data (using GWEN_BUFFER
 * for input).
 */
CHIPCARD_API LC_CLIENT_RESULT LC_DDVCard_CryptBlock(LC_CARD *card,
                                                    GWEN_BUFFER *ibuf,
                                                    GWEN_BUFFER *obuf);

/**
 * Let the card encrypt/decrypt exactly 8 bytes of data.
 */
CHIPCARD_API
LC_CLIENT_RESULT LC_DDVCard_CryptCharBlock(LC_CARD *card,
                                           const char *data,
                                           unsigned int dlen,
                                           GWEN_BUFFER *obuf);

/**
 * Let the card sign exactly 20 bytes of data. Returns 8 bytes of data.
 */
CHIPCARD_API LC_CLIENT_RESULT LC_DDVCard_SignHash(LC_CARD *card,
                                                  GWEN_BUFFER *hbuf,
                                                  GWEN_BUFFER *obuf);
/*@}*/


/** @name General Card Data
 *
 */
/*@{*/
/**
 * Returns the card data (EF_ID) parsed into a GWEN_DB.
 */
CHIPCARD_API GWEN_DB_NODE *LC_DDVCard_GetCardDataAsDb(const LC_CARD *card);

/**
 * Returns the raw card data (content of EF_ID). The card object remains the
 * owner of the object returned (if any), so you must not manipulate or free
 * it.
 */
CHIPCARD_API GWEN_BUFFER *LC_DDVCard_GetCardDataAsBuffer(const LC_CARD *card);
/*@}*/


/** @name Institution Data
 *
 */
/*@{*/
/**
 * Read institution data (including bank code, server address, user id etc).
 */
CHIPCARD_API
  LC_CLIENT_RESULT LC_DDVCard_ReadInstituteData(LC_CARD *card,
                                                int idx,
                                                GWEN_DB_NODE *dbData);

/**
 * Write institution data (including bank code, server address, user id etc).
 */
CHIPCARD_API 
  LC_CLIENT_RESULT LC_DDVCard_WriteInstituteData(LC_CARD *card,
                                                 int idx,
                                                 GWEN_DB_NODE *dbData);
/*@}*/

/** @name Key Information
 *
 * Every key has a version and a number assigned to it. There are two keys:
 * <ul>
 *  <li>sign key</li>
 *  <li>crypt key</li>
 * </ul>
 */
/*@{*/
/**
 * Return the version of the sign key.
 */
CHIPCARD_API int LC_DDVCard_GetSignKeyVersion(LC_CARD *card);

/**
 * Return the number of the sign key.
 */
CHIPCARD_API int LC_DDVCard_GetSignKeyNumber(LC_CARD *card);

/**
 * Return the version of the crypt key.
 */
CHIPCARD_API int LC_DDVCard_GetCryptKeyVersion(LC_CARD *card);

/**
 * Return the number of the crypt key.
 */
CHIPCARD_API int LC_DDVCard_GetCryptKeyNumber(LC_CARD *card);
/*@}*/

/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif


#endif /* CHIPCARD_CARD_DDVCARD_H */


