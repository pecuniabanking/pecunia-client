/***************************************************************************
 begin       : Wed Feb 27 2008
 copyright   : (C) 2008 by Martin Preuss
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

#ifndef GWENHYWFAR_XSDNODE_H
#define GWENHYWFAR_XSDNODE_H


typedef struct GWEN_XSD_NODE GWEN_XSD_NODE;

#include <gwenhywfar/inherit.h>
#include <gwenhywfar/list1.h>

GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_XSD_NODE, GWENHYWFAR_API)
GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_XSD_NODE, GWEN_XsdNode, GWENHYWFAR_API)


#include <gwenhywfar/xml.h>
#include <gwenhywfar/db.h>


typedef enum {
  GWEN_Xsd_NodeType_Unknown=0,
  GWEN_Xsd_NodeType_Any,
  GWEN_Xsd_NodeType_Element,
  GWEN_Xsd_NodeType_Attribute,
  GWEN_Xsd_NodeType_ComplexType,
  GWEN_Xsd_NodeType_SimpleType,
  GWEN_Xsd_NodeType_Group,
  GWEN_Xsd_NodeType_AttributeGroup,
  GWEN_Xsd_NodeType_Facet
} GWEN_XSD_NODETYPE;



GWEN_XSD_NODE *GWEN_XsdNode_new(GWEN_XSD_NODE *parent,
				GWEN_XSD_NODETYPE t,
				const char *name);
void GWEN_XsdNode_free(GWEN_XSD_NODE *xsdNode);


GWEN_XSD_NODETYPE GWEN_XsdNode_GetNodeType(const GWEN_XSD_NODE *xsdNode);
const char *GWEN_XsdNode_GetName(const GWEN_XSD_NODE *xsdNode);


GWEN_XSD_NODE *GWEN_XsdNode_GetParent(const GWEN_XSD_NODE *xsdNode);
GWEN_XSD_NODE_LIST *GWEN_XsdNode_GetChildren(const GWEN_XSD_NODE *xsdNode);
void GWEN_XsdNode_AddChild(GWEN_XSD_NODE *xsdNode, GWEN_XSD_NODE *newChild);
void GWEN_XsdNode_Unlink(GWEN_XSD_NODE *xsdNode);

uint32_t GWEN_XsdNode_GetFlags(const GWEN_XSD_NODE *xsdNode);
void GWEN_XsdNode_SetFlags(GWEN_XSD_NODE *xsdNode, uint32_t fl);
void GWEN_XsdNode_AddFlags(GWEN_XSD_NODE *xsdNode, uint32_t fl);
void GWEN_XsdNode_SubFlags(GWEN_XSD_NODE *xsdNode, uint32_t fl);


int GWEN_XsdNode_Read(GWEN_XSD_NODE *xsdNode,
		      GWEN_XMLNODE *xmlNode,
		      GWEN_DB_NODE *db);

int GWEN_XsdNode_Write(GWEN_XSD_NODE *xsdNode,
		       GWEN_XMLNODE *xmlNode,
		       GWEN_DB_NODE *db);



#endif

