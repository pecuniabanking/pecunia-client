/***************************************************************************
    begin       : Tue Jul 13 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef CPPWIDGET_HPP
#define CPPWIDGET_HPP

#include <gwenhywfar/dialog_be.h>
#include <list>
#include <string>

class CppWidget;
class CppDialog;


/**
 * @brief A C++ binding for the C module @ref GWEN_WIDGET
 *
 * This class simply is a C++ binding for the C module @ref GWEN_WIDGET.
 * It redirects C callbacks used by GWEN_WIDGET to virtual functions in
 * this class.
 *
 * @author Martin Preuss<martin@aquamaniac.de>
 */
class CppWidget {
  friend class CppWidgetLinker;

private:
  GWEN_WIDGET_SETINTPROPERTY_FN _setIntPropertyFn;
  GWEN_WIDGET_GETINTPROPERTY_FN _getIntPropertyFn;
  GWEN_WIDGET_SETCHARPROPERTY_FN _setCharPropertyFn;
  GWEN_WIDGET_GETCHARPROPERTY_FN _getCharPropertyFn;
  GWEN_WIDGET_ADDCHILDGUIWIDGET_FN _addChildGuiWidgetFn;

public:
  CppWidget(GWEN_WIDGET *w);
  virtual ~CppWidget();

  GWEN_WIDGET *getCInterface();
  static CppWidget *getWidget(GWEN_WIDGET *w);

  CppDialog *getDialog();

  const char *getName();
  GWEN_WIDGET_TYPE getType();
  int getColumns();
  int getRows();
  uint32_t getFlags();

  int getGroupId();
  int getWidth();
  int getHeight();
  const char *getText(int idx);
  const char *getIconFileName();
  const char *getImageFileName();


protected:
  GWEN_WIDGET *_widget;

  CppWidget();

  virtual int setIntProperty(GWEN_DIALOG_PROPERTY prop,
			     int index,
			     int value,
			     int doSignal);

  virtual int getIntProperty(GWEN_DIALOG_PROPERTY prop,
			     int index,
			     int defaultValue);

  virtual int setCharProperty(GWEN_DIALOG_PROPERTY prop,
			      int index,
			      const char *value,
			      int doSignal);

  virtual const char *getCharProperty(GWEN_DIALOG_PROPERTY prop,
				      int index,
				      const char *defaultValue);

  virtual int addChildGuiWidget(GWEN_WIDGET *wChild);

};




#endif /* CPPWIDGET_HPP */


