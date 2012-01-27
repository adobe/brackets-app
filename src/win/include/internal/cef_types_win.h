// Copyright (c) 2009 Marshall A. Greenblatt. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the name Chromium Embedded
// Framework nor the names of its contributors may be used to endorse
// or promote products derived from this software without specific prior
// written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#ifndef _CEF_TYPES_WIN_H
#define _CEF_TYPES_WIN_H

#if defined(OS_WIN)
#include <windows.h>
#include "cef_string.h"

#ifdef __cplusplus
extern "C" {
#endif

// Window handle.
#define cef_window_handle_t HWND
#define cef_cursor_handle_t HCURSOR

///
// Supported graphics implementations.
///
enum cef_graphics_implementation_t
{
  ANGLE_IN_PROCESS = 0,
  ANGLE_IN_PROCESS_COMMAND_BUFFER,
  DESKTOP_IN_PROCESS,
  DESKTOP_IN_PROCESS_COMMAND_BUFFER,
};

///
// Class representing window information.
///
typedef struct _cef_window_info_t
{
  // Standard parameters required by CreateWindowEx()
  DWORD m_dwExStyle;
  cef_string_t m_windowName;
  DWORD m_dwStyle;
  int m_x;
  int m_y;
  int m_nWidth;
  int m_nHeight;
  cef_window_handle_t m_hWndParent;
  HMENU m_hMenu;

  // If window rendering is disabled no browser window will be created. Set
  // |m_hWndParent| to the window that will act as the parent for popup menus,
  // dialog boxes, etc.
  BOOL m_bWindowRenderingDisabled;

  // Set to true to enable transparent painting.
  BOOL m_bTransparentPainting;
  
  // Handle for the new browser window.
  cef_window_handle_t m_hWnd;
} cef_window_info_t;

///
// Class representing print context information.
///
typedef struct _cef_print_info_t
{
  HDC m_hDC;
  RECT m_Rect;
  double m_Scale;
} cef_print_info_t;

#ifdef __cplusplus
}
#endif

#endif // OS_WIN

#endif // _CEF_TYPES_WIN_H
