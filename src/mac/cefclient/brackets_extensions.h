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

#endif // _BRACKETS_EXTENSION_TEST_H
