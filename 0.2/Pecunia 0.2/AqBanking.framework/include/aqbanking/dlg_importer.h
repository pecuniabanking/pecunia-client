/***************************************************************************
 begin       : Tue Feb 10 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQBANKING_DLG_IMPORTER_H
#define AQBANKING_DLG_IMPORTER_H


#include <gwenhywfar/dialog.h>
#include <gwenhywfar/db.h>

#include <aqbanking/banking.h>
#include <aqbanking/imexporter.h>



/** @defgroup G_AB_DIALOGS_IMPORTER Generic File Import Dialog
 * @ingroup G_AB_DIALOGS
 *
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif



/**
 * Creates a file import assistent.
 *
 * @return pointer to the created dialog.
 *
 * @param banking pointer to the AqBanking object

 * @param ctx pointer to the import context to receive the content of the
 * imported file
 *
 * @param finishedMessage message to show on the last page of the assistent
 *   (i.e. the page which is shown after a successfull import into the given
 *    import context).
 */
AQBANKING_API GWEN_DIALOG *AB_ImporterDialog_new(AB_BANKING *ab,
						 AB_IMEXPORTER_CONTEXT *ctx,
						 const char *finishedMessage);


#ifdef __cplusplus
}
#endif


/*@}*/


#endif

