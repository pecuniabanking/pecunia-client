/***************************************************************************
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef GWEN_GUI_FOX16_API_H
#define GWEN_GUI_FOX16_API_H



#if defined __GNUC__ && (! defined (__sun)) && (__GNUC__ >= 4 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 3))
# ifdef BUILDING_FOX16_GUI
#   define FOX16GUI_API __attribute__ ((visibility("default")))
# else
#   define FOX16GUI_API
# endif
#else
# define FOX16GUI_API
#endif


#endif

