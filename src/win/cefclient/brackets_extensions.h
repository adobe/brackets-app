#ifndef _BRACKETS_EXTENSIONS_H
#define _BRACKETS_EXTENSIONS_H

#include "include/cef.h"

// Register the Brackets extension handler.
void InitBracketsExtensions();

void DelegateQuitToBracketsJS(CefRefPtr<CefBrowser> browser);

#endif // _BRACKETS_EXTENSIONS_H
