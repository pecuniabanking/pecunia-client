/***************************************************************************
    begin       : Tue Feb 23 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef FOX16_HTMLLABEL_HPP
#define FOX16_HTMLLABEL_HPP

#include <gwen-gui-fox16/cppgui.hpp>

#include <fx.h>


class FOX16_HtmlCtx;


class FOX16GUI_API FOX16_HtmlLabel: public FXFrame {
  FXDECLARE(FOX16_HtmlLabel)

public:

  enum {
    /** don't wrap the text. If this flag is given as parameter to the constructor
     * then you'll have to insert line-breaks into the text yourself.
     */
    FLAGS_NO_WORDWRAP    = 0x00080000,
    /** when wrapping words use the full widget width to layout the text.
     * Otherwise the wordwrapping occurrs at the width set by @ref setMaxDefaultWidth().
     */
    FLAGS_USE_FULL_WIDTH = 0x00040000
  };

  FOX16_HtmlLabel(FXComposite* p, const FXString& text,
		  FXuint opts=0,
		  FXint x=0, FXint y=0, FXint w=0, FXint h=0,
		  FXint pl=DEFAULT_PAD, FXint pr=DEFAULT_PAD,
		  FXint pt=DEFAULT_PAD, FXint pb=DEFAULT_PAD);
  ~FOX16_HtmlLabel();

  /// Set the text for this label
  void setText(const FXString& text);

  /// Get the text for this label
  FXString getText() const { return m_text; }

  FXIcon *getIcon() const { return m_icon;};
  void setIcon(FXIcon *ic);

  void addMediaPath(const char *s);

  /// Return default width
  virtual FXint getDefaultWidth();

  /// Return default height
  virtual FXint getDefaultHeight();

  void create();

  void setMinimumWidth(int i) { m_minWidth=i;};
  void setMaxDefaultWidth(int i) { m_maxDefaultWidth=i;};

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

  GWEN_STRINGLIST *m_mediaPaths;

  FXIcon *m_icon;

  FOX16_HtmlLabel();
  void updateHtml();
  void calcDefaultDims();


};



#endif

