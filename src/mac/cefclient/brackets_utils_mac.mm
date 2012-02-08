/*
 * Copyright 2012 Adobe Systems Incorporated. All Rights Reserved.
 */

#include "brackets_utils_mac.h"
#include "client_handler.h"

#import <Cocoa/Cocoa.h>

extern CefRefPtr<ClientHandler> g_handler;


bool Brackets::Utils::IsDevToolsBrowser( CefRefPtr<CefBrowser> browser ) {
  if( !browser ) { 
    return false;
  }
  
  CefRefPtr<CefFrame> frame = browser->GetMainFrame();
  if( !frame ) {
    return false;
  }
  
  std::string url = frame->GetURL();
  const char * chromeProtocol = "chrome-devtools";
  return ( 0 == strncmp(url.c_str(), chromeProtocol, strlen(chromeProtocol)) );
}



CefRefPtr<CefBrowser> Brackets::Utils::GetBrowserForWindow(const BracketsMainWindowHandle wnd) {
  CefRefPtr<CefBrowser> browser = NULL;
  if(g_handler.get() && wnd) {
    //go through all the browsers looking for a browser within this window
    ClientHandler::BrowserWindowMap browsers( g_handler->GetOpenBrowserWindowMap() );
    for( ClientHandler::BrowserWindowMap::const_iterator i = browsers.begin() ; i != browsers.end() && browser == NULL ; i++ ) {
      NSView* browserView = i->first;
      if( browserView && [browserView window] == wnd ) {
        browser = i->second;
      }
    }
  }
  return browser;
}

CefRefPtr<CefBrowser> Brackets::Utils::GetDevToolsPopupForBrowser(CefRefPtr<CefBrowser> parentBrowser) {
  CefRefPtr<CefBrowser> browser = NULL;
  if(g_handler.get() && parentBrowser) {
    //go through all the browsers looking for the one that was opened by the parentBrowser
    ClientHandler::BrowserWindowMap browsers( g_handler->GetOpenBrowserWindowMap() );
    for( ClientHandler::BrowserWindowMap::const_iterator i = browsers.begin() ; i != browsers.end() && browser == NULL ; i++ ) {
      if( IsDevToolsBrowser(i->second) && parentBrowser->GetWindowHandle() == i->second->GetOpenerWindowHandle() ) {
        browser = i->second;
      }
    }
  }
  return browser;
}
