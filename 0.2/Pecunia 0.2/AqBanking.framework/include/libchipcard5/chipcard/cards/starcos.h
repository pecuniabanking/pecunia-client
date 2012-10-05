/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CARD_STARCOS_H
#define CHIPCARD_CARD_STARCOS_H

#include <chipcard/card.h>
#include <chipcard/cards/starcos_keydescr.h>

#ifdef __cplusplus
extern "C" {
#endif


#define LC_STARCOS_KEY_STATUS_ACTIVE            0x10
#define LC_STARCOS_KEY_STATUS_INACTIVE_CERT     0x0a
#define LC_STARCOS_KEY_STATUS_INACTIVE_FREE     0x08
#define LC_STARCOS_KEY_STATUS_INACTIVE_NEW      0x07
#define LC_STARCOS_KEY_STATUS_ACTIVE_NEW        0x02
#define LC_STARCOS_KEY_STATUS_ACTIVE_INCOMPLETE 0x01
#define LC_STARCOS_KEY_STATUS_ACTIVE_INILETTER  0x00
#define LC_STARCOS_KEY_STATUS_INTERNAL_UNUSED   0xff


CHIPCARD_API
int LC_Starcos_ExtendCard(LC_CARD *card);
CHIPCARD_API
int LC_Starcos_UnextendCard(LC_CARD *card);
CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_Reopen(LC_CARD *card);


CHIPCARD_API
GWEN_DB_NODE *LC_Starcos_GetCardDataAsDb(const LC_CARD *card);
CHIPCARD_API
GWEN_BUFFER *LC_Starcos_GetCardDataAsBuffer(const LC_CARD *card);



/** @name Key Management Functions
 *
 */
/*@{*/


/**
 * Generates a temporary key pair. To use the newly created key pair you
 * need to call @ref LC_Starcos_ActivateKeyPair.
 * @param kid use 0x8e for crypt keys and 0x8f for sign keys
 */
CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_GenerateKeyPair(LC_CARD *card,
                                            int kid,
                                            int bits);

CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_ActivateKeyPair(LC_CARD *card,
                                            int srcKid,
					    int dstKid,
					    const LC_STARCOS_KEYDESCR *descr);

CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_GetKeyDescr(LC_CARD *card, int kid,
					LC_STARCOS_KEYDESCR **pDescr);

CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_SaveKeyDescr(LC_CARD *card,
					 const LC_STARCOS_KEYDESCR *d);

CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_WritePublicKey(LC_CARD *card, int kid,
					   const uint8_t *pModulus,
					   uint32_t lModulus,
					   const uint8_t *pExponent,
					   uint32_t lExponent);

CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_ReadPublicKey(LC_CARD *card, int kid,
					  GWEN_BUFFER *bModulus,
					  GWEN_BUFFER *bExponent);

/*@}*/



/** @name Bank Information Functions
 *
 */
/*@{*/
/**
 * This function reads institute data from the card. You need to verify
 * the pin prior to using this function.
 * Please note that this function always returns contexts if there was no
 * error. However, if the context is empty the corresponding context group
 * returned will be empty, too.
 * @param idx if 0 then all 5 entries are read, if 1 then entry 1 is read etc
 * @param dbData if idx==0 then every context read will be added as a new
 * group called "context" to this given group. Otherwise the specified context
 * is directly stored within this given group.
 *
 */
CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_ReadInstituteData(LC_CARD *card,
                                              int idx,
                                              GWEN_DB_NODE *dbData);

CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_WriteInstituteData(LC_CARD *card,
                                               int idx,
                                               GWEN_DB_NODE *dbData);
/*@}*/



/** @name Cryptographic Functions
 *
 */
/*@{*/
CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_ReadSigCounter(LC_CARD *card, int kid,
					   uint32_t *pSeq);

/**
 * returns 8 random bytes
 */
CHIPCARD_API
LC_CLIENT_RESULT LC_Starcos_GetChallenge(LC_CARD *card, GWEN_BUFFER *mbuf);


/*@}*/

#ifdef __cplusplus
}
#endif

#endif /* CHIPCARD_CARD_STARCOS_H */


