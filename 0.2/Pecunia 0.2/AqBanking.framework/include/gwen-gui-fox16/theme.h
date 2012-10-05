
/* These widgets have initially been created by Martin Oberzalek who gave them into
 * the public domain via an email to the mailing list foxgui-users on 17th of June, 2010
 * ("here the source. Free to use for alll.").
 * I (Martin Preuss) adapted them to be usable with FOX 1.6 and also added some widgets of
 * my own (for now: ThemeHeaderItem).
 */

#ifndef THEME_H
#define THEME_H

#include <fx.h>

/** This header is only needed for the definition of "FOX16GUI_API" which is
 * used in the declaration of all exported classes and methods.
 * If you want to use these themed widgets in your own projects you should remove
 * this include here and all occurrences of "FOX16GUI_API".
 */
#include <gwen-gui-fox16/fox16_gui.hpp>



#define THEMEBUTTON          ThemeButton
#define THEMETEXTFIELD       ThemeTextField
#define THEMECOMBOBOX        ThemeComboBox
#define THEMELABEL           ThemeLabel
#define THEMEVERTICALFRAME   ThemeVerticalFrame
#define THEMEHORIZONTALFRAME ThemeHorizontalFrame
#define THEMEMENUBUTTON      ThemeMenuButton
#define THEMEHEADERITEM      ThemeHeaderItem
#define THEMETABITEM         ThemeTabItem



class FOX16GUI_API ThemeButton : public FXButton {
  FXDECLARE( ThemeButton );

protected:
  ThemeButton() {}

public:	
  ThemeButton(FXComposite* p,const FXString& text,FXIcon* ic=NULL,
	      FXObject* tgt=NULL,FXSelector sel=0,FXuint opts=BUTTON_NORMAL,
	      FXint x=0,FXint y=0,FXint w=0,FXint h=0,FXint pl=DEFAULT_PAD,
	      FXint pr=DEFAULT_PAD,FXint pt=DEFAULT_PAD,FXint pb=DEFAULT_PAD);

  long onPaint(FXObject*,FXSelector,void* ptr);
};



class FOX16GUI_API ThemeTextField : public FXTextField {
  FXDECLARE( ThemeTextField );

protected:
  ThemeTextField() {}

public:
  ThemeTextField(FXComposite* p,FXint ncols,FXObject* tgt=NULL,FXSelector sel=0,
		 FXuint opts=TEXTFIELD_NORMAL,FXint x=0,FXint y=0,FXint w=0,
		 FXint h=0,FXint pl=DEFAULT_PAD,FXint pr=DEFAULT_PAD,FXint pt=DEFAULT_PAD,FXint pb=DEFAULT_PAD);

  long onPaint(FXObject*,FXSelector,void* ptr);

protected:
  void drawFrame(FXDCWindow& dc,FXint x,FXint y,FXint w,FXint h);
};




FOX16GUI_API void init_theme( FXApp *app );




class FOX16GUI_API ThemeComboBox : public FXComboBox {
  FXDECLARE( ThemeComboBox );

protected:
  ThemeComboBox() {}

public:
  ThemeComboBox(FXComposite *p,FXint cols,FXObject* tgt=NULL,FXSelector sel=0,
		FXuint opts=COMBOBOX_NORMAL,FXint x=0,FXint y=0,FXint w=0,FXint h=0,
		FXint pl=DEFAULT_PAD,FXint pr=DEFAULT_PAD,FXint pt=DEFAULT_PAD,FXint pb=DEFAULT_PAD);

  long onPaint(FXObject*,FXSelector,void* ptr);
};




class FOX16GUI_API ThemeLabel : public FXLabel {
  FXDECLARE( ThemeLabel );

protected:
  ThemeLabel() {}

public:
  ThemeLabel(FXComposite* p,const FXString& text,FXIcon* ic=0,FXuint opts=LABEL_NORMAL,
	     FXint x=0,FXint y=0,FXint w=0,FXint h=0,
	     FXint pl=DEFAULT_PAD,FXint pr=DEFAULT_PAD,FXint pt=DEFAULT_PAD,FXint pb=DEFAULT_PAD);

  long onPaint(FXObject*,FXSelector,void* ptr);
};




class FOX16GUI_API ThemeTabItem : public FXTabItem {
  FXDECLARE( ThemeTabItem );

protected:
  ThemeTabItem() {}

public:
  ThemeTabItem(FXTabBar* p,const FXString& text,FXIcon* ic=0,
	       FXuint opts=TAB_TOP_NORMAL,
	       FXint x=0,FXint y=0,FXint w=0,FXint h=0,
	       FXint pl=DEFAULT_PAD,FXint pr=DEFAULT_PAD,
	       FXint pt=DEFAULT_PAD,FXint pb=DEFAULT_PAD);
};




class FOX16GUI_API ThemeVerticalFrame : public FXVerticalFrame {
protected:
  ThemeVerticalFrame() {}

public:
  ThemeVerticalFrame(FXComposite *p,FXuint opts=0,FXint x=0,FXint y=0,FXint w=0,FXint h=0,
		     FXint pl=DEFAULT_SPACING,FXint pr=DEFAULT_SPACING,FXint pt=DEFAULT_SPACING,
		     FXint pb=DEFAULT_SPACING,FXint hs=DEFAULT_SPACING,FXint vs=DEFAULT_SPACING);
};




class FOX16GUI_API ThemeHorizontalFrame : public FXHorizontalFrame {
protected:
  ThemeHorizontalFrame() {}

public:
  ThemeHorizontalFrame(FXComposite *p,FXuint opts=0,FXint x=0,FXint y=0,FXint w=0,FXint h=0,FXint
		       pl=DEFAULT_SPACING,FXint pr=DEFAULT_SPACING,FXint pt=DEFAULT_SPACING,
		       FXint pb=DEFAULT_SPACING,FXint hs=DEFAULT_SPACING,FXint vs=DEFAULT_SPACING);
};




class FOX16GUI_API ThemeMenuButton : public FXMenuButton {
  FXDECLARE( ThemeMenuButton );

protected:
  ThemeMenuButton() {}

public:
  ThemeMenuButton(FXComposite* p,const FXString& text,FXIcon* ic=NULL,
		  FXPopup* pup=NULL,
		  FXuint opts=JUSTIFY_NORMAL|ICON_BEFORE_TEXT|MENUBUTTON_DOWN,
		  FXint x=0,FXint y=0,FXint w=0,FXint h=0,
		  FXint pl=DEFAULT_PAD,FXint pr=DEFAULT_PAD,
		  FXint pt=DEFAULT_PAD,FXint pb=DEFAULT_PAD);


  long onPaint(FXObject*,FXSelector,void* ptr);

  FXint getDefaultWidth();
};



class FOX16GUI_API ThemeHeaderItem : public FXHeaderItem {
protected:
  ThemeHeaderItem() {}

public:
  ThemeHeaderItem(const FXString& text, FXIcon* ic=NULL, FXint s=0, void* ptr=NULL);

  void draw(const FXHeader* header,FXDC& dc,FXint x,FXint y,FXint w,FXint h);

};



#endif

