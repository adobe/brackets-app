/*
 * Copyright 2012 Adobe Systems Incorporated. All Rights Reserved.
 */

#ifndef _BRACKETS_UTILS_MAC_H
#define _BRACKETS_UTILS_MAC_H

#include "include/cef.h"


#ifdef __cplusplus
#ifdef __OBJC__
@class NSWindow;
#else
class NSWindow;
#endif
#define brackets_main_window_handle_t NSWindow*
#else
#define brackets_main_window_handle_t void*
#endif
#define BracketsMainWindowHandle brackets_main_window_handle_t

namespace Brackets { 
namespace Utils {

//Utility function that maps NSWindows to the browser that they belong to
CefRefPtr<CefBrowser> GetBrowserForWindow(const BracketsMainWindowHandle wnd);

//Utility function to identify dev tool browsers
bool IsDevToolsBrowser( CefRefPtr<CefBrowser> browser );

//Get the devtoools browser for the window (or null if it is not the dev tools)
CefRefPtr<CefBrowser> GetDevToolsPopupForBrowser(CefRefPtr<CefBrowser> parentBrowser);

} 
}
#endif // _BRACKETS_UTILS_MAC_H
