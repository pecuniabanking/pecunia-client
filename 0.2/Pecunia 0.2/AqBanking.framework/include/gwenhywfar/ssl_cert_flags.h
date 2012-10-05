/***************************************************************************
    begin       : Wed Mar 16 2005
    copyright   : (C) 2005-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_SSL_CERT_FLAGS_H
#define GWEN_SSL_CERT_FLAGS_H


#define GWEN_SSL_CERT_FLAGS_SIGNER_NOT_FOUND 0x00000001
#define GWEN_SSL_CERT_FLAGS_INVALID          0x00000002
#define GWEN_SSL_CERT_FLAGS_REVOKED          0x00000004
#define GWEN_SSL_CERT_FLAGS_EXPIRED          0x00000008
#define GWEN_SSL_CERT_FLAGS_NOT_ACTIVE       0x00000010
#define GWEN_SSL_CERT_FLAGS_BAD_HOSTNAME     0x00000020
#define GWEN_SSL_CERT_FLAGS_BAD_DATA         0x00000040
#define GWEN_SSL_CERT_FLAGS_SYSTEM           0x00000080
#define GWEN_SSL_CERT_FLAGS_OK               0x80000000


#endif


