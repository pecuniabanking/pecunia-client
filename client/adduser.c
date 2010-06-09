
#include "adduser.h"
#include <aqhbci/user.h>

#include <gwenhywfar/text.h>
#include <gwenhywfar/url.h>
#include <gwenhywfar/ct.h>
#include <gwenhywfar/ctplugin.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

int getBankUrl(AB_BANKING *ab,
               AH_CRYPT_MODE cm,
	       const char *bankId,
	       GWEN_BUFFER *bufServer) {
  AB_BANKINFO *bi;
  
  bi=AB_Banking_GetBankInfo(ab, "de", 0, bankId);
  if (bi) {
    AB_BANKINFO_SERVICE_LIST *l;
    AB_BANKINFO_SERVICE *sv;
  
    l=AB_BankInfo_GetServices(bi);
    assert(l);
    sv=AB_BankInfoService_List_First(l);
    while(sv) {
      const char *st;
  
      st=AB_BankInfoService_GetType(sv);
      if (st && *st && strcasecmp(st, "hbci")==0) {
	const char *svm;
  
	svm=AB_BankInfoService_GetMode(sv);
	if (svm && *svm) {
	  if (!
	      ((strcasecmp(svm, "pintan")==0) ^
               (cm==AH_CryptMode_Pintan))){
            const char *addr;

            addr=AB_BankInfoService_GetAddress(sv);
	    if (addr && *addr) {
	      GWEN_Buffer_Reset(bufServer);
	      GWEN_Buffer_AppendString(bufServer, addr);
              return 0;
	    }
	  }
	}
      }
      sv=AB_BankInfoService_List_Next(sv);
    }
    AB_BankInfo_free(bi);
  } /* if bank info */

  return -1;
}



