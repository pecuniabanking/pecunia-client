/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Tue Sep 09 2003
 copyright   : (C) 2003 by Martin Preuss
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


#ifndef GWENHYWFAR_PATH_H
#define GWENHYWFAR_PATH_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/buffer.h>


#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup MOD_PATH Paths
 * @ingroup MOD_PARSER
 *
 * @brief These functions work on general paths.
 *
 * A path consists of a list of elements separated by a slash, like in
 * <i>/element1/element2/element3</i>.
 * An element can either be a <i>group</i> or an <i>item</i>.
 * Groups can contain multiple items and groups, but an item can not contain
 * anything.
 * So there can at most be <strong>one</strong> item, and it must be the
 * last element.
 * An example of how to use these functions is given in the module
 * @ref MOD_DB. These functions can also be used with files and folders. In
 * this case a group corresponds to a folder and items correspond to files.
 */
/*@{*/

/**
 * @name Path Flags
 *
 * The path flags only use the lower word of the integer. The high word
 * may be used/interpreted by the called function.
 */
/*@{*/
/**
 * if this is set then all elements of the path must exist.
 */
#define GWEN_PATH_FLAGS_PATHMUSTEXIST          0x00000001
/**
 * if this is set then none of the elements of the path must exist.
 */
#define GWEN_PATH_FLAGS_PATHMUSTNOTEXIST       0x00000002

/**
 * if this bit is set then the whole path (at any depth!) will be created.
 * This may lead to double entries at any part of the path.
 * You need this in very rare cases, most likely you want
 * @ref GWEN_PATH_FLAGS_NAMEMUSTEXIST.
 */
#define GWEN_PATH_FLAGS_PATHCREATE             0x00000004

/**
 * if this bit is set then the last element of the path MUST exist.
 * This implies @ref GWEN_PATH_FLAGS_PATHMUSTEXIST
 */
#define GWEN_PATH_FLAGS_NAMEMUSTEXIST          0x00000008

/**
 * if this bit is set then the last element of the path MUST NOT exist.
 */
#define GWEN_PATH_FLAGS_NAMEMUSTNOTEXIST       0x00000010

/**
 * if this bit is set then the last element of the path is created in any
 * case (this is for groups).
 * This may lead to double entries of the last element.
 */
#define GWEN_PATH_FLAGS_CREATE_GROUP            0x00000020

/**
 * if this bit is set then the last element of the path is created in any
 * case (this is for variables).
 * This may lead to double entries of the last element.
 */
#define GWEN_PATH_FLAGS_CREATE_VAR              0x00000040

/**
 * a variable is wanted (if this bit is 0 then a group is wanted).
 * This flag is used internally, too. When the path handler function
 * is called by @ref GWEN_Path_Handle then this flag is modified
 * to reflect the type of the current path element.
 */
#define GWEN_PATH_FLAGS_VARIABLE                0x00000080


/**
 * all elements of the path are to be escaped.
 * This is usefull when used with file names etc. It makes sure that the
 * path elements presented to the path element handler function only
 * consist of alphanumeric characters. All other characters are escaped
 * using @ref GWEN_Text_Escape.
 */
#define GWEN_PATH_FLAGS_ESCAPE                  0x00000100

/** use the same flag for both escape and unescape */
#define GWEN_PATH_FLAGS_UNESCAPE                0x00000100

/* be more tolerant, don't escape common characters such as '.' */
#define GWEN_PATH_FLAGS_TOLERANT_ESCAPE         0x00000200

/**
 * Allow to also escape/unescape the last path element (otherwise it will
 * not be escaped/unescaped).
 */
#define GWEN_PATH_FLAGS_CONVERT_LAST            0x00000400

/**
 * Allows checking for root. If the path begins with a slash ('/') and this
 * flags is set the slash will be included in the first path element
 * passed to the element handler function. Additionally the flag
 * @ref GWEN_PATH_FLAGS_ROOT will be set. Otherwise there will be no check
 * and special treatment of root entries.
 */
#define GWEN_PATH_FLAGS_CHECKROOT               0x00000800

/**
 * This flag is only used with @ref GWEN_Path_HandleWithIdx to disable
 * index handling.
 */
#define GWEN_PATH_FLAGS_NO_IDX                  0x00001000

/**
 *
 */
#define GWEN_PATH_FLAGS_RFU1                    0x00002000


/**
 * @internal
 */
#define GWEN_PATH_FLAGS_INTERNAL                0x0000c000

/**
 * @internal
 * this is flagged for the path function. If this is set then the
 * element given is the last one, otherwise it is not.
 */
#define GWEN_PATH_FLAGS_LAST                    0x00004000

/**
 * @internal
 * this is flagged for the path function. If this is set then the
 * element given is within root (in this case the element passed to the
 * element handler funcion will start with a slash), otherwise it is not.
 */
#define GWEN_PATH_FLAGS_ROOT                    0x00008000

/*@}*/



typedef void* (*GWEN_PATHHANDLERPTR)(const char *entry,
                                     void *data,
                                     uint32_t flags);

typedef void* (*GWEN_PATHIDXHANDLERPTR)(const char *entry,
                                        void *data,
                                        int idx,
                                        uint32_t flags);


/**
 * This function works on a path according to the given flags.
 * For every element the given function is called.
 * A path consists of multiple elements separated by a slash ("/"),
 * e.g. "first/second/element".
 * This function is used by the DB module but may also be used for any
 * type of path handling (like creating all directories along a given path).
 * This function simply calls the given function for any element as long as
 * that function returns a non-zero value or the path ends.
 * The type of the returned value completely depends on the function called.
 * @return 0 on error, !=0 otherwise
 */
GWENHYWFAR_API
  void *GWEN_Path_Handle(const char *path,
			 void *data,
			 uint32_t flags,
			 GWEN_PATHHANDLERPTR elementFunction);

GWENHYWFAR_API
  void *GWEN_Path_HandleWithIdx(const char *path,
				void *data,
				uint32_t flags,
				GWEN_PATHIDXHANDLERPTR elementFunction);


/**
 * Converts the given path according to the given flags.
 * You can use this function to escape, unescape or simply store  all path
 * elements within a buffer. The converted path will simply be appended to
 * the given buffer (without any leading slash).
 */
GWENHYWFAR_API
  int GWEN_Path_Convert(const char *path,
                        GWEN_BUFFER *buffer,
                        uint32_t flags);


/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif


#endif /* GWENHYWFAR_PATH_H */

