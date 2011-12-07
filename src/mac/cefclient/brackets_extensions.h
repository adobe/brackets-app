#ifndef _BRACKETS_EXTENSION_TEST_H
#define _BRACKETS_EXTENSION_TEST_H

#include "include/cef.h"

// Register the Brackets extension handler.
void InitBracketsExtensions();

// Run the test.
void RunBracketsExtensionTest(CefRefPtr<CefBrowser> browser);

// Tell Brackets to open the specified file
void OpenFile(const char *filename, CefRefPtr<CefBrowser> browser);

#endif // _BRACKETS_EXTENSION_TEST_H
