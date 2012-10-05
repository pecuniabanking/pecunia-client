/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Tue Dec 03 2002
    copyright   : (C) 2002 by Martin Preuss
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

/**
 * @file directory.h
 * @short This file contains the directory handling module
 */


#ifndef GWEN_DIRECTORY_H
#define GWEN_DIRECTORY_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GWEN_DIRECTORY GWEN_DIRECTORY;

#ifdef __cplusplus
}
#endif


#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/buffer.h>
#include <gwenhywfar/stringlist.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 *
 */
/*@{*/
#define GWEN_DIR_FLAGS_PUBLIC_PATH 0x00010000
#define GWEN_DIR_FLAGS_PUBLIC_NAME 0x00020000
/*@}*/



/**
 * @defgroup MOD_DIRECTORY Directory Functions
 * @ingroup MOD_OS
 * @short Provides secure interprocess communication
 * @author Martin Preuss<martin@libchipcard.de>
 */
/*@{*/

/**
 * Constructor.
 */
GWENHYWFAR_API GWEN_DIRECTORY *GWEN_Directory_new();

/**
 * Destructor
 */
GWENHYWFAR_API void GWEN_Directory_free(GWEN_DIRECTORY *d);

/**
 * Opens a directory. This allows calling "Directory_Read" to succeed.
 * @author Martin Preuss<martin@libchipcard.de>
 * @return 0 if ok, !=0 on error (e.g. if no such directory exists; see opendir(3) and errno for the detailed error)
 * @param d pointer to a directory data structure. This should be created
 * by calling @ref GWEN_Directory_new().
 * @param n path and name of the directory to open
 */
GWENHYWFAR_API
  int GWEN_Directory_Open(GWEN_DIRECTORY *d, const char *n);

/**
 * Closes a previously opened directory.
 * @author Martin Preuss<martin@libchipcard.de>
 * @return 0 if ok, !=0 on error
 * @param d pointer to a directory data structure. This should be created
 * by calling @ref GWEN_Directory_new().
 */
GWENHYWFAR_API int GWEN_Directory_Close(GWEN_DIRECTORY *d);

/**
 * Reads the next entry from a directory and stores the name of that
 * entry in the given buffer. The entry returned is relative to the
 * open directory.
 * @author Martin Preuss<martin@libchipcard.de>
 * @return 0 if ok, !=0 on error
 * @param d pointer to a directory data structure. This should be created
 * by calling @ref GWEN_Directory_new().
 * @param buffer pointer to a buffer to receive the name
 * @param len size of the buffer
 */
GWENHYWFAR_API int GWEN_Directory_Read(GWEN_DIRECTORY *d,
                                       char *buffer,
                                       unsigned int len);

/**
 * Rewinds the internal pointers, so that the next call to
 * @author Martin Preuss<martin@libchipcard.de>
 * @ref GWEN_Directory_Read will return the first entry of the open directory.
 * @return 0 if ok, !=0 on error
 * @param d pointer to a directory data structure. This should be created
 * by calling @ref GWEN_Directory_new().
 */
GWENHYWFAR_API int GWEN_Directory_Rewind(GWEN_DIRECTORY *d);


/**
 * Gets the current user's home directory and copies it into the
 * given buffer.
 *
 * On Unix, this looks up the passwd entry of the current user,
 * similar to glib's g_get_home_dir(). Watch out: The environment
 * variable "HOME" is *not* used, not even as a fallback if there
 * is no passwd entry (different from g_get_home_dir()).
 *
 * On Windows, this looks up the environment variable "HOME", then
 * "USERPROFILE", then the Windows system directory. This
 * behaviour is identical to glib's g_get_home_dir(). Watch out:
 * In the normal non-mingw/msys environment, only "USERPROFILE" is
 * set, e.g. to "c:\Documents\Yourusername". But if this function
 * is called from within msys, then msys itself has set "HOME" to
 * a different value, e.g. to "c:\msys\1.0\home\yourusername". In
 * effect, your program will see a different home directory when
 * run from within msys compared to without msys. This is weird,
 * but it is identical to the glib behaviour and hence we leave it
 * at that.
 *
 * @return 0 if ok, !=0 on error
 */
GWENHYWFAR_API
int GWEN_Directory_GetHomeDirectory(char *buffer, unsigned int size);

/**
 * Gets the directory to use for temporary files and copies it
 * into the given buffer.
 *
 * This is found from inspecting the environment variables TMPDIR,
 * TMP, and TEMP in that order. If none of those are defined,
 * "/tmp" is returned on UNIX and "C:\" on Windows. This is
 * similar to glib's g_get_tmp_dir().
 *
 * @return 0 if ok, !=0 on error
 */
GWENHYWFAR_API
int GWEN_Directory_GetTmpDirectory(char *buffer, unsigned int size);

