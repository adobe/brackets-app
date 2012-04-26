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

#ifndef _BRACKETS_EXTENSIONS_H
#define _BRACKETS_EXTENSIONS_H

#include "include/cef.h"


// Register the Brackets extension handler.
void InitBracketsExtensions();

typedef const std::wstring BracketsCommandName;

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
