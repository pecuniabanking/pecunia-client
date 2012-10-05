/***************************************************************************
    begin       : Fri Jan 22 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef CPPDIALOG_HPP
#define CPPDIALOG_HPP

#include <gwenhywfar/dialog_be.h>

#include <list>
#include <string>

class CppDialog;


/**
 * @brief A C++ binding for the C module @ref GWEN_DIALOG
 *
 * This class simply is a C++ binding for the C module @ref GWEN_DIALOG.
 * It redirects C callbacks used by GWEN_DIALOG to virtual functions in
 * this class.
 *
 * @author Martin Preuss<martin@aquamaniac.de>
 */
class CppDialog {
  friend class CppDialogLinker;

private:
  GWEN_DIALOG_SETINTPROPERTY_FN _setIntPropertyFn;
  GWEN_DIALOG_GETINTPROPERTY_FN _getIntPropertyFn;
  GWEN_DIALOG_SETCHARPROPERTY_FN _setCharPropertyFn;
  GWEN_DIALOG_GETCHARPROPERTY_FN _getCharPropertyFn;

public:
  CppDialog(GWEN_DIALOG *dlg);
  virtual ~CppDialog();

  GWEN_DIALOG *getCInterface();

  static CppDialog *getDialog(GWEN_DIALOG *dlg);

protected:
  GWEN_DIALOG *_dialog;

  CppDialog();

  int emitSignal(GWEN_DIALOG_EVENTTYPE t, const char *sender);

  GWEN_WIDGET_TREE *getWidgets() const;

  GWEN_WIDGET *findWidgetByName(const char *name);

  GWEN_WIDGET *findWidgetByImplData(int index, void *ptr);


  virtual int setIntProperty(GWEN_WIDGET *w,
			     GWEN_DIALOG_PROPERTY prop,
			     int index,
			     int value,
			     int doSignal);

  virtual int getIntProperty(GWEN_WIDGET *w,
			     GWEN_DIALOG_PROPERTY prop,
			     int index,
			     int defaultValue);

  virtual int setCharProperty(GWEN_WIDGET *w,
			      GWEN_DIALOG_PROPERTY prop,
			      int index,
			      const char *value,
			      int doSignal);

  virtual const char *getCharProperty(GWEN_WIDGET *w,
				      GWEN_DIALOG_PROPERTY prop,
				      int index,
				      const char *defaultValue);

};




#endif /* CPPDIALOG_HPP */


