/*
 * Copyright (c) 2012 Adobe Systems Incorporated. All rights reserved.
 *  
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"), 
 * to deal in the Software without restriction, including without limitation 
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of the Software, and to permit persons to whom the 
 * Software is furnished to do so, subject to the following conditions:
 *  
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *  
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 * 
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