/**
 * Gets the prefix to which the calling executable was installed, e.g.
 * if the executable was installed using prefix "/usr" then the binary
 * itself will be in "/usr/bin". In this case this function will return
 * the directory name "/usr".
 * Please note that this function only looks at the folder at which the
 * calling exectuable is located when this function is called, so if you
 * move the binary to another place then the result will be different.
 */
GWENHYWFAR_API
int GWEN_Directory_GetPrefixDirectory(char *buffer, unsigned int size);


/**
 * Gets a file path. It uses @ref MOD_PATH to either create or check for
 * the existence of a given path.
 * @return 0 if ok, !=0 on error
 * @param path path to inspect
 * @param flags flags, please see @ref GWEN_PATH_FLAGS_PATHMUSTEXIST et. al.
 */
GWENHYWFAR_API
int GWEN_Directory_GetPath(const char *path, unsigned int flags);


/**
 * Creates a directory.
 */
GWENHYWFAR_API
int GWEN_Directory_Create(const char *path);

/**
 * Creates a public directory (a folder which can be listed and entered
 * by anyone)
 */
GWENHYWFAR_API
int GWEN_Directory_CreatePublic(const char *path);

/**
 * Takes a path and translates it into a path that the running platform
 * can understand.
 * This is needed for unix paths used on Windows.
 * If transformDriveElement is !=0 on Windows platforms and the first element
 * of the path is "/x" (with x being [a..z,A..Z]) then this element is
 * translated into the corresponding drive letter sequence (x:).
 * Slashes and backslashes are transformed as needed by the running platform.
 * Duplicate slashes/backslashed are removed.
 * @param path path to translate
 * @param pbuf buffer to which the path is appended
 * @param transformDriveElemen see above (ignored on non-win32 platforms)
 */
GWENHYWFAR_API
int GWEN_Directory_OsifyPath(const char *path, GWEN_BUFFER *pbuf,
                             int transformDriveElement);


GWENHYWFAR_API
int GWEN_Directory_FindFileInPaths(const GWEN_STRINGLIST *paths,
                                   const char *filePath,
                                   GWEN_BUFFER *fbuf);

GWENHYWFAR_API
int GWEN_Directory_FindPathForFile(const GWEN_STRINGLIST *paths,
                                   const char *filePath,
                                   GWEN_BUFFER *fbuf);

/**
 * This function reads all entries of the given folder and stores them
 * in the given string list if they match a mask.
 *
 * The entries added to the string list are the names returned by the
 * operating systems. They do not contain the full path.
 *
 * @param folder folder to inspect
 * @param sl string list to add new entries to
 * @param mask if omitted, all entries match (wildcards and jokers allowed)
 */
GWENHYWFAR_API
int GWEN_Directory_GetAllEntries(const char *folder,
				 GWEN_STRINGLIST *sl,
				 const char *mask);

/**
 * This function does the same as @ref GWEN_Directory_GetAllEntries, but
 * in addition a entry type indicator is prepended to the entries added
 * to the string list.
 * Known indicators are:
 * <ul>
 *   <li><b>d</b>: entry is a directory</li>
 *   <li><b>f</b>: entry is a file</li>
 *   <li><b>?</b>: entry type is unknown</li>
 * </ul>
 *
 * @param folder folder to inspect
 * @param sl string list to add new entries to
 * @param mask if omitted, all entries match (wildcards and jokers allowed)
 */
GWENHYWFAR_API
int GWEN_Directory_GetFileEntriesWithType(const char *folder,
					  GWEN_STRINGLIST *sl,
					  const char *mask);

/**
 * This function does the same as @ref GWEN_Directory_GetAllEntries, but
 * it only adds file entries.
 *
 * @param folder folder to inspect
 * @param sl string list to add new entries to
 * @param mask if omitted, all entries match (wildcards and jokers allowed)
 */
GWENHYWFAR_API
int GWEN_Directory_GetFileEntries(const char *folder,
				  GWEN_STRINGLIST *sl,
				  const char *mask);


/**
 * This function does the same as @ref GWEN_Directory_GetAllEntries, but
 * it only adds folder entries.
 *
 * @param folder folder to inspect
 * @param sl string list to add new entries to
 * @param mask if omitted, all entries match (wildcards and jokers allowed)
 */
GWENHYWFAR_API
int GWEN_Directory_GetDirEntries(const char *folder,
				 GWEN_STRINGLIST *sl,
				 const char *mask);


/**
 * This function adds all matching files to the given string list recursively.
 *
 * @param folder folder to inspect (including sub-folders)
 * @param sl string list to add new entries to
 * @param mask if omitted, all entries match (wildcards and jokers allowed)
 */
GWENHYWFAR_API
int GWEN_Directory_GetMatchingFilesRecursively(const char *folder,
					       GWEN_STRINGLIST *sl,
					       const char *mask);


/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif


#endif /* GWEN_DIRECTORY_H */




