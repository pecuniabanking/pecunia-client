/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_MSGENGINE_H
#define AQBANKING_MSGENGINE_H

#include <aqbanking/error.h> /* for AQBANKING_API */
#include <gwenhywfar/msgengine.h>

#ifdef __cplusplus
extern "C" {
#endif


/**
 * @file aqbanking/msgengine.h
 *
 * This message engine implements a few new types:
 * <ul>
 *   <li>byte</li>
 *   <li>word (bigEndian="1")</li>
 *   <li>dword (bigEndian="1")</li>
 *   <li>bytes (size="-1") </li>
 *   <li>tlv (tlvType="BER"||"SIMPLE") </li>
 * </ul>
 */

AQBANKING_API
GWEN_MSGENGINE *AB_MsgEngine_new();


#ifdef __cplusplus
}
#endif


#endif /* AQBANKING_MSGENGINE_H */


