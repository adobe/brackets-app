#ifndef _BRACKETS_EXTENSION_TEST_H
#define _BRACKETS_EXTENSION_TEST_H

#include "include/cef.h"

// Register the Brackets extension handler.
void InitBracketsExtensions();

// Run the test.
void RunBracketsExtensionTest(CefRefPtr<CefBrowser> browser);

// Tell Brackets to open the specified file
void OpenFile(const char *filename, CefRefPtr<CefBrowser> browser);

//Callback to Brackets to let it know a native quit has been fired
void DelegateQuitToBracketsJS(CefRefPtr<CefBrowser> browser);

//Callback to Brackets to let it know a native window close has been fired
bool DelegateWindowCloseToBracketsJS(CefRefPtr<CefBrowser> browser);

//Utility function to identify dev tool browsers
bool IsDevToolsBrowser( CefRefPtr<CefBrowser> browser );

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

//Utility function that maps NSWindows to the browser that they belong to
CefRefPtr<CefBrowser> GetBrowserForWindow(const BracketsMainWindowHandle wnd);

//Get the devtoools browser for the window (or null if it is not the dev tools)
CefRefPtr<CefBrowser> GetDevToolsPopupForBrowser(CefRefPtr<CefBrowser> parentBrowser);
#endif // _BRACKETS_EXTENSION_TEST_H
