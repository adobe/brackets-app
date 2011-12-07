// Copyright (c) 2011 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#include "include/cef.h"
#include "include/cef_wrapper.h"
#include "cefclient.h"
#include "client_handler.h"
#include "resource_util.h"
#include "string_util.h"
#include "NSAlert+SynchronousSheet.h"
#import <Cocoa/Cocoa.h>
#import <sstream>

#ifdef TEST_REDIRECT_POPUP_URLS
#include "client_popup_handler.h"
#endif

// ClientHandler::ClientLifeSpanHandler implementation

bool ClientHandler::OnBeforePopup(CefRefPtr<CefBrowser> parentBrowser,
                                  const CefPopupFeatures& popupFeatures,
                                  CefWindowInfo& windowInfo,
                                  const CefString& url,
                                  CefRefPtr<CefClient>& client,
                                  CefBrowserSettings& settings)
{
  REQUIRE_UI_THREAD();

#ifdef TEST_REDIRECT_POPUP_URLS
  std::string urlStr = url;
  if(urlStr.find("chrome-devtools:") == std::string::npos) {
    // Show all popup windows excluding DevTools in the current window.
    windowInfo.m_bHidden = true;
    client = new ClientPopupHandler(m_Browser);
  }
#endif // TEST_REDIRECT_POPUP_URLS

  return false;
}

bool ClientHandler::OnBeforeResourceLoad(CefRefPtr<CefBrowser> browser,
                                     CefRefPtr<CefRequest> request,
                                     CefString& redirectUrl,
                                     CefRefPtr<CefStreamReader>& resourceStream,
                                     CefRefPtr<CefResponse> response,
                                     int loadFlags)
{
  REQUIRE_IO_THREAD();

/*
  std::string url = request->GetURL();
  if(url == "http://tests/request") {
    // Show the request contents
    std::string dump;
    DumpRequestContents(request, dump);
    resourceStream = CefStreamReader::CreateForData(
        (void*)dump.c_str(), dump.size());
    response->SetMimeType("text/plain");
    response->SetStatus(200);
  } else if (strstr(url.c_str(), "/ps_logo2.png") != NULL) {
    // Any time we find "ps_logo2.png" in the URL substitute in our own image
    resourceStream = GetBinaryResourceReader("logo.png");
    response->SetMimeType("image/png");
    response->SetStatus(200);
  } else if(url == "http://tests/localstorage") {
    // Show the localstorage contents
    resourceStream = GetBinaryResourceReader("localstorage.html");
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/xmlhttprequest") {
    // Show the xmlhttprequest HTML contents
    resourceStream = GetBinaryResourceReader("xmlhttprequest.html");
    response->SetMimeType("text/html");
    response->SetStatus(200);
  } else if(url == "http://tests/domaccess") {
    // Show the domaccess HTML contents
    resourceStream = GetBinaryResourceReader("domaccess.html");
    response->SetMimeType("text/html");
    response->SetStatus(200);
  }
*/
    
  return false;
}

void ClientHandler::OnAddressChange(CefRefPtr<CefBrowser> browser,
                                    CefRefPtr<CefFrame> frame,
                                    const CefString& url)
{
  REQUIRE_UI_THREAD();

  if(m_BrowserHwnd == browser->GetWindowHandle() && frame->IsMain())
  {
    // Set the edit window text
    NSTextField* textField = (NSTextField*)m_EditHwnd;
    std::string urlStr(url);
    NSString* str = [NSString stringWithUTF8String:urlStr.c_str()];
    [textField setStringValue:str];
  }
}

void ClientHandler::OnTitleChange(CefRefPtr<CefBrowser> browser,
                                  const CefString& title)
{
  REQUIRE_UI_THREAD();

  // Set the frame window title bar
  NSView* view = (NSView*)browser->GetWindowHandle();
  NSWindow* window = [view window];
  std::string titleStr(title);
  NSString* str = [NSString stringWithUTF8String:titleStr.c_str()];
  [window setTitle:str];
}

void ClientHandler::SendNotification(NotificationType type)
{
  SEL sel = nil;
  switch(type) {
    case NOTIFY_CONSOLE_MESSAGE:
      sel = @selector(notifyConsoleMessage:);
      break;
    case NOTIFY_DOWNLOAD_COMPLETE:
      sel = @selector(notifyDownloadComplete:);
      break;
    case NOTIFY_DOWNLOAD_ERROR:
      sel = @selector(notifyDownloadError:);
      break;
  }

  if(sel == nil)
    return;

  NSWindow* window = [AppGetMainHwnd() window];
  NSObject* delegate = [window delegate];
  [delegate performSelectorOnMainThread:sel withObject:nil waitUntilDone:NO];
}

void ClientHandler::SetLoading(bool isLoading)
{
  // TODO(port): Change button status.
}

void ClientHandler::SetNavState(bool canGoBack, bool canGoForward)
{
  // TODO(port): Change button status.
}

void ClientHandler::CloseMainWindow()
{
  // TODO(port): Close window
}


///
// Called  to run a JavaScript alert message. Return false to display the
// default alert or true if you displayed a custom alert.
///
/*--cef()--*/
bool ClientHandler::OnJSAlert(CefRefPtr<CefBrowser> browser,
                              CefRefPtr<CefFrame> frame,
                              const CefString& message) 
{ 
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    
    std::string msgString(message);
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:[NSString stringWithUTF8String:msgString.c_str()]];
    
    [alert runModalSheet];
    
    return true; 
}

///
// Called to run a JavaScript confirm request. Return false to display the
// default alert or true if you displayed a custom alert. If you handled the
// alert set |retval| to true if the user accepted the confirmation.
///
/*--cef()--*/
bool ClientHandler::OnJSConfirm(CefRefPtr<CefBrowser> browser,
                                CefRefPtr<CefFrame> frame,
                                const CefString& message,
                                bool& retval) 
{ 
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    int result;
    
    std::string msgString(message);
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:[NSString stringWithUTF8String:msgString.c_str()]];
    
    result = [alert runModalSheet];
    
    retval = result == NSAlertFirstButtonReturn;
    return true;
}

///
// Called to run a JavaScript prompt request. Return false to display the
// default prompt or true if you displayed a custom prompt. If you handled
// the prompt set |retval| to true if the user accepted the prompt and request
// and |result| to the resulting value.
///
/*--cef()--*/
bool ClientHandler::OnJSPrompt(CefRefPtr<CefBrowser> browser,
                               CefRefPtr<CefFrame> frame,
                               const CefString& message,
                               const CefString& defaultValue,
                               bool& retval,
                               CefString& result) 
{ 
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    NSTextField *textfield = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 22)];
    
    std::string msgString(message);
    std::string defaultString(defaultValue);
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:[NSString stringWithUTF8String:msgString.c_str()]];
    [textfield setStringValue:[NSString stringWithUTF8String:defaultString.c_str()]];
    [alert setAccessoryView:textfield];
    
    [alert layout];
    NSView* view = (NSView*)browser->GetWindowHandle();
    NSWindow* window = [view window];
    [window makeFirstResponder:textfield];
    
    int buttonClicked = [alert runModalSheet];
    
    result = [[textfield stringValue] UTF8String];
    retval = buttonClicked == NSAlertFirstButtonReturn;
    
    return true; 
}


