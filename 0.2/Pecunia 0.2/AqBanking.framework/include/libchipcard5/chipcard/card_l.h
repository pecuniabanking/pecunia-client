/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef CHIPCARD_CLIENT_CARD_L_H
#define CHIPCARD_CLIENT_CARD_L_H


#include "card_imp.h"

#include <winscard.h>



LC_CARD *LC_Card_new(LC_CLIENT *cl,
		     SCARDHANDLE scardHandle,
		     const char *readerName,
		     DWORD protocol,
		     const char *cardType,
		     uint32_t rflags,
		     const unsigned char *atrBuf,
		     unsigned int atrLen);


GWEN_XMLNODE *LC_Card_FindCommand(LC_CARD *card,
                                  const char *commandName);

int LC_Card_IsConnected(const LC_CARD *card);

void LC_Card_SetConnected(LC_CARD *card, int b);


SCARDHANDLE LC_Card_GetSCardHandle(const LC_CARD *card);

uint32_t LC_Card_GetFeatureCode(const LC_CARD *cd, int idx);

const char *LC_Card_GetReaderName(const LC_CARD *card);

DWORD LC_Card_GetProtocol(const LC_CARD *card);

#endif /* CHIPCARD_CLIENT_CARD_L_H */
