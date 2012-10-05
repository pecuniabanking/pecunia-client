/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Sat Jun 28 2003
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


#ifndef GWENHYWFAR_MEMORY_H
#define GWENHYWFAR_MEMORY_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/error.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>



#ifdef __cplusplus
extern "C" {
#endif


  /* this is taken from the system header file assert.h and
   * and modified by me (Martin Preuss).
   */
# if defined __cplusplus ? __GNUC_PREREQ (2, 6) : __GNUC_PREREQ (2, 4)
#   define GWEN_LOCATION_FUNCTION	__PRETTY_FUNCTION__
# else
#  if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#   define GWEN_LOCATION_FUNCTION	__func__
#  else
#   define GWEN_LOCATION_FUNCTION	((__const char *) "unknown function")
#  endif
# endif


  GWENHYWFAR_API
  void *GWEN_Memory_malloc(size_t dsize);
  GWENHYWFAR_API
  void GWEN_Memory_dealloc(void *p);

  GWENHYWFAR_API
  void *GWEN_Memory_realloc(void *oldp, size_t nsize);

  GWENHYWFAR_API 
  char *GWEN_Memory_strdup(const char *s);

  GWENHYWFAR_API 
  void GWEN_Memory_Collect();

  GWENHYWFAR_API 
  void GWEN_Memory_Dump();


#define GWEN_MEM_NEW(typ, memptr) \
  memptr=(typ*)GWEN_Memory_malloc(sizeof(typ));

#define GWEN_MEM_FREE(varname) \
  GWEN_Memory_dealloc((void*)varname);


#define GWEN_NEW_OBJECT(typ, varname)\
  {\
    varname=(typ*)GWEN_Memory_malloc(sizeof(typ)); \
    memset(varname, 0, sizeof(typ));\
  }

#define GWEN_FREE_OBJECT(varname) \
  GWEN_Memory_dealloc((void*)varname);


#ifdef __cplusplus
}
#endif


#endif /* GWENHYWFAR_MEMORY_H */

