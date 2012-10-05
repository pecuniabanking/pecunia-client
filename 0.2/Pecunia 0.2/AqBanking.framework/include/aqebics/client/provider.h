/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef AQEBICS_CLIENT_PROVIDER_H
#define AQEBICS_CLIENT_PROVIDER_H


#include <aqebics/aqebics.h>
#include <aqbanking/provider.h>
#include <gwenhywfar/ct.h>

#define EBC_DEFAULT_CONNECT_TIMEOUT  30
#define EBC_DEFAULT_TRANSFER_TIMEOUT 60


AB_PROVIDER *EBC_Provider_new(AB_BANKING *ab);

int EBC_Provider_CreateKeys(AB_PROVIDER *pro,
			    AB_USER *u,
			    int cryptAndAuthKeySizeInBytes,
			    int signKeySizeInBytes,
			    int nounmount);

int EBC_Provider_CreateTempKey(AB_PROVIDER *pro,
			       AB_USER *u,
			       int signKeySizeInBytes,
			       int nounmount);

int EBC_Provider_GetIniLetterTxt(AB_PROVIDER *pro,
				 AB_USER *u,
				 int useBankKey,
				 GWEN_BUFFER *lbuf,
				 int nounmount);

int EBC_Provider_GetHiaLetterTxt(AB_PROVIDER *pro,
				 AB_USER *u,
				 int useBankKey,
				 GWEN_BUFFER *lbuf,
				 int nounmount);

int EBC_Provider_GetCert(AB_PROVIDER *pro, AB_USER *u);

int EBC_Provider_Send_HIA(AB_PROVIDER *pro, AB_USER *u);
int EBC_Provider_Send_INI(AB_PROVIDER *pro, AB_USER *u);
int EBC_Provider_Send_PUB(AB_PROVIDER *pro, AB_USER *u, const char *signVersion);
int EBC_Provider_Send_HPB(AB_PROVIDER *pro, AB_USER *u);
int EBC_Provider_Send_HPD(AB_PROVIDER *pro, AB_USER *u);
int EBC_Provider_Send_HKD(AB_PROVIDER *pro, AB_USER *u);
int EBC_Provider_Send_HTD(AB_PROVIDER *pro, AB_USER *u);

int EBC_Provider_Download(AB_PROVIDER *pro, AB_USER *u,
			  const char *rtype,
			  GWEN_BUFFER *targetBuffer,
			  int withReceipt,
			  const GWEN_TIME *fromTime,
			  const GWEN_TIME *toTime);

int EBC_Provider_Upload(AB_PROVIDER *pro, AB_USER *u,
			const char *rtype,
			const uint8_t *pData,
			uint32_t lData);

int EBC_Provider_GetConnectTimeout(const AB_PROVIDER *pro);
int EBC_Provider_GetTransferTimeout(const AB_PROVIDER *pro);


#endif
