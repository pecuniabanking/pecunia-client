/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Sun Dec 05 2003
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

#ifndef GWENHYWFAR_INHERIT_H
#define GWENHYWFAR_INHERIT_H

#ifdef __cplusplus
extern "C" {
#endif
typedef struct GWEN_INHERITDATA GWEN_INHERITDATA;
#ifdef __cplusplus
}
#endif


#include <gwenhywfar/misc.h>
#include <gwenhywfar/gwenhywfarapi.h>


#ifdef __cplusplus
extern "C" {
#endif


  /** @defgroup GWEN_MACRO_INHERIT Macros For Typesafe Inheritance
   *
   */
  /*@{*/
  typedef void GWENHYWFAR_CB (*GWEN_INHERIT_FREEDATAFN)(void *baseData,
                                                        void *data);

  GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_INHERITDATA, GWEN_InheritData, GWENHYWFAR_API)
  /* No trailing semicolon because this is a macro call */

  GWENHYWFAR_API 
  GWEN_INHERITDATA *GWEN_InheritData_new(const char *t,
                                         uint32_t id,
                                         void *data,
                                         void *baseData,
                                         GWEN_INHERIT_FREEDATAFN fn);
  GWENHYWFAR_API 
  void GWEN_InheritData_free(GWEN_INHERITDATA *d);

  GWENHYWFAR_API 
  void GWEN_InheritData_freeData(GWEN_INHERITDATA *d);

  GWENHYWFAR_API
  void GWEN_InheritData_freeAllData(GWEN_INHERITDATA *d);

  GWENHYWFAR_API
    void GWEN_InheritData_clear(GWEN_INHERITDATA *d);

  GWENHYWFAR_API 
  const char *GWEN_InheritData_GetTypeName(const GWEN_INHERITDATA *d);

  GWENHYWFAR_API 
  uint32_t GWEN_InheritData_GetId(const GWEN_INHERITDATA *d);

  GWENHYWFAR_API 
  void *GWEN_InheritData_GetData(const GWEN_INHERITDATA *d);

  GWENHYWFAR_API 
    GWEN_INHERIT_FREEDATAFN
    GWEN_InheritData_GetFreeDataFn(const GWEN_INHERITDATA *d);

  GWENHYWFAR_API 
  uint32_t GWEN_Inherit_MakeId(const char *typeName);

  GWENHYWFAR_API 
  void* GWEN_Inherit_FindData(GWEN_INHERITDATA_LIST *l,
                              uint32_t id,
                              int wantCreate);

  GWENHYWFAR_API
    GWEN_INHERITDATA *GWEN_Inherit_FindEntry(GWEN_INHERITDATA_LIST *l,
                                             uint32_t id,
                                             int wantCreate);

  /** @name Macros To Be Used In Inherited Classes - Header Files
   *
   */
  /*@{*/
  /**
   * Use this macro inside the struct which you want to make inheritable.
   * This macro defines some new elements for the struct for administration
   * of inheritance.
   */
#define GWEN_INHERIT_ELEMENT(t) \
  GWEN_INHERITDATA_LIST *INHERIT__list;

  /**
   * Use this macro in the header file of the base class. This defines
   * the prototypes of some inheritance functions. This macro should
   * be used in libraries with the __declspec(dllexport) as the @c
   * decl argument.
   *
   * You should not care about these functions here, since you should not use
   * them directly. Please use @ref GWEN_INHERIT_GETDATA and
   * @ref GWEN_INHERIT_SETDATA instead.
   */
#define GWEN_INHERIT_FUNCTION_LIB_DEFS(t, decl) \
  decl void t##__INHERIT_SETDATA(t *element, \
                                 const char *typeName,\
                                 uint32_t id,\
                                 void *data,\
                                 GWEN_INHERIT_FREEDATAFN f);\
  decl int t##__INHERIT_ISOFTYPE(const t *element, uint32_t id);\
  decl GWEN_INHERITDATA_LIST *t##__INHERIT_GETLIST(const t *element);\
  decl void t##__INHERIT_UNLINK(t *element, \
                                const char *typeName,\
                                uint32_t id);

  /**
   * Use this macro in the header file of the base class. This defines
   * the prototypes of some inheritance functions. This macro should
   * be used in applications, not in libraries. In libraries please
   * use the macro @ref GWEN_INHERIT_FUNCTION_LIB_DEFS.
   *
   * You should not care about these functions here, since you should not use
   * them directly. Please use @ref GWEN_INHERIT_GETDATA and
   * @ref GWEN_INHERIT_SETDATA instead.
   */
#define GWEN_INHERIT_FUNCTION_DEFS(t) \
  GWEN_INHERIT_FUNCTION_LIB_DEFS(t, GWEN_DUMMY_EMPTY_ARG)

  /*@}*/


  /** @name Macros To Be Used In Inherited Classes - C Files
   *
   */
  /*@{*/
  /**
   * Use this macro in the C file of the base class. It defines the
   * implementations of the inheritance functions. This macro MUST be
   * placed after the include statement which includes the classes header
   * file.
   */
