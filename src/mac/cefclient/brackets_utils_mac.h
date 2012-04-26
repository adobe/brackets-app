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
