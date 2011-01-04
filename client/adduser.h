/*
 *  adduser.h
 *  MacBanking
 *
 *  Copyright 2007 Frank Emminghaus. All rights reserved.
 *
 */


#ifdef HAVE_I18N
# ifdef HAVE_LOCALE_H
#  include <locale.h>
# endif
# ifdef HAVE_LIBINTL_H
#  include <libintl.h>
# endif
# define I18N(msg) dgettext(PACKAGE, msg)
#else
# define I18N(msg) msg
#endif

#define I18N_NOOP(msg) msg

#include <aqbanking/banking.h>
#include <aqbanking/banking_be.h>
#include <aqhbci/provider.h>

#include <gwenhywfar/args.h>
#include <gwenhywfar/buffer.h>
#include <gwenhywfar/db.h>
#include <gwenhywfar/debug.h>

int addUser(AB_BANKING *ab,
			const char *bankId,
			const char *userId,
			const char *customerId,
			const char *tokenName,
			const char *server,
			const char *userName,
			uint32_t	idx,
			uint32_t    flags,
			int			hbciVersion,
			char		**errmsg );