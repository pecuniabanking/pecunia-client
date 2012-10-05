/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004-2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_BANKING_IMEX_H
#define AQBANKING_BANKING_IMEX_H

#include <aqbanking/imexporter.h>


#ifdef __cplusplus
extern "C" {
#endif


/** @addtogroup G_AB_IMEXPORTER
 */
/*@{*/


/** @name Plugin Handling
 *
 */
/*@{*/
/**
 * Returns a list2 of available importers and exporters.
 * You must free this list after using it via
 * @ref GWEN_PluginDescription_List2_freeAll.
 * Please note that a simple @ref GWEN_PluginDescription_List2_free would
 * not suffice, since that would only free the list but not the objects
 * stored within the list !
 * @param ab pointer to the AB_BANKING object
 */
AQBANKING_API
GWEN_PLUGIN_DESCRIPTION_LIST2 *AB_Banking_GetImExporterDescrs(AB_BANKING *ab);

/**
 * Loads an importer/exporter backend with the given name. You can use
 * @ref AB_Banking_GetImExporterDescrs to retrieve a list of available
 * im-/exporters.
 * AqBanking remains the owner of the object returned (if any), so you
 * <b>must not</b> free it.
 */
AQBANKING_API 
AB_IMEXPORTER *AB_Banking_GetImExporter(AB_BANKING *ab, const char *name);

/**
 * <p>
 * Loads all available profiles for the given importer/exporter.
 * This includes global profiles as well as local ones.
 * </p>
 * <p>
 * Local profiles overwrite global ones, allowing the user to customize the
 * profiles. Local profiles are expected in a folder below the user
 * local folder (e.g. "$HOME/.aqbanking"). The local profile folder for the
 * CSV plugin is in "$HOME/.aqbanking/imexporters/csv/profiles".
 * </p>
 * <p>
 * The GWEN_DB returned contains one group for every loaded profile. Every
 * group has the name of the profile it contains. Every group contains at
 * least three variables:
 * <ul>
 *   <li>char "name": name of the profile</li>
 *   <li>int "isGlobal": this is 0 for profiles loaded from the users home directory and
 *       1 otherwise.</li>
 *   <li>char "fileName": name of the loaded file (without path, so it can be used for
 *       @ref AB_Banking_SaveLocalImExporterProfile)</li>
 * </ul>
 * The remaining content of each group is completely defined by
 * the importer/exporter.
 * </p>
 * <p>
 * You can use @ref GWEN_DB_GetFirstGroup and @ref GWEN_DB_GetNextGroup
 * to browse the profiles.
 * </p>
 * <p>
 * The caller becomes the new owner of the object returned (if any).
 * This makes him/her responsible for freeing it via
 *  @ref GWEN_DB_Group_free.
 * </p>
 * <p>
 * You can use any of the subgroups below the returned one as argument
 * to @ref AB_ImExporter_Import.
 * </p>
 * @param ab pointer to the AB_BANKING object
 * @param name name of the importer whose profiles are to be read
 */
AQBANKING_API
GWEN_DB_NODE *AB_Banking_GetImExporterProfiles(AB_BANKING *ab,
                                               const char *name);

AQBANKING_API
GWEN_DB_NODE *AB_Banking_GetImExporterProfile(AB_BANKING *ab,
					      const char *imExporterName,
					      const char *profileName);

/**
 * Save the given profile in the local user folder of the given im-/exporter
 * module. After that this profile will appear in the list returned by
 * @ref AB_Banking_GetImExporterProfiles.
 * Existing profiles with the same file name (argument @c fname) will be overwritten.
 * It is best practice to use the name of the profile plus ".conf" as file name
 * (e.g. "testprofile.conf"). The caller has to make sure that the name of the profile
 * is unique among all profiles of the given im-/exporter module, otherwise some
 * profiles can not be loaded.
 *
 * @param ab pointer to the AB_BANKING object
 * @param imexporterName name of the im-/exporter whose profile is to be written
 * @param dbProfile DB group containing the profile
 * @param fname name of the file to write without path (e.g. "testprofile.conf")
 * (if NULL then the path is determined by AqBanking using the given name of the im-/exporter).
 */
AQBANKING_API
int AB_Banking_SaveLocalImExporterProfile(AB_BANKING *ab,
                                          const char *imexporterName,
					  GWEN_DB_NODE *dbProfile,
					  const char *fname);

/*@}*/


/** @name Convenience Functions for Import/Export
 *
 * For import and exports the following objects are generally needed:
 * <ul>
 *   <li>im/exporter module (e.g. "csv", "ofx", "swift")</li>
 *   <li>im/export profile with the settings for the im/exporter module (e.g. "SWIFT-MT940" for
 *       the "swift" importer)</li>
 *   <li>im/export context (needed on import to store imported data, on export to hold the data
 *       to export)</li>
 *   <li>source/destination for the data to import/export (e.g. a CSV-file, OFX file etc)</li>
 * </ul>
 *
 * To make it easier for applications to import/export data this group contains some convenience
 * functions which automatically load the appropriate im/exporter plugin and a selected im/exporter
 * settings profile.
 *
 * The raw im/export API of AqBanking works with GWEN_SYNCIO objects as source/destination for the
 * formatted data. Such a GWEN_SYNCIO object can be a file or a buffer in memory.
 * However, the functions in this group allow you just to specify the file to import from/export to
 * and leave the gory details of setting up a GWEN_SYNCIO to AqBanking.
 *
 * There are functions to:
 * <ul>
 *   <li>import from a file</li>
 *   <li>import from a memory buffer</li>
 *   <li>export to a file</li>
 *   <li>export to a memory buffer</li>
 * </ul>
 */
/*@{*/

/**
 * This function tries to fill missing fields in a given imexporter context.
 * It tries to find the online banking accounts for all account info objects in
 * the context and copies missing information (like IBAN, BIC, owner name etc).
 *
 * @param ab pointer to the AB_BANKING object
 * @param iec pointer to the imexporter context to fill
 * @return 0 if all accounts were found, 1 if there was at least 1 unknown account
 */
AQBANKING_API
int AB_Banking_FillGapsInImExporterContext(AB_BANKING *ab, AB_IMEXPORTER_CONTEXT *iec);


/**
 * This function loads the given im/exporter plugin (if necessary) and also loads the given
 * im/exporter settings profile. The resulting data is written to a GWEN_BUFFER (which is basically
 * a memory buffer).
 * @return 0 on success, an error code otherwise
 * @param ab banking API object
 * @param ctx export context containing the accounts, transactions etc to export
 * @param exporterName name of the exporter module (e.g. "csv", "swift", "ofx" etc)
 * @param profileName name of the exporter settings profile to use (most plugins only provide the
 * "default" profile, but especially the CSV im/exporter has many profiles from which to choose)
 * @param buf buffer to write the exported data to
 */
AQBANKING_API
int AB_Banking_ExportToBuffer(AB_BANKING *ab,
			      AB_IMEXPORTER_CONTEXT *ctx,
			      const char *exporterName,
                              const char *profileName,
			      GWEN_BUFFER *buf);

/**
 * This function loads the given im/exporter plugin (if necessary) and also loads the given
 * im/exporter settings profile. The resulting data is written to the given file.
 * @return 0 on success, an error code otherwise
 * @param ab banking API object
 * @param ctx export context containing the accounts, transactions etc to export
 * @param exporterName name of the exporter module (e.g. "csv", "swift", "ofx" etc)
 * @param profileName name of the exporter settings profile to use (most plugins only provide the
 * "default" profile, but especially the CSV im/exporter has many profiles from which to choose)
 * @param fileName name of the file to create and to write the formatted data to
 */
AQBANKING_API
int AB_Banking_ExportToFile(AB_BANKING *ab,
			    AB_IMEXPORTER_CONTEXT *ctx,
			    const char *exporterName,
			    const char *profileName,
			    const char *fileName);

/**
 * This function basically does the same as @ref AB_Banking_ExportToFile. However, it loads the
 * exporter settings profile from a given file (as opposed to the forementioned function which
 * loads the profile by name from the set of system- or user-wide installed profiles).
 * So this functions allows for loading of special profiles which aren't installed.
 * @return 0 on success, an error code otherwise
 * @param ab banking API object
 * @param ctx export context containing the accounts, transactions etc to export
 * @param exporterName name of the exporter module (e.g. "csv", "swift", "ofx" etc)
 * @param profileName name of the exporter settings profile stored in the file whose name
 *   is given in @b profileFile
 * @param profileFile name of the file to load the exporter settings profile from.
 * @param outFileName name of the file to create and to write the formatted data to
 */
AQBANKING_API
int AB_Banking_ExportToFileWithProfile(AB_BANKING *ab,
				       const char *exporterName,
				       AB_IMEXPORTER_CONTEXT *ctx,
				       const char *profileName,
				       const char *profileFile,
				       const char *outputFileName);


AQBANKING_API 
int AB_Banking_ExportWithProfile(AB_BANKING *ab,
				 const char *exporterName,
				 AB_IMEXPORTER_CONTEXT *ctx,
				 const char *profileName,
				 const char *profileFile,
				 GWEN_SYNCIO *sio);


AQBANKING_API
int AB_Banking_ImportBuffer(AB_BANKING *ab,
			    AB_IMEXPORTER_CONTEXT *ctx,
			    const char *exporterName,
			    const char *profileName,
			    GWEN_BUFFER *buf);


AQBANKING_API
int AB_Banking_ImportFileWithProfile(AB_BANKING *ab,
				     const char *importerName,
				     AB_IMEXPORTER_CONTEXT *ctx,
				     const char *profileName,
				     const char *profileFile,
                                     const char *inputFileName);



AQBANKING_API 
int AB_Banking_ImportWithProfile(AB_BANKING *ab,
				 const char *importerName,
				 AB_IMEXPORTER_CONTEXT *ctx,
				 const char *profileName,
				 const char *profileFile,
				 GWEN_SYNCIO *sio);

/**
 * Another convenience function to import a given file.
 * (introduced in AqBanking 4.3.0)
 */
AQBANKING_API 
int AB_Banking_ImportFileWithProfile(AB_BANKING *ab,
				     const char *importerName,
				     AB_IMEXPORTER_CONTEXT *ctx,
				     const char *profileName,
				     const char *profileFile,
                                     const char *inputFileName);

/*@}*/


/*@}*/ /* addtogroup */

#ifdef __cplusplus
}
#endif

#endif

