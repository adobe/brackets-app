// Copyright (c) 2011 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#include "include/cef.h"
#include "include/cef_wrapper.h"
#include "client_handler.h"
#include "resource.h"
#include "resource_util.h"
#include "string_util.h"

#ifdef TEST_REDIRECT_POPUP_URLS
#include "client_popup_handler.h"
#endif

bool ClientHandler::OnBeforePopup(CefRefPtr<CefBrowser> parentBrowser,
                                  const CefPopupFeatures& popupFeatures,
                                  CefWindowInfo& windowInfo,
                                  const CefString& url,
                                  CefRefPtr<CefClient>& client,
                                  CefBrowserSettings& settings)
{
  REQUIRE_UI_THREAD();

   std::string urlStr = url;
#ifdef TEST_REDIRECT_POPUP_URLS
  if(urlStr.find("chrome-devtools:") == std::string::npos) {
    // Show all popup windows excluding DevTools in the current window.
    windowInfo.m_dwStyle &= ~WS_VISIBLE;
    client = new ClientPopupHandler(m_Browser);
  }
#endif // TEST_REDIRECT_POPUP_URLS

  //ensure all non-dev tools windows get a menu bar
  if(windowInfo.m_hMenu == NULL && urlStr.find("chrome-devtools:") == std::string::npos) {
    windowInfo.m_hMenu = ::LoadMenu( GetModuleHandle(NULL), MAKEINTRESOURCE(IDC_CEFCLIENT_POPUP) 	);
  }

  return false;
}

extern CefRefPtr<ClientHandler> g_handler;
namespace {

CefRefPtr<CefBrowser> GetBrowserForWindow(HWND wnd) {
  CefRefPtr<CefBrowser> browser = NULL;
  if(g_handler.get() && wnd) {
    //go through all the browsers looking for a browser within this window
    ClientHandler::BrowserWindowMap browsers( g_handler->GetOpenBrowserWindowMap() );
    ClientHandler::BrowserWindowMap::const_iterator i = browsers.find(wnd);
    if( i != browsers.end() ) {
      browser = i->second;
    }
  }
  return browser;
}

static WNDPROC g_popupWndOldProc = NULL;
//BRACKETS: added so our popup windows can have a menu bar too
//
//  FUNCTION: PopupWndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE:  Handle commands from the menus.
LRESULT CALLBACK PopupWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  //For now, we are only interest in WM_COMMAND's that we know are in our menus
  switch (message)
  {
    case WM_COMMAND:
      {
        CefRefPtr<CefBrowser> browser = GetBrowserForWindow(hWnd);
        int wmId    = LOWORD(wParam);
        int wmEvent = HIWORD(wParam);
        // Parse the menu selections:
        switch (wmId)
        {
        case IDM_CLOSE:
			if(browser.get())
				browser->CloseBrowser();
			return 0;
        case IDC_NAV_RELOAD:  // Reload button
          if(browser.get())
            browser->ReloadIgnoreCache();
          return 0;
        case ID_TESTS_DEVTOOLS_SHOW:
          if (browser.get())
            browser->ShowDevTools();
          return 0;
        case ID_TESTS_DEVTOOLS_CLOSE:
          if (browser.get())
            browser->CloseDevTools();
          return 0;
        }
      }
      break;
  }

  if (g_popupWndOldProc) 
    return (LRESULT)::CallWindowProc(g_popupWndOldProc, hWnd, message, wParam, lParam);
  return ::DefWindowProc(hWnd, message, wParam, lParam);
}

void AttachWindProcToPopup(HWND wnd)
{
  if( !wnd ) {
    return;
  }

  if( !::GetMenu(wnd) ) {
    return; //no menu, no need for the proc
  }

  WNDPROC curProc = reinterpret_cast<WNDPROC>(GetWindowLongPtr(wnd, GWLP_WNDPROC));

  //if this is the first time, assume the above checks are all we need, otherwise
  //it had better be the same proc we pulled before
  if(!g_popupWndOldProc) {
    g_popupWndOldProc = curProc;
  }
  else if( g_popupWndOldProc != curProc ) {
    return;
  }

  SetWindowLongPtr(wnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(PopupWndProc));
}

void LoadWindowsIcons(HWND wnd)
{
	if( !wnd ) {
		return;
	}
	//We need to load the icons after the pop up is created so they have the
	//brackets icon instead of the generic window icon
	HINSTANCE inst = ::GetModuleHandle(NULL);
	HICON bigIcon = ::LoadIcon(inst, MAKEINTRESOURCE(IDI_BRACKETS));
	HICON smIcon = ::LoadIcon(inst, MAKEINTRESOURCE(IDI_BRACKETS_SMALL));
	if(bigIcon) {
		::SendMessage(wnd, WM_SETICON, ICON_BIG, (LPARAM)bigIcon);
	}
	if(smIcon) {
		::SendMessage(wnd, WM_SETICON, ICON_SMALL, (LPARAM)smIcon);
	}
}

}

void ClientHandler::OnAfterCreated(CefRefPtr<CefBrowser> browser)
{
  REQUIRE_UI_THREAD();

  AutoLock lock_scope(this);
  if(!m_Browser.get())
  {
    // We need to keep the main child window, but not popup windows
    m_Browser = browser;
    m_BrowserHwnd = browser->GetWindowHandle();
  }
  else
  {
    AttachWindProcToPopup(browser->GetWindowHandle());
	LoadWindowsIcons(browser->GetWindowHandle());
  }

  m_OpenBrowserWindowMap[browser->GetWindowHandle()] = browser;
}


