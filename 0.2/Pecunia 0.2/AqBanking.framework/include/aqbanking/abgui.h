/***************************************************************************
 begin       : Thu Jun 18 2009
 copyright   : (C) 2009 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_GUI_H
#define AQBANKING_GUI_H


#include <gwenhywfar/gui_be.h>
#include <aqbanking/banking.h>


/** @addtogroup G_AB_GUI Gwenhywfar GUI Extension
 *
 * @brief Extends the GWEN_GUI framework.
 *
 * This module adds the following features to GWEN_GUI:
 * <ul>
 *   <li>maintenance of SSL certificates</li>
 *   <li>reading and writing of GWEN_DIALOG settings (allows storing the settings of every
 *       dialog in AqBanking's shared settings database)</li>
 * </ul>
 *
 *
 * The following example shows how to use this module correctly. We use the FOX implementation
 * of the GWEN_GUI framework here, but the basic steps are the same for every implementation.
 * <ol>
 *   <li>GWEN_Init()</li>
 *   <li>basic setup of your application</li>
 *   <li>create a GUI, set it as the application's GUI (GWEN_Gui_SetGui())</li>
 *   <li>create the AqBanking object (AB_Banking_new())</li>
 *   <li>init the AqBanking object (just AB_Banking_Init(), no need for AB_Banking_Online_Init() here)</li>
 *   <li>call @ref AB_Gui_Extend() to extend the GUI (regardless of the heritage if the GUI, this works
 *       with every GUI implementation, even on console)</li>
 * </ol>
 *
 * @code
 *
 * FF_App app("AqFinance", "Martin Preuss");
 * AB_BANKING *ab;
 * FF_Gui *gui;
 *
 * GWEN_Init();
 *
 * app.init(argc, argv);
 *
 * gui=new FF_Gui(&app, "/some/where");
 * GWEN_Gui_SetGui(gui->getCInterface());
 *
 * ab=AB_Banking_new("MyApplication", NULL, 0);
 * AB_Banking_Init(ab);
 *
 * AB_Gui_Extend(gui->getCInterface(), ab);
 *
 * @endcode
 */
/*@{*/



#ifdef __cplusplus
extern "C" {
#endif


/**
 * This function creates a GWEN_GUI object which uses AqBanking's shared certificate data
 * for certificate checking.
 * AB_Banking_Init() must be called before the certificate check callback of this GWEN_GUI
 * object is called.
 */
AQBANKING_API GWEN_GUI *AB_Gui_new(AB_BANKING *ab);

/**
 * This function can be used to add certificate handling using AqBanking's shared certificate
 * data to any GWEN_GUI object.
 * It sets the callback for certificate checking.
 * Use this function if you have your own GWEN_GUI implementation but still want to use AqBanking's
 * certificate handling.
 * AB_Banking_Init() must be called before the certificate check callback of this GWEN_GUI
 * object is called.
 */
AQBANKING_API void AB_Gui_Extend(GWEN_GUI *gui, AB_BANKING *ab);

/**
 * This function unlinks the given GWEN_GUI object from AqBanking.
 * It resets the callback for certificate checking to the value it had before
 * @ref AB_Gui_Extend was called.
 */
AQBANKING_API void AB_Gui_Unextend(GWEN_GUI *gui);


#ifdef __cplusplus
}
#endif


/*@}*/   /* end of group G_AB_GUI */


#endif


