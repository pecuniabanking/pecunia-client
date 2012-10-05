/***************************************************************************
 begin       : Sat Jun 28 2003
 copyright   : (C) 2003-2010 by Martin Preuss
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

#ifndef GWENHYWFAR_XML_H
#define GWENHYWFAR_XML_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/stringlist.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/list2.h>
#include <gwenhywfar/syncio.h>

#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup MOD_XMLNODE_ALL XML Tree
 * @ingroup MOD_PARSER
 *
 */
/*@{*/

/** @defgroup MOD_XMLNODE XML Node
 *
 */
/*@{*/


/** @name Read Flags
 */
/*@{*/

/**
 * if set then comments are read. Otherwise they are ignored when reading
 * a file */
#define GWEN_XML_FLAGS_HANDLE_COMMENTS      0x0001

/**
 * Indent lines according to node level when writing nodes. This increases
 * the readability of the resulting file.
 */
#define GWEN_XML_FLAGS_INDENT               0x0002

/**
 * Let the parser accept some HTML which are known to be unclosed (e.g.
 * the tag "BR" in HTML tags is never closed).
 * If not set a "BR" tag without a corresponding "/BR" will produce an error.
 */
#define GWEN_XML_FLAGS_HANDLE_OPEN_HTMLTAGS 0x0004

/**
 * If set then data will not be condensed (e.g. multiple spaces will not
 * be replaced by a single one).
 */
#define GWEN_XML_FLAGS_NO_CONDENSE          0x0008

/**
 * If set then control characters (such as CR, LF) will not be removed from
 * data.
 */
#define GWEN_XML_FLAGS_KEEP_CNTRL           0x0010

#define GWEN_XML_FLAGS_KEEP_BLANKS          0x0020

#define GWEN_XML_FLAGS_SIMPLE               0x0040

/**
 * apply special treatment to toplevel header tags (such as &lt;?xml&gt;)
 */
#define GWEN_XML_FLAGS_HANDLE_HEADERS       0x0080

/**
 * If this flag is given this module will be more tolerant when encountering
 * and end element (e.g. &lt;/html&gt;). If the name of the end element does
 * not match the currently open element then the element to be closed is
 * searched above the currently open element. This works around problems
 * with malformed XML files.
 */
#define GWEN_XML_FLAGS_TOLERANT_ENDTAGS     0x0100

#define GWEN_XML_FLAGS_HANDLE_NAMESPACES    0x0200

/**
 * combination of other flags resembling the default flags
 */
#define GWEN_XML_FLAGS_DEFAULT \
  (\
  GWEN_XML_FLAGS_INDENT | \
  GWEN_XML_FLAGS_HANDLE_COMMENTS\
  )

/*@}*/

/**
 * The possible types of a GWEN_XMLNODE.
 */
typedef enum {
  /** A node can be a tag (in XML notation these are called
      elements). */
  GWEN_XMLNodeTypeTag=0,
  /** A node can be some data. */
  GWEN_XMLNodeTypeData,
  /** A node can be some XML comment. */
  GWEN_XMLNodeTypeComment
} GWEN_XMLNODE_TYPE;

/** The abstract type XMLNODE. Each node is one node in the document
 * tree and can represent different things, see @ref
 * GWEN_XMLNODE_TYPE. */
typedef struct GWEN__XMLNODE GWEN_XMLNODE;
typedef struct GWEN_XMLNODE_NAMESPACE GWEN_XMLNODE_NAMESPACE;

GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_XMLNODE, GWEN_XMLNode, GWENHYWFAR_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_XMLNODE, GWEN_XMLNode, GWENHYWFAR_API)

GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_XMLNODE_NAMESPACE, GWEN_XMLNode_NameSpace, GWENHYWFAR_API)

#ifdef __cplusplus
}
#endif


#include <gwenhywfar/xmlctx.h>
#include <gwenhywfar/fastbuffer.h>


