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



#endif // _BRACKETS_EXTENSIONS_H
