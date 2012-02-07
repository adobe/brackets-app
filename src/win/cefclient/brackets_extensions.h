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
	static void DelegateQuitToBracketsJS(CefRefPtr<CefBrowser> browser);
	static void DelegateCloseToBracketsJS(CefRefPtr<CefBrowser> browser);
	static void ExecuteJavaScript(CefRefPtr<CefBrowser> browser, const CefString& jsCode);
};



#endif // _BRACKETS_EXTENSIONS_H
