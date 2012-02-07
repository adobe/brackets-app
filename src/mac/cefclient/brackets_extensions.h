#ifndef _BRACKETS_EXTENSIONS_H
#define _BRACKETS_EXTENSIONS_H

#include "include/cef.h"


// Register the Brackets extension handler.
void InitBracketsExtensions();

typedef const std::string BracketsCommandName;

/**
 * BracketsShellAPI contains functionality for making calls from native code to JavaScript
 */
class BracketsShellAPI {

public:
    static bool DispatchQuitToBracketsJS(const CefRefPtr<CefBrowser>& browser);
    static bool DispatchCloseToBracketsJS(const CefRefPtr<CefBrowser>& browser);
	static bool DispatchReloadToBracketsJS(const CefRefPtr<CefBrowser>& browser);
    static bool DispatchBracketsJSCommand(const CefRefPtr<CefBrowser>& browser, BracketsCommandName &command);

    // Command constants (should match Commands.js)
    static BracketsCommandName FILE_QUIT;
    static BracketsCommandName FILE_CLOSE_WINDOW;
    static BracketsCommandName FILE_RELOAD;
};

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

//Utility function to identify dev tool browsers
bool IsDevToolsBrowser( CefRefPtr<CefBrowser> browser );

//Get the devtoools browser for the window (or null if it is not the dev tools)
CefRefPtr<CefBrowser> GetDevToolsPopupForBrowser(CefRefPtr<CefBrowser> parentBrowser);
#endif // _BRACKETS_EXTENSIONS_H
