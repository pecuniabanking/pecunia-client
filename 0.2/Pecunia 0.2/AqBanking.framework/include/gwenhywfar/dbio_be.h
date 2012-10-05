/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id: dbio.h 1107 2007-01-07 21:17:05Z martin $
 begin       : Wed Mar 31 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *                                                                         *
 *   This library is free software; you can redistribute it and/or         *
 *   modify it under the terms of the GNU Lesser General Public            *
 *   License as published by the Free Software Foundation; either          *
 *   version 2.1 of the License, or (at your option) any later version.    *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   Lesser General Public License for more details.                       *
 *                                                                         *
 *   You should have received a copy of the GNU Lesser General Public      *
 *   License along with this library; if not, write to the Free Software   *
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston,                 *
 *   MA  02111-1307  USA                                                   *
 *                                                                         *
 ***************************************************************************/


/** @file dbio.h
 * @short This file provides the GWEN DB import/export framework.
 */

#ifndef GWENHYWFAR_DBIO_BE_H
#define GWENHYWFAR_DBIO_BE_H

#include <gwenhywfar/dbio.h>



typedef int (*GWEN_DBIO_IMPORTFN)(GWEN_DBIO *dbio,
				  GWEN_SYNCIO *sio,
				  GWEN_DB_NODE *db,
				  GWEN_DB_NODE *params,
				  uint32_t flags);

typedef int (*GWEN_DBIO_EXPORTFN)(GWEN_DBIO *dbio,
				  GWEN_SYNCIO *sio,
				  GWEN_DB_NODE *db,
				  GWEN_DB_NODE *params,
				  uint32_t flags);

typedef GWEN_DBIO_CHECKFILE_RESULT (*GWEN_DBIO_CHECKFILEFN)(GWEN_DBIO *dbio, const char *fname);



GWENHYWFAR_API
GWEN_PLUGIN *GWEN_DBIO_Plugin_new(GWEN_PLUGIN_MANAGER *pm,
                                  const char *name,
                                  const char *fileName);

GWENHYWFAR_API
void GWEN_DBIO_Plugin_SetFactoryFn(GWEN_PLUGIN *pl,
                                   GWEN_DBIO_PLUGIN_FACTORYFN f);


/** @name Functions To Be Used By Inheritors
 *
 */
/*@{*/
/**
 * Creates the base object which is to be extended by the inheritor.
 */
GWENHYWFAR_API
GWEN_DBIO *GWEN_DBIO_new(const char *name, const char *descr);

/**
 * Sets the import function for this kind of GWEN_DBIO.
 */
GWENHYWFAR_API
void GWEN_DBIO_SetImportFn(GWEN_DBIO *dbio, GWEN_DBIO_IMPORTFN f);

/**
 * Sets the export function for this kind of GWEN_DBIO.
 */
GWENHYWFAR_API
void GWEN_DBIO_SetExportFn(GWEN_DBIO *dbio, GWEN_DBIO_EXPORTFN f);

GWENHYWFAR_API
void GWEN_DBIO_SetCheckFileFn(GWEN_DBIO *dbio, GWEN_DBIO_CHECKFILEFN f);

/*@}*/


#endif