bool ClientHandler::OnBeforeResourceLoad(CefRefPtr<CefBrowser> browser,
                                     CefRefPtr<CefRequest> request,
                                     CefString& redirectUrl,
                                     CefRefPtr<CefStreamReader>& resourceStream,
                                     CefRefPtr<CefResponse> response,
                                     int loadFlags)
{
  REQUIRE_IO_THREAD();

  std::string url = request->GetURL();
  if(url == "http://tests/request") {
    // Show the request contents
    std::string dump;
    DumpRequestContents(request, dump);
    resourceStream =
        CefStreamReader::CreateForData((void*)dump.c_str(), dump.size());
    response->SetMimeType("text/plain");
    response->SetStatus(200);
  } else if(strstr(url.c_str(), "/ps_logo2.png") != NULL) {
    // Any time we find "ps_logo2.png" in the URL substitute in our own image
    resourceStream = GetBinaryResourceReader(IDS_LOGO);
    response->SetMimeType("image/png");
    response->SetStatus(200);
  } else if(url == "http://tests/uiapp") {
    // Show the uiapp contents
    resourceStream = GetBinaryResourceReader(IDS_UIPLUGIN);
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/osrapp") {
    // Show the osrapp contents
    resourceStream = GetBinaryResourceReader(IDS_OSRPLUGIN);
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/localstorage") {
    // Show the localstorage contents
    resourceStream = GetBinaryResourceReader(IDS_LOCALSTORAGE);
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/xmlhttprequest") {
    // Show the xmlhttprequest HTML contents
    resourceStream = GetBinaryResourceReader(IDS_XMLHTTPREQUEST);
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/domaccess") {
    // Show the domaccess HTML contents
    resourceStream = GetBinaryResourceReader(IDS_DOMACCESS);
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(strstr(url.c_str(), "/logoball.png") != NULL) {
    // Load the "logoball.png" image resource.
    resourceStream = GetBinaryResourceReader(IDS_LOGOBALL);
    response->SetMimeType("image/png");
    response->SetStatus(200);
  } else if(url == "http://tests/modalmain") {
    resourceStream = GetBinaryResourceReader(IDS_MODALMAIN);
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/modaldialog") {
    resourceStream = GetBinaryResourceReader(IDS_MODALDIALOG);
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/transparency") {
    resourceStream = GetBinaryResourceReader(IDS_TRANSPARENCY);
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/plugin") {
    std::string html =
        "<html><body>\n"
        "Client Plugin loaded by Mime Type:<br>\n"
        "<embed type=\"application/x-client-plugin\" width=600 height=40>\n"
        "<br><br>Client Plugin loaded by File Extension:<br>\n"
        "<embed src=\"test.xcp\" width=600 height=40>\n"
        // Add some extra space below the plugin to allow scrolling.
        "<div style=\"height:1000px;\">&nbsp;</div>\n"
        "</body></html>";
  
    resourceStream =
        CefStreamReader::CreateForData((void*)html.c_str(), html.size());
    response->SetMimeType("text/html");
    response->SetStatus(200);
  }

  return false;
}

void ClientHandler::OnAddressChange(CefRefPtr<CefBrowser> browser,
                                    CefRefPtr<CefFrame> frame,
                                    const CefString& url)
{
  REQUIRE_UI_THREAD();

  if(m_BrowserHwnd == browser->GetWindowHandle() && frame->IsMain())
  {
    // Set the edit window text
    SetWindowText(m_EditHwnd, std::wstring(url).c_str());
  }
}

void ClientHandler::OnTitleChange(CefRefPtr<CefBrowser> browser,
                                  const CefString& title)
{
  REQUIRE_UI_THREAD();

  // Set the frame window title bar
  CefWindowHandle hwnd = browser->GetWindowHandle();
  if(m_BrowserHwnd == hwnd)
  {
    // The frame window will be the parent of the browser window
    hwnd = GetParent(hwnd);
  }
  SetWindowText(hwnd, std::wstring(title).c_str());
}

void ClientHandler::SendNotification(NotificationType type)
{
  UINT id;
  switch(type)
  {
  case NOTIFY_CONSOLE_MESSAGE:
    id = ID_WARN_CONSOLEMESSAGE;
    break;
  case NOTIFY_DOWNLOAD_COMPLETE:
    id = ID_WARN_DOWNLOADCOMPLETE;
    break;
  case NOTIFY_DOWNLOAD_ERROR:
    id = ID_WARN_DOWNLOADERROR;
    break;
  default:
    return;
  }
  PostMessage(m_MainHwnd, WM_COMMAND, id, 0);
}

void ClientHandler::SetLoading(bool isLoading)
{
	/*
  ASSERT(m_EditHwnd != NULL && m_ReloadHwnd != NULL && m_StopHwnd != NULL);
  EnableWindow(m_EditHwnd, TRUE);
  EnableWindow(m_ReloadHwnd, !isLoading);
  EnableWindow(m_StopHwnd, isLoading);
  */
}

void ClientHandler::SetNavState(bool canGoBack, bool canGoForward)
{
/*
  ASSERT(m_BackHwnd != NULL && m_ForwardHwnd != NULL);
  EnableWindow(m_BackHwnd, canGoBack);
  EnableWindow(m_ForwardHwnd, canGoForward);
  */
}

void ClientHandler::CloseMainWindow()
{
  ::PostMessage(m_MainHwnd, WM_CLOSE, 0, 0);
}
