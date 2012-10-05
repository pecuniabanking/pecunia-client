/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004-2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

/** @file imexporter_be.h
 * @short This file is used by provider/importer/exporter plugins.
 */


#ifndef AQBANKING_IMEXPORTER_BE_H
#define AQBANKING_IMEXPORTER_BE_H


#include <aqbanking/imexporter.h>
#include <gwenhywfar/misc.h>
#include <gwenhywfar/plugin.h>


/** @defgroup G_AB_BE_IMEXPORTER Generic Im- and Exporter
 * @ingroup G_AB_BE_INTERFACE
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif

typedef AB_IMEXPORTER* (*AB_IMEXPORTER_FACTORY_FN)(AB_BANKING *ab);


/** @name Construction and Destruction
 *
 */
/*@{*/
AQBANKING_API 
AB_IMEXPORTER *AB_ImExporter_new(AB_BANKING *ab,
                                 const char *name);
AQBANKING_API 
void AB_ImExporter_free(AB_IMEXPORTER *ie);


/*@}*/



/** @name Manipulation of the Flags
 *
 */
/*@{*/
AQBANKING_API
void AB_ImExporter_SetFlags(AB_IMEXPORTER *ie, uint32_t flags);

AQBANKING_API 
void AB_ImExporter_AddFlags(AB_IMEXPORTER *ie, uint32_t flags);

AQBANKING_API 
void AB_ImExporter_SubFlags(AB_IMEXPORTER *ie, uint32_t flags);
/*@}*/



/** @name Prototypes for Virtual Backend Functions
 *
 */
/*@{*/
typedef int (*AB_IMEXPORTER_IMPORT_FN)(AB_IMEXPORTER *ie,
                                       AB_IMEXPORTER_CONTEXT *ctx,
				       GWEN_SYNCIO *sio,
				       GWEN_DB_NODE *params);

typedef int (*AB_IMEXPORTER_EXPORT_FN)(AB_IMEXPORTER *ie,
                                       AB_IMEXPORTER_CONTEXT *ctx,
				       GWEN_SYNCIO *sio,
				       GWEN_DB_NODE *params);

/**
 * Checks whether the given file is possibly supported by the plugin.
 */
typedef int (*AB_IMEXPORTER_CHECKFILE_FN)(AB_IMEXPORTER *ie,
					  const char *fname);


/**
 * This function should return a dialog (see @ref GWEN_DIALOG) which
 * allows editing of the given profile.
 * (introduced in AqBanking 4.3.0)
 */
typedef int (*AB_IMEXPORTER_GET_EDITPROFILE_DIALOG_FN)(AB_IMEXPORTER *ie,
						       GWEN_DB_NODE *params,
						       const char *testFileName,
						       GWEN_DIALOG **pDlg);

/*@}*/




/** @name Setters for Virtual Backend Functions
 *
 */
/*@{*/
AQBANKING_API 
void AB_ImExporter_SetImportFn(AB_IMEXPORTER *ie,
                               AB_IMEXPORTER_IMPORT_FN f);

AQBANKING_API 
void AB_ImExporter_SetExportFn(AB_IMEXPORTER *ie,
                               AB_IMEXPORTER_EXPORT_FN f);

AQBANKING_API
void AB_ImExporter_SetCheckFileFn(AB_IMEXPORTER *ie,
                                  AB_IMEXPORTER_CHECKFILE_FN f);

AQBANKING_API
void AB_ImExporter_SetGetEditProfileDialogFn(AB_IMEXPORTER *ie,
					     AB_IMEXPORTER_GET_EDITPROFILE_DIALOG_FN f);
/*@}*/




/** @name Handling of ImExporter Plugins
 *
 */
/*@{*/

typedef AB_IMEXPORTER* (*AB_PLUGIN_IMEXPORTER_FACTORY_FN)(GWEN_PLUGIN *pl,
							  AB_BANKING *ab);


AQBANKING_API
GWEN_PLUGIN *AB_Plugin_ImExporter_new(GWEN_PLUGIN_MANAGER *pm,
				      const char *name,
				      const char *fileName);

AQBANKING_API
AB_IMEXPORTER *AB_Plugin_ImExporter_Factory(GWEN_PLUGIN *pl,
					    AB_BANKING *ab);

AQBANKING_API
void AB_Plugin_ImExporter_SetFactoryFn(GWEN_PLUGIN *pl,
				       AB_PLUGIN_IMEXPORTER_FACTORY_FN fn);

/*@}*/


#ifdef __cplusplus
}
#endif

/*@}*/ /* defgroup */


#endif /* AQBANKING_IMEXPORTER_BE_H */