#ifdef __cplusplus
extern "C" {
#endif



/** @name Constructors and Destructors
 *
 */
/*@{*/
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_new(GWEN_XMLNODE_TYPE t, const char *data);

/**
 * Free the given node (including its children nodes)
 */
GWENHYWFAR_API
void GWEN_XMLNode_free(GWEN_XMLNODE *n);

/**
 * Free the given node and all nodes besides this one.
 * Hmm, this function should not be public, I think I will move it
 * to xml_p.h.
 */
GWENHYWFAR_API
void GWEN_XMLNode_freeAll(GWEN_XMLNODE *n);

/**
 * Create and return a deep copy of the given node.
 */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_dup(const GWEN_XMLNODE *n);

/*@}*/


/** @name Managing Headers
 *
 * <p>
 * Headers are special tags in XML files which describe the document (such as
 * &lt;?xml?&gt; or &lt;!DOCTYPE&gt;).
 * </p>
 * <p>
 * If the flag @ref GWEN_XML_FLAGS_HANDLE_HEADERS is on upon reading of
 * files these special toplevel tags are added to the current node's header
 * list instead of the normal children node list.
 * </p>
 * <p>
 * If the same flag is given when writing files the header tags of the given
 * root node are written to the output stream before its children.
 * </p>
 * <p>
 * Header nodes are identified as nodes whose name begins with '?' or '!'.
 * </p>
 */
/*@{*/

/**
 * Returns the first header tag of the given node.
 * Use @ref GWEN_XMLNode_Next to get the next header tag.
 */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_GetHeader(const GWEN_XMLNODE *n);

/**
 * Adds a node as a header to the given root node.
 */
GWENHYWFAR_API
void GWEN_XMLNode_AddHeader(GWEN_XMLNODE *root, GWEN_XMLNODE *nh);

/**
 * Removes a node from the given root nodes' header list. The header node is
 * just removed from the list, not freed !
 */
GWENHYWFAR_API
void GWEN_XMLNode_DelHeader(GWEN_XMLNODE *root, GWEN_XMLNODE *nh);

/**
 * Clears the given root nodes' list of headers. All the tags in the header
 * list are also freed.
 */
GWENHYWFAR_API
void GWEN_XMLNode_ClearHeaders(GWEN_XMLNODE *root);

/*@}*/


/** @name Managing Properties/Attributes
 *
 * A property (in XML notation this is called attribute) is given
 * within a tag (in XML notation this is called element), like in this
 * example:
 *
 * @code
 * <tag property="1" />
 * @endcode
 */
/*@{*/
/**
 * Returns the value of the given property/attribute (or the default
 * value if the property/attribute does not exist or is empty).
 *
 * @param n node (must be a tag/element)
 * @param name name of the property/attribute
 * @param defaultValue default value to be returned if no value could
 * be retrieved
 */
GWENHYWFAR_API
  const char *GWEN_XMLNode_GetProperty(const GWEN_XMLNODE *n,
                                       const char *name,
                                       const char *defaultValue);

/**
 * Sets the value of a property/attribute. This property/attribute will be created if it does not
 * exist and overwritten if it does.
 * @param n node (must be a tag/element)
 * @param name name of the property/attribute
 * @param value new value of the property/attribute
 */
GWENHYWFAR_API
  void GWEN_XMLNode_SetProperty(GWEN_XMLNODE *n,
                                const char *name,
                                const char *value);

/**
 * This function copies the properties/attributes of one tag/element
 * to another one.
 *
 * @param tn destination node (must be a tag/element)
 * @param sn source node (must be a tag/element)
 * @param overwrite if !=0 then existing properties/attributes in the
 * destination node will be overwritten.
 */
GWENHYWFAR_API
  void GWEN_XMLNode_CopyProperties(GWEN_XMLNODE *tn,
                                   const GWEN_XMLNODE *sn,
                                   int overwrite);
/*@}*/

/** @name Type And Data
 *
 */
/*@{*/
/** Returns the type of the given node. */
GWENHYWFAR_API
GWEN_XMLNODE_TYPE GWEN_XMLNode_GetType(const GWEN_XMLNODE *n);

/** Returns the character data of the given node. */
GWENHYWFAR_API
const char *GWEN_XMLNode_GetData(const GWEN_XMLNODE *n);

/** Set the character data of the given node to the given value. This
 * function will create a deep copy of the character data. */
GWENHYWFAR_API
void GWEN_XMLNode_SetData(GWEN_XMLNODE *n, const char *data);

GWENHYWFAR_API
const char *GWEN_XMLNode_GetNamespace(const GWEN_XMLNODE *n);

GWENHYWFAR_API
void GWEN_XMLNode_SetNamespace(GWEN_XMLNODE *n, const char *s);

/*@}*/


/** @name Usage Counter
 *
 * <p>
 * The usage counter of a node is only used by applications, not by
 * Gwenhywfar itself. So if the application does not set this
 * counter it will always be zero.
 * </p>
 * <p>
 * An application could use this counter to check whether a given node
 * is still in use by some parts of the application in order to free
 * unused nodes.
 * </p>
 */
/*@{*/
GWENHYWFAR_API
  void GWEN_XMLNode_IncUsage(GWEN_XMLNODE *n);

GWENHYWFAR_API
  void GWEN_XMLNode_DecUsage(GWEN_XMLNODE *n);

GWENHYWFAR_API
  uint32_t GWEN_XMLNode_GetUsage(const GWEN_XMLNODE *n);
/*@}*/


/** @name Iterating Through an XML Tree
 *
 */
/*@{*/
/** INTERNAL. Iterates on the same level in the XML tree from the
 * given node to the next one on the same level (i.e. the returned
 * node has the same parent node as the given element). The returned
 * node may be a tag/element node, or a property/attribute node, or a
 * data node. You will probably prefer to use
 * GWEN_XMLNode_GetNextTag() instead of this function.
 *
 * @return The next node on the same level, or NULL if no more element
 * exists. */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_Next(const GWEN_XMLNODE *n);

/** INTERNAL. Descends in the XML tree to the first GWEN_XMLNODE below
 * the given node. The returned node may be a tag/element node, or a
 * property/attribute node, or a data node. You will probably prefer
 * to use GWEN_XMLNode_GetFirstTag() instead of this function.
 *
 * @return The first children tag/element, or NULL if none exists.
 */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_GetChild(const GWEN_XMLNODE *n);

/** Returns the parent node of the given node, or NULL if it already
 * is the root node. */
GWENHYWFAR_API
  GWEN_XMLNODE *GWEN_XMLNode_GetParent(const GWEN_XMLNODE *n);

/** Descends in the XML tree to the first children tag (in XML
 * notation they are called elements) below the given node.
 *
 * Different from GWEN_XMLNode_GetChild() this function only looks for
 * another tag/element and not for a (more general) node. You will
 * probably prefer this function instead of GWEN_XMLNode_GetChild().
 *
 * @return The first children tag/element, or NULL if none exists. */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_GetFirstTag(const GWEN_XMLNODE *n);

/** Iterates on the same level in the XML tree from the given tag (in
 * XML notation they are called elements) to the next one on the same
 * level (i.e. the returned element has the same parent node as the
 * given element).
 *
 * Different from GWEN_XMLNode_Next() this function only looks for
 * another tag/element and not for a (more general) node. You will
 * probably prefer this function instead of GWEN_XMLNode_Next().
 *
 * @return The next tag/element on the same level, or NULL if no more
 * element exists. */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_GetNextTag(const GWEN_XMLNODE *n);

/** Descends in the XML tree to the first children data node below the
 * given node. 
 *
 * Different from GWEN_XMLNode_GetChild() this function only looks for
 * another data node and not for a (more general) node. 
 *
 * @return The first children data node, or NULL if none exists. */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_GetFirstData(const GWEN_XMLNODE *n);

/** Iterates on the same level in the XML tree from the given data
 * node to the next one on the same level (i.e. the returned element
 * has the same parent node as the given element). An XML element may
 * have multiple data nodes as children, and you use this function to
 * iterate through all of them.
 *
 * Different from GWEN_XMLNode_Next() this function only looks for
 * another data node  and not for a (more general) node.
 *
 * @return The next data node on the same level, or NULL if no more
 * data node exists. */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_GetNextData(const GWEN_XMLNODE *n);

/**
 * Searches for the first matching tag/element below the given one.
 * Lets say you have the following XML file:
 * @code
 *  <DEVICES>
 *    <DEVICE id="dev1" />
 *    <DEVICE id="dev2" />
 *  </DEVICES>
 * @endcode
 * If you are looking for a device called "dev2" then you should call this
 * function like this:
 * @code
 *   tag=GWEN_XMLNode_FindFirstTag(root, "DEVICE", "id", "dev2");
 * @endcode
 * @return pointer to the tag/element if found, 0 otherwise
 * @param n tag/element below which to search
 * @param tname tag/element name (e.g. if the tag is "<TESTTAG>" then the
 * tag name is "TESTTAG"). Wildcards (like "*") are allowed.
 *
 * @param pname name of the property/attribute to check (if 0 then no
 * property/attribute comparison takes place). No wildcards allowed.
 *
 * @param pvalue optional value of the property/attribute to compare
 * against, wildcards allowed.
 */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_FindFirstTag(const GWEN_XMLNODE *n,
                                        const char *tname,
                                        const char *pname,
                                        const char *pvalue);

/**
 * Searches for the next matching tag/element after the given one one
 * the same level (i.e. the returned element has the same parent node
 * as the given element).
 */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_FindNextTag(const GWEN_XMLNODE *n,
                                       const char *tname,
                                       const char *pname,
                                       const char *pvalue);

/**
 * Checks whether the second node is a child of the first one.
 * @return 0 if statement is not true, !=0 otherwise
 */
GWENHYWFAR_API
int GWEN_XMLNode_IsChildOf(const GWEN_XMLNODE *parent,
                           const GWEN_XMLNODE *child);

GWENHYWFAR_API
int GWEN_XMLNode_GetXPath(const GWEN_XMLNODE *n1,
                          const GWEN_XMLNODE *n2,
                          GWEN_BUFFER *nbuf);

/**
 * Locates a tag by its XPath. Currently attributes are not allowed, and
 * the flag @ref GWEN_PATH_FLAGS_VARIABLE is not supported.
 * Supported types of XPaths are:
 * <ul>
 *   <li>/element[1]/element[2]</li>
 *   <li>../../element[5]</li>
 * </ul>
 * and so on. As you can see index numbers are supported.
 * You should not use this function to create a node but rather for node
 * lookups.
 */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_GetNodeByXPath(GWEN_XMLNODE *n,
                                          const char *path,
                                          uint32_t flags);


/*@}*/


/** @name Managing Nodes
 *
 */
/*@{*/

/**
 * Adds a node as a child to another one. This function does not make deep
 * copies. Instead it takes over ownership of the new child.
 * @param n node to which the new node is to be added (i.e. the node which
 * becomes the parent of the second argument)
 * @param child child which is to be added (this function takes over ownership
 * of that node, so you MUST NOT free the node yourself)
 */
GWENHYWFAR_API
  void GWEN_XMLNode_AddChild(GWEN_XMLNODE *n, GWEN_XMLNODE *child);

/**
 * Unlinks the given child node from its parent without freeing it.
 * This function relinquishes the ownership of the child to the caller who
 * thereby becomes responsible for freeing this node.
 * @param n node which is suspected to be the parent of the second argument
 * @param child node which is to be unlinked
 */
GWENHYWFAR_API
  void GWEN_XMLNode_UnlinkChild(GWEN_XMLNODE *n, GWEN_XMLNODE *child);

/**
 * Unlinks and frees @b all children of the given node.
 */
GWENHYWFAR_API
  void GWEN_XMLNode_RemoveChildren(GWEN_XMLNODE *n);

/**
 * Adds the children of the second argument as new children to the first
 * one.
 * @param n node which is to become parent of the second argument's children
 * @param nn node whose children are to be moved.
 * @param copythem if 0 then the children will be moved (leaving the node of
 * the second argument without children), otherwise deep copies will be made
 * and the node from the second argument will not be altered.
 * co
 */
GWENHYWFAR_API
  void GWEN_XMLNode_AddChildrenOnly(GWEN_XMLNODE *n, GWEN_XMLNODE *nn,
                                    int copythem);

/**
 * This is a very primitive function. It looks for a node of the given type
 * and data matching the given one (case-insensitive) @b below the given node
 * (i.e. if a node is returned it will be a child of the given one).
 */
GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_FindNode(const GWEN_XMLNODE *n,
                                    GWEN_XMLNODE_TYPE t,
                                    const char *data);
/*@}*/


/** @name Reading And Writing From/To Streams
 *
 */
/*@{*/

/**
 * This function removes unnecessary namespaces from the given node and
 * all nodes below.
 */
GWENHYWFAR_API
int GWEN_XMLNode_NormalizeNameSpaces(GWEN_XMLNODE *n);



GWENHYWFAR_API
int GWEN_XMLNode_StripNamespaces(GWEN_XMLNODE *n);


GWENHYWFAR_API
int GWEN_XMLNode_Globalize(GWEN_XMLNODE *n);


GWENHYWFAR_API
int GWEN_XMLNode_GlobalizeWithList(GWEN_XMLNODE *n,
				   GWEN_XMLNODE_NAMESPACE_LIST *l,
				   uint32_t *pLastId);


GWENHYWFAR_API
int GWEN_XML_ReadFromFastBuffer(GWEN_XML_CONTEXT *ctx, GWEN_FAST_BUFFER *fb);

/**
 * Reads a single element (and all its sub-elements) from an IO layer.
 */
GWENHYWFAR_API
int GWEN_XMLContext_ReadFromIo(GWEN_XML_CONTEXT *ctx, GWEN_SYNCIO *io);

GWENHYWFAR_API
int GWEN_XMLContext_ReadFromFile(GWEN_XML_CONTEXT *ctx, const char *fname);

GWENHYWFAR_API
int GWEN_XMLContext_ReadFromString(GWEN_XML_CONTEXT *ctx, const char *text);


/**
 * Reads all tags/elements from a file and adds them as children to
 * the given node.
 */
GWENHYWFAR_API
int GWEN_XML_ReadFile(GWEN_XMLNODE *n, const char *filepath, uint32_t flags);

GWENHYWFAR_API
GWEN_XMLNODE *GWEN_XMLNode_fromString(const char *s,
				      int len,
				      uint32_t flags);

/**
 * Writes a tag and all its subnodes to the given io layer.
 */
GWENHYWFAR_API
int GWEN_XMLNode_WriteToStream(const GWEN_XMLNODE *n,
			       GWEN_XML_CONTEXT *ctx,
			       GWEN_SYNCIO *sio);

/**
 * Writes a tag and all its subnodes to the given file.
 */
GWENHYWFAR_API
int GWEN_XMLNode_WriteFile(const GWEN_XMLNODE *n,
                           const char *fname,
                           uint32_t flags);

GWENHYWFAR_API
int GWEN_XMLNode_toBuffer(const GWEN_XMLNODE *n, GWEN_BUFFER *buf, uint32_t flags);




GWENHYWFAR_API
GWEN_XMLNODE_NAMESPACE_LIST *GWEN_XMLNode_GetNameSpaces(const GWEN_XMLNODE *n);

GWENHYWFAR_API
GWEN_XMLNODE_NAMESPACE *GWEN_XMLNode_FindNameSpaceByName(const GWEN_XMLNODE *n,
							 const char *s);

GWENHYWFAR_API
GWEN_XMLNODE_NAMESPACE *GWEN_XMLNode_FindNameSpaceByUrl(const GWEN_XMLNODE *n,
							const char *s);

GWENHYWFAR_API
void GWEN_XMLNode_AddNameSpace(GWEN_XMLNODE *n, const GWEN_XMLNODE_NAMESPACE *ns);



/*@}*/



/** @name Handling Tags As Variables
 *
 * These functions look for a tag, read their first data element and
 * return it as if it was a DB variable.
 * This simplifies access to simple tags containing simple data tags only.
 * E.g. if your XML structure is this:
 * @code
 * <test>
 *   <X> 15 </X>
 *   <Y> 10 </Y>
 * </test>
 * @endcode
 * ... then you can access the value of X with the following call:
 * @code
 * x=GWEN_XMLNode_GetIntValue(testNode, "X", 0);
 * @endcode
 * If the given variables do not exist or have no value then the also given
 * default value will be returned.
 */
/*@{*/

/**
 * @param n Node which is expected to contain a node of the specified name
 * @param name name of the node below n to be looked up
 * @param defValue default value to return if the tag did not exist
 */
GWENHYWFAR_API
const char *GWEN_XMLNode_GetCharValue(const GWEN_XMLNODE *n,
                                      const char *name,
                                      const char *defValue);

GWENHYWFAR_API
  void GWEN_XMLNode_SetCharValue(GWEN_XMLNODE *n,
                                 const char *name,
                                 const char *value);

/**
 * This function does the same as @ref GWEN_XMLNode_GetCharValue, but it
 * looks for an element with the attribute "lang" which matches the currently
 * selected locale (e.g. "lang=de" for Germany).
 * If there is no localized version of the given element then the first
 * element of that name is used (withouth "lang" attribute).
 * Therefore XML documents used with this function should contain unlocalized
 * elements along with localized ones to provide a fallback.
 * @param n Node which is expected to contain a node of the specified name
 * @param name name of the node below n to be looked up
 * @param defValue default value to return if the tag did not exist
 */
GWENHYWFAR_API
const char *GWEN_XMLNode_GetLocalizedCharValue(const GWEN_XMLNODE *n,
                                               const char *name,
                                               const char *defValue);

/**
 * Internally calls @ref GWEN_XMLNode_GetCharValue and interpretes the
 * data as an integer which is then returned.
 * @param n Node which is expected to contain a node of the specified name
 * @param name name of the node below n to be looked up
 * @param defValue default value to return if the tag did not exist
 */
GWENHYWFAR_API
int GWEN_XMLNode_GetIntValue(const GWEN_XMLNODE *n,
			     const char *name,
			     int defValue);

GWENHYWFAR_API
void GWEN_XMLNode_SetIntValue(GWEN_XMLNODE *n,
                              const char *name,
                              int value);

/*@}*/


/** @name Debugging
 *
 */
/*@{*/

/**
 * Dumps the content of the given XML node and all its children.
 */
GWENHYWFAR_API
void GWEN_XMLNode_Dump(const GWEN_XMLNODE *n, FILE *f, int ind);
/*@}*/

/*@}*/ /* defgroup */


/** @defgroup MOD_XMLNODE_PATH XML Node Path
 *
 * This is used by the message engine module (@ref MOD_MSGENGINE_ALL).
 * A path consists of a list of nodes which are used while decoding/encoding
 * a message. A GWEN_XMLNODE_PATH serves as a LIFO stack (last-in-first-out).
 */
/*@{*/

typedef struct GWEN_XMLNODE_PATH GWEN_XMLNODE_PATH;


GWENHYWFAR_API
GWEN_XMLNODE_PATH *GWEN_XMLNode_Path_new();
GWENHYWFAR_API
GWEN_XMLNODE_PATH *GWEN_XMLNode_Path_dup(const GWEN_XMLNODE_PATH *np);
GWENHYWFAR_API
void GWEN_XMLNode_Path_free(GWEN_XMLNODE_PATH *np);

/**
 * Adds a node to the path.
 */
GWENHYWFAR_API
int GWEN_XMLNode_Path_Dive(GWEN_XMLNODE_PATH *np,
                           GWEN_XMLNODE *n);

/**
 * Removes and returns the last added node (or 0 if that would bring us
 * beyond the root).
 */
GWENHYWFAR_API
  GWEN_XMLNODE *GWEN_XMLNode_Path_Surface(GWEN_XMLNODE_PATH *np);

/**
 * Dumps the contents of all XML nodes in the path.
 */
GWENHYWFAR_API
void GWEN_XMLNode_Path_Dump(GWEN_XMLNODE_PATH *np);
/*@}*/ /* defgroup */
/*@}*/ /* defgroup (all)*/



GWENHYWFAR_API
GWEN_XMLNODE_NAMESPACE *GWEN_XMLNode_NameSpace_new(const char *name,
						   const char *url);

GWENHYWFAR_API
void GWEN_XMLNode_NameSpace_free(GWEN_XMLNODE_NAMESPACE *ns);

GWENHYWFAR_API
GWEN_XMLNODE_NAMESPACE *GWEN_XMLNode_NameSpace_dup(const GWEN_XMLNODE_NAMESPACE *ns);

GWENHYWFAR_API
const char *GWEN_XMLNode_NameSpace_GetName(const GWEN_XMLNODE_NAMESPACE *ns);

GWENHYWFAR_API
const char *GWEN_XMLNode_NameSpace_GetUrl(const GWEN_XMLNODE_NAMESPACE *ns);


#ifdef __cplusplus
}
#endif



#endif