int addUser(AB_BANKING *ab,
			const char *bankId,
			const char *userId,
			const char *customerId,
			const char *tokenName,
			const char *server,
			const char *userName,
			uint32_t	cid,
			uint32_t    flags,
			int			hbciVersion,
			char **errmsg )
{
  AB_PROVIDER *pro;
  int rv;
  GWEN_BUFFER *nameBuffer=NULL;

  const char *tokenType = "pintan";

  pro=AB_Banking_GetProvider(ab, "aqhbci");
  assert(pro);

  if (1) {
    const char *lbankId;
    const char *luserId;
    const char *lcustomerId;
    const char *lserverAddr;

    AH_CRYPT_MODE cm;
    GWEN_URL *url;
    GWEN_CRYPT_TOKEN_CONTEXT *ctx=NULL;
    AB_USER *user;

    if (strcasecmp(tokenType, "pintan")==0) {
      lbankId=bankId;
      luserId=userId;
      lcustomerId=customerId?customerId:luserId;
      lserverAddr=server;
      cm=AH_CryptMode_Pintan;
    }
    else {
      GWEN_PLUGIN_MANAGER *pm;
      GWEN_PLUGIN *pl;
      GWEN_CRYPT_TOKEN *ct;
      const GWEN_CRYPT_TOKEN_CONTEXT *cctx;
      const GWEN_CRYPT_TOKEN_KEYINFO *ki;
      uint32_t keyId;
      GWEN_CRYPT_CRYPTALGOID algo;

      if (cid==0) {
	asprintf(errmsg, "No context given.");
	return 1;
      }

      /* get crypt token */
      pm=GWEN_PluginManager_FindPluginManager("ct");
      if (pm==0) {
	asprintf(errmsg, "Plugin manager not found");
	return 3;
      }

      pl=GWEN_PluginManager_GetPlugin(pm, tokenType);
      if (pl==0) {
	asprintf(errmsg, "Plugin not found");
	return 3;
      }
      DBG_INFO(0, "Plugin found");

      ct=GWEN_Crypt_Token_Plugin_CreateToken(pl, tokenName);
      if (ct==0) {
	asprintf(errmsg, "Could not create crypt token");
	return 3;
      }

      /* open crypt token */
      rv=GWEN_Crypt_Token_Open(ct, 0, 0);
      if (rv) {
	asprintf(errmsg, "Could not open token (%d)", rv);
	return 3;
      }

      /* get real token name */
      nameBuffer=GWEN_Buffer_new(0, 64, 0, 1);
      GWEN_Buffer_AppendString(nameBuffer,
			       GWEN_Crypt_Token_GetTokenName(ct));
      tokenName=GWEN_Buffer_GetStart(nameBuffer);

      cctx=GWEN_Crypt_Token_GetContext(ct, cid, 0);
      if (cctx==NULL) {
	asprintf(errmsg, "Context %02x not found", cid);
	return 3;
      }
      ctx=GWEN_Crypt_Token_Context_dup(cctx);
      lbankId=bankId?bankId:GWEN_Crypt_Token_Context_GetServiceId(ctx);

      luserId=userId?userId:GWEN_Crypt_Token_Context_GetUserId(ctx);
      lcustomerId=customerId?customerId:luserId;

      lserverAddr=server?server:GWEN_Crypt_Token_Context_GetAddress(ctx);

      /* determine crypt mode */
      keyId=GWEN_Crypt_Token_Context_GetSignKeyId(ctx);
      if (keyId==0)
	keyId=GWEN_Crypt_Token_Context_GetVerifyKeyId(ctx);
      if (keyId==0)
	keyId=GWEN_Crypt_Token_Context_GetEncipherKeyId(ctx);
      if (keyId==0)
	keyId=GWEN_Crypt_Token_Context_GetDecipherKeyId(ctx);
      if (keyId==0) {
	asprintf(errmsg, "No keys, unable to determine crypt mode");
	GWEN_Crypt_Token_Close(ct, 1, 0);
	return 3;
      }
  
      ki=GWEN_Crypt_Token_GetKeyInfo(ct, keyId, 0xffffffff, 0);
      if (ki==NULL) {
	asprintf(errmsg,
		  "Could not get keyinfo for key %d, "
		  "unable to determine crypt mode", keyId);
	GWEN_Crypt_Token_Close(ct, 1, 0);
	return 3;
      }

      algo=GWEN_Crypt_Token_KeyInfo_GetCryptAlgoId(ki);
      if (algo==GWEN_Crypt_CryptAlgoId_Des3K)
	cm=AH_CryptMode_Ddv;
      else if (algo==GWEN_Crypt_CryptAlgoId_Rsa)
	cm=AH_CryptMode_Rdh;
      else {
	asprintf(errmsg,
		  "Unexpected crypt algorithm \"%s\", "
		  "unable to determine crypt mode",
		  GWEN_Crypt_CryptAlgoId_toString(algo));
	GWEN_Crypt_Token_Close(ct, 1, 0);
	return 3;
      }

      rv=GWEN_Crypt_Token_Close(ct, 0, 0);
      if (rv) {
	asprintf(errmsg, "Could not close token (%d)", rv);
	return 3;
      }

      GWEN_Crypt_Token_free(ct);
    }

    if (!lbankId || !*lbankId) {
      asprintf(errmsg, "No bank id stored and none given");
      return 3;
    }
    if (!luserId || !*luserId) {
      asprintf(errmsg, "No user id (Benutzerkennung) stored and none given");
      return 3;
    }

    user=AB_Banking_FindUser(ab, AH_PROVIDER_NAME,
			     "de",
			     lbankId, luserId, lcustomerId);
    if (user) {
      asprintf(errmsg, "User %s already exists", luserId);
      return 3;
    }

    user=AB_Banking_CreateUser(ab, AH_PROVIDER_NAME);
    assert(user);

    AB_User_SetUserName(user, userName);
    AB_User_SetCountry(user, "de");
    AB_User_SetBankCode(user, lbankId);
    AB_User_SetUserId(user, luserId);
    AB_User_SetCustomerId(user, lcustomerId);
    AH_User_SetTokenType(user, tokenType);
    AH_User_SetTokenName(user, tokenName);
    AH_User_SetTokenContextId(user, cid);
    AH_User_SetCryptMode(user, cm);
// IMPORTANT!!!
	AH_User_SetFlags(user, flags);
//
    if (hbciVersion==0) {
    if (cm==AH_CryptMode_Pintan)
	AH_User_SetHbciVersion(user, 220);
      else
	AH_User_SetHbciVersion(user, 210);
    }
    else
      AH_User_SetHbciVersion(user, hbciVersion);

    /* try to get server address from database if still unknown */
    if (!lserverAddr || *lserverAddr==0) {
      GWEN_BUFFER *tbuf;

      tbuf=GWEN_Buffer_new(0, 256, 0, 1);
      if (getBankUrl(ab,
                     cm,
                     lbankId,
		     tbuf)) {
	DBG_INFO(0, "Could not find server address for \"%s\"",
		 lbankId);
      }
      if (GWEN_Buffer_GetUsedBytes(tbuf)==0) {
	asprintf(errmsg, "No address given and none available in internal db");
	return 3;
      }
      url=GWEN_Url_fromString(GWEN_Buffer_GetStart(tbuf));
      if (url==NULL) {
	asprintf(errmsg, "Bad URL \"%s\" in internal db",
		  GWEN_Buffer_GetStart(tbuf));
	return 3;
      }
      GWEN_Buffer_free(tbuf);
    }
    else {
      /* set address */
      url=GWEN_Url_fromString(lserverAddr);
      if (url==NULL) {
	asprintf(errmsg, "Bad URL \"%s\"", lserverAddr);
	return 3;
      }
    }

    if (cm==AH_CryptMode_Pintan) {
      GWEN_Url_SetProtocol(url, "https");
      if (GWEN_Url_GetPort(url)==0)
	GWEN_Url_SetPort(url, 443);
    }
    else {
      GWEN_Url_SetProtocol(url, "hbci");
      if (GWEN_Url_GetPort(url)==0)
	GWEN_Url_SetPort(url, 3000);
    }
    AH_User_SetServerUrl(user, url);
    GWEN_Url_free(url);

    if (cm==AH_CryptMode_Ddv)
      AH_User_SetStatus(user, AH_UserStatusEnabled);

    AB_Banking_AddUser(ab, user);
  }

  return 0;
}



