#ifndef _BRACKETS_EXTENSIONS_H
#define _BRACKETS_EXTENSIONS_H

#include "include/cef.h"

// Register the Brackets extension handler.
void InitBracketsExtensions();

class BracketsShellAPI {

public:
	static bool DelegateQuitToBracketsJS(const CefRefPtr<CefBrowser>& browser);
	static bool DelegateCloseToBracketsJS(const CefRefPtr<CefBrowser>& browser);
	static bool CallShellAPI(const CefRefPtr<CefBrowser>& browser, const CefString& functionName );
};



#endif // _BRACKETS_EXTENSIONS_H
