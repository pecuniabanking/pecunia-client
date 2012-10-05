/***************************************************************************
 begin       : Fri Jan 02 2009
 copyright   : (C) 2009 by Martin Preuss
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


#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <assert.h>


#ifndef GWEN_DUMMY_EMPTY_ARG
/** Necessary for MSVC compiler because it does not accept a left-out
    macro argument. */
# define GWEN_DUMMY_EMPTY_ARG
#endif


#ifndef GWEN_TREE_H
#define GWEN_TREE_H


#ifdef __cplusplus
extern "C" {
#endif


/** @defgroup GWEN_MACRO_TREE Macros For Typesafe Tree Handling
 *
 * The macros of this group facilitates typesafe use of trees.
 *
 * <p>
 * Let's assume you have a structure type called MYSTRUCT and you want
 * to manage lists of them. Let's further assume that you want the
 * functions dealing with that struct have prefixes like MyStruct (as in
 * @b MyStruct_new)
 * </p>
 * The header file would look like this:
 *
 * @code
 *
 * / * mystruct.h * /
 *
 * #ifndef MYSTRUCT_H
 * #define MYSTRUCT_H
 *
 * typedef struct MYSTRUCT MYSTRUCT;
 *
 * GWEN_TREE_FUNCTION_DEFS(MYSTRUCT, MyStruct);
 *
 * struct MYSTRUCT {
 *   GWEN_TREE_ELEMENT(MYSTRUCT);
 *   int myData;
 * }
 *
 *
 * MYSTRUCT *MyStruct_new(int myData);
 * void MyStruct_free(MYSTRUCT *myStruct);
 *
 * #endif
 * @endcode
 * <p>
 * This defines all necessary data and function prototypes needed for
 * list management.
 * </p>
 *
 * <p>
 * The code file would look quite similar to the following:
 * </p>
 *
 * @code
 *
 * / * mystruct.c * /
 *
 * GWEN_TREE_FUNCTIONS(MYSTRUCT, MyStruct)
 *
 * MYSTRUCT *MyStruct_new(int myData) {
 *   MYSTRUCT *pMyStruct;
 *
 *   pMyStruct=(MYSTRUCT*)malloc(sizeof(MYSTRUCT));
 *   memset(pMyStruct, 0, sizeof(MYSTRUCT));
 *
 *   GWEN_TREE_INIT(MYSTRUCT, pMyStruct)
 *
 *   pMyStruct->myData=myData;
 *   return pMyStruct;
 * }
 *
 * void MyStruct_free(MYSTRUCT *pMyStruct) {
 *   if (pMyStruct) {
 *     pMyStruct->myData=0;
 *
 *     GWEN_TREE_FINI(MYSTRUCT, pMyStruct)
 *
 *     free(pMyStruct);
 *   }
 * }
 *
 * @endcode
 * Please note the three macros used in the code file:
 * <ul>
 *   <li>@ref GWEN_TREE_FUNCTIONS creates the functions for the list
 *       management</li>
 *   <li>@ref GWEN_TREE_INIT initializes the list data inside your
 *       struct to defined values </li>
 *   <li>@ref GWEN_TREE_FINI frees all ressources occupied by the list
 *       management code. Please note that this macro should be the last
 *       statement inside the destructor function before @b free()</li>
 * </ul>
 *
 * <p>Note: When writing these macro code lines, the original ISO
 * C89 standard for the C language does not allow terminating the
 * macro statement with a semicolon ';'. Any recent compiler will
 * probably silently ignore such an extra ';', but you should be
 * aware that this can cause problems once one of your users tries
 * to compile this with a different compiler. Therefore these code
 * lines should end directly with the closing parentheses.</p>
 * 
 * <p>
 * The list management code assumes that there is a function called
 * (in this example) @b MyStruct_free() (or generally: TYPEPREFIX_free).
 * This is used when destroying a list of MYSTRUCT elements. In this case
 * all elements still enlisted are destroyed upon destruction of the list.
 * </p>
 */
/*@{*/


/** @name Internal Functions
 *
 * All functions and structs within this group should be considered
 * internal. They just implement the functionality behind the typesafe list
 * macros (see @ref GWEN_TREE_FUNCTION_LIB_DEFS and following).
 */
/*@{*/
typedef struct GWEN_TREE GWEN_TREE;
typedef struct GWEN_TREE_ELEMENT GWEN_TREE_ELEMENT;


/** Allocate (create) a new empty list. */
GWENHYWFAR_API
GWEN_TREE *GWEN_Tree_new();

/** Free (delete) an existing list.  The list elements are
 * untouched by this function; they need to be freed
 * beforehand. */
GWENHYWFAR_API
void GWEN_Tree_free(GWEN_TREE *l);

/** Returns the number of elements in this list. This value is
 * cached in the list structure, so this function is a cheap
 * function. */
GWENHYWFAR_API
int GWEN_Tree_GetCount(const GWEN_TREE *l);

/** Adds (appends) a toplevel tree element. (This
 * operation is also called "append" or "push_back" elsewhere.) */
GWENHYWFAR_API
void GWEN_Tree_Add(GWEN_TREE *l, GWEN_TREE_ELEMENT *el);

/** Inserts (prepends) a toplevel tree element at the beginning of the
 * list. (This operation is also called "prepend" or "push_front"
 * elsewhere.) */
GWENHYWFAR_API
void GWEN_Tree_Insert(GWEN_TREE *l, GWEN_TREE_ELEMENT *el);

/** Deletes (removes) a tree element from the tree it used to
 * belong to. The tree element is not free'd or anything, it is
 * only removed from the list it used to belong to. (This
 * operation is also called "remove" or "unlink" elsewhere.) */
GWENHYWFAR_API
void GWEN_Tree_Del(GWEN_TREE_ELEMENT *el);

/** Adds (appends) the second list to the end of the first
 * list. (This operation is also called "append" or "concatenate"
 * elsewhere.)
 * The second list will be empty upon return.
 */
GWENHYWFAR_API
void GWEN_Tree_AddList(GWEN_TREE *dest, GWEN_TREE *l);

/** Add a child below the given element. */
GWENHYWFAR_API
void GWEN_Tree_AddChild(GWEN_TREE_ELEMENT *where, GWEN_TREE_ELEMENT *el);

/** Insert a child below the given element. */
GWENHYWFAR_API
void GWEN_Tree_InsertChild(GWEN_TREE_ELEMENT *where, GWEN_TREE_ELEMENT *el);


/** Returns the data pointer of the first list element. */
GWENHYWFAR_API
void *GWEN_Tree_GetFirst(const GWEN_TREE *l);

/** Returns the data pointer of the last list element. */
GWENHYWFAR_API
void *GWEN_Tree_GetLast(const GWEN_TREE *l);



/** Allocate (create) a new list element structure. */
GWENHYWFAR_API
GWEN_TREE_ELEMENT *GWEN_TreeElement_new(void *d);

/** Free (delete) a list element structure. */
GWENHYWFAR_API
void GWEN_TreeElement_free(GWEN_TREE_ELEMENT *el);

/** Returns the data pointer of the list element that is the
 * previous (predecessor) to the given one in its list. If there
 * is no such prepending list element, returns NULL. */
GWENHYWFAR_API
void *GWEN_TreeElement_GetPrevious(const GWEN_TREE_ELEMENT *el);

/** Returns the data pointer of the list element that is the next
 * one (successor) to the given one in its list. If there is no
 * such prepending list element, returns NULL. */
GWENHYWFAR_API
void *GWEN_TreeElement_GetNext(const GWEN_TREE_ELEMENT *el);

/** Returns the element which is logically below the given one.
 * The order of search is this:
 * <ul>
 *  <li>first child of the given element </li>
 *  <li>next neighbour of the given element </li>
 *  <li>loop for every parent: check next neighbour of the given element's parent (if any) </li>
 * </ul>
 */
GWENHYWFAR_API
void *GWEN_TreeElement_GetBelow(const GWEN_TREE_ELEMENT *el);

/** Returns the first child of the given element. */
GWENHYWFAR_API
void *GWEN_TreeElement_GetFirstChild(const GWEN_TREE_ELEMENT *el);

/** Returns the last child of the given element. */
GWENHYWFAR_API
void *GWEN_TreeElement_GetLastChild(const GWEN_TREE_ELEMENT *el);

GWENHYWFAR_API
void *GWEN_TreeElement_GetParent(const GWEN_TREE_ELEMENT *el);

/** Returns the number of children of the given element */
GWENHYWFAR_API
uint32_t GWEN_TreeElement_GetChildrenCount(const GWEN_TREE_ELEMENT *el);

/*@}*/


/** @name Typesafe Macros
 *
 */
/*@{*/

/**
 * Use this inside the declaration of a struct for which you want to create
 * lists.
 */
#define GWEN_TREE_ELEMENT(t) \
GWEN_TREE_ELEMENT *_tree_element;

/**
 * Use this macro in your public header files to export only list functions
 * which do not modify a list. This allows your code to return lists which can
 * not be modified by callers. It also prevents callers from creating their
 * own lists (this is sometimes needed).
 */
#define GWEN_TREE_FUNCTION_LIB_DEFS_CONST(t, pr, decl) \
  typedef GWEN_TREE t##_TREE; \
  \
  decl t* pr##_Tree_GetFirst(const t##_TREE *l); \
  decl t* pr##_Tree_GetLast(const t##_TREE *l); \
  decl t* pr##_Tree_GetNext(const t *element); \
  decl t* pr##_Tree_GetPrevious(const t *element); \
  decl t* pr##_Tree_GetBelow(const t *element); \
  decl uint32_t pr##_Tree_GetCount(const t##_TREE *l); \
  decl int pr##_Tree_HasElement(const t##_TREE *l, const t *element); \
  decl t* pr##_Tree_GetFirstChild(const t *element); \
  decl t* pr##_Tree_GetLastChild(const t *element); \
  decl uint32_t pr##_Tree_GetChildrenCount(const t *element); \
  decl t* pr##_Tree_GetParent(const t *element);


#define GWEN_TREE_FUNCTION_LIB_DEFS_NOCONST(t, pr, decl) \
  typedef GWEN_TREE_ELEMENT t##_TREE_ELEMENT; \
  \
  decl void pr##_Tree_Clear(t##_TREE *l); \
  decl t##_TREE* pr##_Tree_new(); \
  decl void pr##_Tree_free(t##_TREE *l); \
  decl void pr##_Tree_AddList(t##_TREE *dst, t##_TREE *l); \
  decl void pr##_Tree_Add(t##_TREE *list, t *element); \
  decl void pr##_Tree_Insert(t##_TREE *list, t *element); \
  decl void pr##_Tree_Del(t *element); \
  \
  decl void pr##_Tree_AddChild(t *where, t *element); \
  decl void pr##_Tree_InsertChild(t *where, t *element); \
  \
  decl int pr##_Tree_HasChildElement(const t *who, const t *element); \
  decl void pr##_Tree_ClearChildren(t *element); \


#define GWEN_TREE_FUNCTION_DEFS_CONST(t, pr) \
  GWEN_TREE_FUNCTION_LIB_DEFS_CONST(t, pr, GWEN_DUMMY_EMPTY_ARG)

#define GWEN_TREE_FUNCTION_DEFS_NOCONST(t, pr) \
  GWEN_TREE_FUNCTION_LIB_DEFS_NOCONST(t, pr, GWEN_DUMMY_EMPTY_ARG)


/**
 * Use this in public header files to define some prototypes for list
 * functions.
 * Let's assume the type of your list elements is "MYTYPE" and you want to
 * use the prefix "MyType_" for the list functions.
 * The following function prototypes will then be created:
 * <ul>
 *  <li>
 *    void MyType_Tree_Add(MYTYPE *element, MYTYPE_TREE *list);<br>
 *    Adds (appends) a MYTYPE struct at the end of the given
 *    list. (We apologize for the unusual argument order here.)
 *  </li>
 *  <li>
 *    void MyType_Tree_Del(MYTYPE *element);<br>
 *    Removes a MyType struct from the list it is enlisted to.
 *  </li>
 *  <li>
 *    MYTYPE *MyType_Tree_First(MYTYPE *element); <br>
 *    Returns the first element of the given list.
 *  </li>
 *  <li>
 *    MYTYPE* MyType_Tree_Next(const MYTYPE *element);<br>
 *    Returns the next list element to the given one (the
 *    successor) in its list.
 *  </li>
 *  <li>
 *    MYTYPE* MyType_Tree_Previous(const MYTYPE *element);<br>
 *    Returns the previous list element to the given one (the
 *    predecessor) in its list.
 *  </li>
 *  <li>
 *    void MyType_Tree_Clear(MYTYPE *element); <br>
 *    Frees all entries of the given list.
 *    This function assumes that there is a function Mytype_free().
 *  </li>
 *  <li>
 *    MYTYPE_TREE *MyType_Tree_new(); <br>
 *    Creates a new list of elements of MYTYPE type.
 *  </li>
 *  <li>
 *    void MyType_Tree_free(MYTYPE_TREE *l); <br>
 *    Clears and frees a list of elements of MYTYPE type.
 *    All objects inside the list are freed.
 *  </li>
 * </ul>
 *
 */
#define GWEN_TREE_FUNCTION_LIB_DEFS(t, pr, decl) \
  GWEN_TREE_FUNCTION_LIB_DEFS_CONST(t, pr, decl) \
  GWEN_TREE_FUNCTION_LIB_DEFS_NOCONST(t, pr, decl)


/**
 * This macro should be used in applications, not in libraries. In
 * libraries please use the macro @ref GWEN_TREE_FUNCTION_LIB_DEFS.
 */
#define GWEN_TREE_FUNCTION_DEFS(t, pr) \
  GWEN_TREE_FUNCTION_LIB_DEFS(t, pr, GWEN_DUMMY_EMPTY_ARG)


  /**
   * Use this inside your code files (*.c).
   * Actually implements the functions for which the prototypes have been
   * defined via @ref GWEN_TREE_FUNCTION_DEFS.
   */
#define GWEN_TREE_FUNCTIONS(t, pr) \
  \
  void pr##_Tree_Add(t##_TREE *l, t *element) { \
    assert(element); \
    assert(element->_tree_element);\
    GWEN_Tree_Add(l, element->_tree_element); \
  } \
  \
  void pr##_Tree_AddList(t##_TREE *dst, t##_TREE *l) { \
    GWEN_Tree_AddList(dst, l); \
  } \
  \
  void pr##_Tree_Insert(t##_TREE *l, t *element) { \
    assert(element); \
    assert(element->_tree_element);\
    GWEN_Tree_Insert(l, element->_tree_element); \
  } \
  \
  void pr##_Tree_Del(t *element){ \
    assert(element); \
    assert(element->_tree_element);\
    GWEN_Tree_Del(element->_tree_element); \
  }\
  \
  t* pr##_Tree_GetFirst(const t##_TREE *l) { \
    if (l) return (t*)GWEN_Tree_GetFirst(l);\
    else return 0; \
  } \
  \
  t* pr##_Tree_GetLast(const t##_TREE *l) { \
    if (l) return (t*) GWEN_Tree_GetLast(l);\
    else return 0; \
  } \
  \
  void pr##_Tree_Clear(t##_TREE *l) { \
    t* el; \
    while( (el=GWEN_Tree_GetFirst(l)) ) {\
      pr##_Tree_Del(el);\
      pr##_Tree_ClearChildren(el); \
      pr##_free(el);\
    } /* while */ \
  } \
  \
  int pr##_Tree_HasElement(const t##_TREE *l, const t *element) { \
    const t* el; \
    el=(t*)GWEN_Tree_GetFirst(l); \
    while(el) {\
      if (el==element) \
        return 1; \
      el=(const t*)GWEN_TreeElement_GetBelow(el->_tree_element); \
    } /* while */ \
    return 0; \
  } \
  \
  t##_TREE* pr##_Tree_new(){\
    return (t##_TREE*)GWEN_Tree_new(); \
  }\
  \
  void pr##_Tree_free(t##_TREE *l) {\
    if (l) { \
      pr##_Tree_Clear(l);\
      GWEN_Tree_free(l); \
    }\
  } \
  \
  t* pr##_Tree_GetNext(const t *element) { \
    assert(element); \
    assert(element->_tree_element);\
    return (t*)GWEN_TreeElement_GetNext(element->_tree_element);\
  } \
  \
  t* pr##_Tree_GetPrevious(const t *element) { \
    assert(element); \
    assert(element->_tree_element);\
    return (t*)GWEN_TreeElement_GetPrevious(element->_tree_element);\
  } \
  \
  t* pr##_Tree_GetBelow(const t *element) { \
    assert(element); \
    assert(element->_tree_element);\
    return (t*)GWEN_TreeElement_GetBelow(element->_tree_element);\
  } \
  \
  uint32_t pr##_Tree_GetCount(const t##_TREE *l){\
    return GWEN_Tree_GetCount(l);\
  } \
  \
  int pr##_Tree_HasChildElement(const t *who, const t *element) { \
    const t* el; \
    el=(const t*)GWEN_TreeElement_GetFirstChild(who->_tree_element); \
    while(el) {\
      if (el==element) \
        return 1; \
      el=(const t*)GWEN_TreeElement_GetNext(el->_tree_element); \
    } /* while */ \
    return 0; \
  } \
  \
  void pr##_Tree_AddChild(t *where, t *element) { \
    assert(where); \
    assert(where->_tree_element);\
    assert(element); \
    assert(element->_tree_element);\
    GWEN_Tree_AddChild(where->_tree_element, element->_tree_element); \
  } \
  \
  void pr##_Tree_InsertChild(t *where, t *element) { \
    assert(where); \
    assert(where->_tree_element);\
    assert(element); \
    assert(element->_tree_element);\
    GWEN_Tree_InsertChild(where->_tree_element, element->_tree_element); \
  } \
  \
  void pr##_Tree_ClearChildren(t *element) { \
    t* c; \
    while( (c=GWEN_TreeElement_GetFirstChild(element->_tree_element)) ) {\
      pr##_Tree_ClearChildren(c);\
      pr##_Tree_Del(c);\
      pr##_free(c);\
    } /* while */ \
  } \
  \
  t* pr##_Tree_GetFirstChild(const t *element) { \
    assert(element); \
    assert(element->_tree_element);\
    return (t*)GWEN_TreeElement_GetFirstChild(element->_tree_element);\
  } \
  \
  t* pr##_Tree_GetLastChild(const t *element) { \
    assert(element); \
    assert(element->_tree_element);\
    return (t*)GWEN_TreeElement_GetLastChild(element->_tree_element);\
  } \
  \
  uint32_t pr##_Tree_GetChildrenCount(const t *element){\
    return GWEN_TreeElement_GetChildrenCount(element->_tree_element);\
  } \
  \
  t* pr##_Tree_GetParent(const t *element) { \
    assert(element); \
    assert(element->_tree_element);\
    return (t*)GWEN_TreeElement_GetParent(element->_tree_element);\
  } \
  \


/**
 * Use this in your code file (*.c) inside the init code for the struct
 * you want to use in lists (in GWEN these are the functions which end with
 * "_new".
 */
#define GWEN_TREE_INIT(t, element) \
  element->_tree_element=GWEN_TreeElement_new(element);


/**
 * Use this in your code file (*.c) inside the fini code for the struct
 * you want to use in lists (in GWEN these are the functions which end with
 * "_free".
 */
#define GWEN_TREE_FINI(t, element) \
  if (element && element->_tree_element) { \
    GWEN_TreeElement_free(element->_tree_element); \
    element->_tree_element=0; \
  }

/*@}*/

/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif


#endif


