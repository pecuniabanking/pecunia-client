/***************************************************************************
    begin       : Fri Jan 22 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef FOX16_GUI_HPP
#define FOX16_GUI_HPP

#include <gwen-gui-fox16/cppgui.hpp>

#include <gwenhywfar/htmlfont_be.h>


#include <fx.h>

#include <list>


/* TODO:
 * - catch closing of dialog and send GWEN_DialogEvent_TypeClose.
 *
 */


class FOX16_GuiUpdater;


class FOX16GUI_API FOX16_Gui: public CppGui {
public:

  class FOX16GUI_API WinScope {
    friend class FOX16_Gui;

  public:
    typedef enum {
      WIN_SCOPE_TYPE_WINDOW=0,
    } WIN_SCOPE_TYPE;

    WinScope(uint32_t parentId, FXWindow *w);
    WinScope(FXWindow *w);
    ~WinScope();

    uint32_t getParentId() const { return m_parentId;};
    uint32_t getId() const { return m_id;};
    FXWindow *getWindow() const { return m_window;};

  protected:
    WinScope(WIN_SCOPE_TYPE t, uint32_t parentId, FXWindow *w);
    WIN_SCOPE_TYPE getType() const { return m_type;};

    uint32_t m_parentId;
    uint32_t m_id;
    FXWindow *m_window;
    WIN_SCOPE_TYPE m_type;

  };
  typedef std::list<WinScope*> WinScopePtrList;

  enum {
    ID_MAINWINDOW=1
  };

  FOX16_Gui(FXApp* a);
  ~FOX16_Gui();

  FXApp *getApp() { return m_app;};

  FOX16GUI_API static FXString getRawText(const char *text);
  FOX16GUI_API static FXString getHtmlText(const char *text);

  FXWindow *getGuiWindow(uint32_t id);

  FOX16GUI_API static FOX16_Gui *getFgGui();

  virtual int openDialog(GWEN_DIALOG *dlg, uint32_t guiid);
  virtual int closeDialog(GWEN_DIALOG *dlg);
  virtual int runDialog(GWEN_DIALOG *dlg, int untilEnd);

  HTML_FONT *getFont(const char *fontName,
		     int fontSize,
		     uint32_t fontFlags);

protected:
  uint32_t getNextId();
  uint32_t getIdOfLastScope();

  void addWinScope(WinScope *ws);
  void delWinScope(WinScope *ws);

  void dumpScopeList();

  HTML_FONT *findFont(const char *fontName,
		      int fontSize,
		      uint32_t fontFlags);


  int print(const char *docTitle,
	    const char *docType,
	    const char *descr,
	    const char *text,
	    uint32_t guiid);

  int execDialog(GWEN_DIALOG *dlg, uint32_t guiid);

  int getFileName(const char *caption,
		  GWEN_GUI_FILENAME_TYPE fnt,
		  uint32_t flags,
		  const char *patterns,
		  GWEN_BUFFER *pathBuffer,
		  uint32_t guiid);


  WinScope *findWinScope(uint32_t id);

  WinScope *findWinScopeExt(uint32_t id);

  FXApp *m_app;
  WinScopePtrList m_scopeList;
  uint32_t m_lastId;

  FOX16_GuiUpdater *m_updater;

  HTML_FONT_LIST *m_fontList;
};





#endif