#define GWEN_INHERIT_FUNCTIONS(t) \
  GWEN_INHERITDATA_LIST *t##__INHERIT_GETLIST(const t *element) {\
  assert(element);\
  return element->INHERIT__list;\
  }\
  \
  void t##__INHERIT_SETDATA(t *element, \
                            const char *typeName,\
                            uint32_t id,\
                            void *data,\
                            GWEN_INHERIT_FREEDATAFN f) {\
  GWEN_INHERITDATA *d;\
  void *p;\
    \
    assert(element);\
    assert(element->INHERIT__list);\
    \
    p=GWEN_Inherit_FindData(element->INHERIT__list, id, 1);\
    if (p) {\
      fprintf(stderr,\
              "ERROR: Type \"%s\" already inherits base type\n",\
              typeName);\
      abort();\
    }\
    d=GWEN_InheritData_new(typeName, id, data, (void*)element, f);\
    GWEN_InheritData_List_Insert(d, element->INHERIT__list);\
  }\
  \
  int t##__INHERIT_ISOFTYPE(const t *element, uint32_t id) {\
    assert(element);\
    assert(element->INHERIT__list);\
  \
    return (GWEN_Inherit_FindData(element->INHERIT__list, id, 1)!=0);\
  }\
  \
  void t##__INHERIT_UNLINK(t *element, \
                           const char *typeName,\
                           uint32_t id) {\
    GWEN_INHERITDATA *d;\
    \
    assert(element);\
    assert(element->INHERIT__list);\
    \
    d=GWEN_Inherit_FindEntry(element->INHERIT__list, id, 1);\
    if (!d) {\
      fprintf(stderr, \
              "ERROR: Type \"%s\" does not inherit base type\n",\
              typeName);\
      abort();\
    }\
    GWEN_InheritData_clear(d);\
    GWEN_InheritData_List_Del(d);\
    GWEN_InheritData_free(d);\
  }

  /**
   * Use this macro in your C file in constructor functions for the base
   * class. This macro initializes the elements defined by the macro
   * @ref GWEN_INHERIT_ELEMENT.
   */
#define GWEN_INHERIT_INIT(t, element) {\
    assert(element);\
    element->INHERIT__list=GWEN_InheritData_List_new();\
  }


  /**
   * Use this macro in your C file in destructor functions for the base
   * class. This macro deinitializes the elements defined by the macro
   * @ref GWEN_INHERIT_ELEMENT. This should be the first instruction in that
   * function, because it also gives inheriting classes the opportunity to
   * free their own data associated with the given element. It causes the
   * least problems if inheriting classes free their data before the base
   * class does.
   */
#define GWEN_INHERIT_FINI(t, element) {\
    GWEN_INHERITDATA *inherit__data;\
    \
    assert(element);\
    assert(element->INHERIT__list);\
    \
    while( (inherit__data=GWEN_InheritData_List_First(element->INHERIT__list)) ) {\
      GWEN_InheritData_freeData(inherit__data); \
      GWEN_InheritData_List_Del(inherit__data); \
      GWEN_InheritData_free(inherit__data); \
    } \
    GWEN_InheritData_List_free(element->INHERIT__list);\
  }

  /*@}*/

  /** @name Macros To Be Used In Inheriting Classes
   *
   */
  /*@{*/
  /**
   * Use this in the C file of inheriting classes. It initializes a global
   * variable with a hash of the inheriting type name. This is used to speed
   * up inheritance functions. This variable will be filled with a value
   * upon the first invocation of the macro @ref GWEN_INHERIT_SETDATA.
   */
#define GWEN_INHERIT(bt, t) \
  uint32_t t##__INHERIT_ID=0;

  /**
   * This macros returns the private data of an inheriting class associated
   * with an element of its base class.
   */
#define GWEN_INHERIT_GETDATA(bt, t, element) \
  ((t*)GWEN_Inherit_FindData(bt##__INHERIT_GETLIST(element),t##__INHERIT_ID,0))

  /**
   * This macro sets the private data of an inheriting class associated
   * with an element of its base class. The last argument is a pointer to a
   * function which frees the associated data. That function will be called
   * when the element of the base class given is freed or new data is to be
   * associated with the element.
   * The prototype of that function is this:
   * @code
   * typedef void (*function)(void *baseData, void *data);
   * @endcode
   * Please note that the argument to that function is a pointer to the
   * base type element. If you want to get the private data associated with
   * the base type element (and you probably do) you must call
   * @ref GWEN_INHERIT_GETDATA.
   * Every time the macro @ref GWEN_INHERIT_SETDATA is used the previously
   * associated data will be freed by calling the function whose prototype
   * you've just learned.
   */
#define GWEN_INHERIT_SETDATA(bt, t, element, data, fn) {\
    if (!t##__INHERIT_ID)\
      t##__INHERIT_ID=GWEN_Inherit_MakeId(__STRING(t));\
    bt##__INHERIT_SETDATA(element, __STRING(t), t##__INHERIT_ID, data, fn);\
  }

  /**
   * This macro checks whether the given element is of the given type.
   * @return !=0 if the pointer is of the expected type, 0 otherwise
   * @param bt base type
   * @param t derived type
   * @param element pointer which is to be checked
   */
#define GWEN_INHERIT_ISOFTYPE(bt, t, element) \
  ((bt##__INHERIT_ISOFTYPE(element,\
                           ((t##__INHERIT_ID==0)?\
                            ((t##__INHERIT_ID=GWEN_Inherit_MakeId(__STRING(t)))):\
                            t##__INHERIT_ID)))?1:0)

  /**
   * This macro gives up the inheritance for the given type. After this
   * macro has been executed there is no link left between the type and
   * its base type.
   * @param bt base type
   * @param t derived type
   */
#define GWEN_INHERIT_UNLINK(bt, t, element) {\
    if (!t##__INHERIT_ID)\
      t##__INHERIT_ID=GWEN_Inherit_MakeId(__STRING(t));\
    bt##__INHERIT_UNLINK(element, __STRING(t), t##__INHERIT_ID);\
  }

  /*@}*/

  /*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif



#endif /* GWENHYWFAR_INHERIT_P_H */



