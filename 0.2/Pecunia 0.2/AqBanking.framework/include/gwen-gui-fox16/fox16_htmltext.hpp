/***************************************************************************
    begin       : Sat Jun 19 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef FOX16_HTMLTEXT_HPP
#define FOX16_HTMLTEXT_HPP

#include <gwen-gui-fox16/cppgui.hpp>

#include <fx.h>


class FOX16_HtmlCtx;


class FOX16GUI_API FOX16_HtmlText: public FXScrollArea {
  FXDECLARE(FOX16_HtmlText)

public:

  enum {
    /** don't wrap the text. If this flag is given as parameter to the constructor
     * then you'll have to insert line-breaks into the text yourself.
     */
    FLAGS_NO_WORDWRAP = 0x00080000
  };

  FOX16_HtmlText(FXComposite* p, const FXString& text,
		 FXuint opts=0,
		 FXint x=0, FXint y=0, FXint w=0, FXint h=0);
  ~FOX16_HtmlText();

  /// Set the text for this label
  void setText(const FXString& text);

  /// Get the text for this label
  FXString getText() const { return m_text; }

  virtual FXint getContentWidth();

  virtual FXint getContentHeight();

  void setMinimumWidth(int i) { m_minWidth=i;};

  void makePositionVisible(FXint pos);

  long onPaint(FXObject*, FXSelector, void*);

  void layout();

protected:
  FOX16_HtmlCtx *m_htmlCtx;
  FXString m_text;
  int m_minWidth;
  int m_maxDefaultWidth;

  bool m_haveDefaultDims;
  FXint m_defaultWidth;
  FXint m_defaultHeight;

  FXint margintop;           // Margins top
  FXint marginbottom;        // Margin bottom
  FXint marginleft;          // Margin left
  FXint marginright;         // Margin right
  FXint barwidth;

  FOX16_HtmlText();
  void updateHtml();
  void calcDefaultDims();


};



#endif

