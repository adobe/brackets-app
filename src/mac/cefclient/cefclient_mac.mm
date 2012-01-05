// Copyright (c) 2010 The Chromium Embedded Framework Authors.
// Portions copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/cef.h"
#import "include/cef_application_mac.h"
#include "cefclient.h"
#include "brackets_extensions.h"
#include "client_handler.h"
#include "resource_util.h"
#include "string_util.h"
#import <Cocoa/Cocoa.h>
#include <sstream>
#include <string>

// The global ClientHandler reference.
extern CefRefPtr<ClientHandler> g_handler;

char szWorkingDir[512];   // The current working directory

// Sizes for URL bar layout
#define BUTTON_HEIGHT 22
#define BUTTON_WIDTH 72
#define BUTTON_MARGIN 8
#define URLBAR_HEIGHT  32

// Content area size for newly created windows.
const int kWindowWidth = 1000;
const int kWindowHeight = 700;

// Memory AutoRelease pool.
static NSAutoreleasePool* g_autopool = nil;

// Provide the CefAppProtocol implementation required by CEF.
@interface ClientApplication : NSApplication<CefAppProtocol> {
@private
  BOOL handlingSendEvent_;
}
@end

@implementation ClientApplication
- (BOOL)isHandlingSendEvent {
  return handlingSendEvent_;
}

- (void)setHandlingSendEvent:(BOOL)handlingSendEvent {
  handlingSendEvent_ = handlingSendEvent;
}

- (void)sendEvent:(NSEvent*)event {
  CefScopedSendingEvent sendingEventScoper;
  [super sendEvent:event];
}
@end


// Receives notifications from controls and the browser window. Will delete
// itself when done.
@interface ClientWindowDelegate : NSObject <NSWindowDelegate>
- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)stopLoading:(id)sender;
- (IBAction)takeURLStringValueFrom:(NSTextField *)sender;
- (void)alert:(NSString*)title withMessage:(NSString*)message;
- (void)notifyConsoleMessage:(id)object;
- (void)notifyDownloadComplete:(id)object;
- (void)notifyDownloadError:(id)object;
@end

@implementation ClientWindowDelegate

- (IBAction)goBack:(id)sender {
  if (g_handler.get() && g_handler->GetBrowserHwnd())
    g_handler->GetBrowser()->GoBack();
}

- (IBAction)goForward:(id)sender {
  if (g_handler.get() && g_handler->GetBrowserHwnd())
    g_handler->GetBrowser()->GoForward();
}

- (IBAction)reload:(id)sender {
  if (g_handler.get() && g_handler->GetBrowserHwnd())
    g_handler->GetBrowser()->Reload();
}

- (IBAction)stopLoading:(id)sender {
  if (g_handler.get() && g_handler->GetBrowserHwnd())
    g_handler->GetBrowser()->StopLoad();
}

- (IBAction)takeURLStringValueFrom:(NSTextField *)sender {
  if (!g_handler.get() || !g_handler->GetBrowserHwnd())
    return;
  
  NSString *url = [sender stringValue];
  
  // if it doesn't already have a prefix, add http. If we can't parse it,
  // just don't bother rather than making things worse.
  NSURL* tempUrl = [NSURL URLWithString:url];
  if (tempUrl && ![tempUrl scheme])
    url = [@"http://" stringByAppendingString:url];
  
  std::string urlStr = [url UTF8String];
  g_handler->GetBrowser()->GetMainFrame()->LoadURL(urlStr);
}

- (void)alert:(NSString*)title withMessage:(NSString*)message {
  NSAlert *alert = [NSAlert alertWithMessageText:title
                                   defaultButton:@"OK"
                                 alternateButton:nil
                                     otherButton:nil
                       informativeTextWithFormat:message];
  [alert runModal];
}

- (void)notifyConsoleMessage:(id)object {
/*
  std::stringstream ss;
  ss << "Console messages will be written to " << g_handler->GetLogFile();
  NSString* str = [NSString stringWithUTF8String:(ss.str().c_str())];
  [self alert:@"Console Messages" withMessage:str];
*/
}

- (void)notifyDownloadComplete:(id)object {
  std::stringstream ss;
  ss << "File \"" << g_handler->GetLastDownloadFile() <<
      "\" downloaded successfully.";
  NSString* str = [NSString stringWithUTF8String:(ss.str().c_str())];
  [self alert:@"File Download" withMessage:str];
}

- (void)notifyDownloadError:(id)object {
  std::stringstream ss;
  ss << "File \"" << g_handler->GetLastDownloadFile() <<
      "\" failed to download.";
  NSString* str = [NSString stringWithUTF8String:(ss.str().c_str())];
  [self alert:@"File Download" withMessage:str];
}

- (void)windowDidBecomeKey:(NSNotification*)notification {
  if(g_handler.get() && g_handler->GetBrowserHwnd()) {
    // Give focus to the browser window.
    g_handler->GetBrowser()->SetFocus(true);
  }
}

// Called when the window is about to close. Perform the self-destruction
// sequence by getting rid of the window. By returning YES, we allow the window
// to be removed from the screen.
- (BOOL)windowShouldClose:(id)window {  
  // Try to make the window go away.
  [window autorelease];
  
  // Clean ourselves up after clearing the stack of anything that might have the
  // window on it.
  [self performSelectorOnMainThread:@selector(cleanup:)
                         withObject:window
                      waitUntilDone:NO];
  
  return YES;
}

// Deletes itself.
- (void)cleanup:(id)window {  
  [self release];
}

@end


NSButton* MakeButton(NSRect* rect, NSString* title, NSView* parent) {
  NSButton* button = [[[NSButton alloc] initWithFrame:*rect] autorelease];
  [button setTitle:title];
  [button setBezelStyle:NSSmallSquareBezelStyle];
  [button setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
  [parent addSubview:button];
  rect->origin.x += BUTTON_WIDTH;
  return button;
}

// Receives notifications from the application. Will delete itself when done.
@interface ClientAppDelegate : NSObject
- (void)createApp:(id)object;
- (IBAction)showDevTools:(id)sender;
- (IBAction)hideDevTools:(id)sender;
@end

@implementation ClientAppDelegate

// Create the application on the UI thread.
- (void)createApp:(id)object {
  [NSApplication sharedApplication];
  [NSBundle loadNibNamed:@"MainMenu" owner:NSApp];
  
  // Set the delegate for application events.
  [NSApp setDelegate:self];
  
  // Create the delegate for control and browser window events.
  ClientWindowDelegate* delegate = [[ClientWindowDelegate alloc] init];
  
  // Create the main application window.
  NSRect screen_rect = [[NSScreen mainScreen] visibleFrame];
  NSRect window_rect = { {0, screen_rect.size.height - kWindowHeight},
    {kWindowWidth, kWindowHeight} };
  NSWindow* mainWnd = [[NSWindow alloc]
                       initWithContentRect:window_rect
                       styleMask:(NSTitledWindowMask |
                                  NSClosableWindowMask |
                                  NSMiniaturizableWindowMask |
                                  NSResizableWindowMask )
                       backing:NSBackingStoreBuffered
                       defer:NO];
  [mainWnd setTitle:@"Brackets"];
  [mainWnd setDelegate:delegate];

  // Rely on the window delegate to clean us up rather than immediately
  // releasing when the window gets closed. We use the delegate to do
  // everything from the autorelease pool so the window isn't on the stack
  // during cleanup (ie, a window close from javascript).
  [mainWnd setReleasedWhenClosed:NO];

  NSView* contentView = [mainWnd contentView];
    
  // Create the handler.
  g_handler = new ClientHandler();
  g_handler->SetMainHwnd(contentView);

  // Create the browser view.
  CefWindowInfo window_info;
  CefBrowserSettings settings;
    
  // Brackets - reduce file url security
  settings.universal_access_from_file_urls_allowed = TRUE;
  settings.file_access_from_file_urls_allowed = TRUE;

  window_info.SetAsChild(contentView, 0, 0, kWindowWidth, kWindowHeight);
  
  std::string initialUrl;
  
  // Look for command line arguments. The first argument is always
  // the app name. If there is a second argument, use that as the url
  // for the main browser view.
  NSArray *arguments = [[NSProcessInfo processInfo] arguments];
   
  if (arguments && [arguments count] > 1) { 
    initialUrl = [[arguments objectAtIndex:1] UTF8String];
    
    // Make sure the initialUrl contains ".htm". When launching from
    // the command line, the OS sometimes passes a pid as a command 
    // line argument
    if (initialUrl.find(".htm") == std::string::npos)
      initialUrl = "";
  }
  
  if (initialUrl == "") {    
    std::string appPath = [[[NSBundle mainBundle] bundlePath] UTF8String];
    std::string filePath;
      
    // Warning: this is a hack.
    // Look for the index.html file in the following order:
    // 1). If the app path includes "xcodebuild", assume we're running from
    //     xcode and reach over to the brackets directory.
    // 2). If the app path doesn't include "xcodebuild", assume we're running
    //     from the bin/mac directory and reach over to the brackets directory.
    //
    // Once we determine final packaging we should look for index.html in the
    // app bundle and provide a mechanism for specifying a specific index.html
    // to load.

    appPath = appPath.substr(0, appPath.rfind("/"));
    if (appPath.find("xcodebuild") != std::string::npos)
        filePath = appPath + "/../../../../brackets/src/index.html";
    else
        filePath = appPath + "/../../brackets/src/index.html";
        
    initialUrl = "file://" + filePath;
  }
  
  CefBrowser::CreateBrowser(window_info, g_handler.get(),
                            initialUrl, settings);

  // Show the window.
  [mainWnd makeKeyAndOrderFront: nil];

  // Size the window.
  NSRect r = [mainWnd contentRectForFrameRect:[mainWnd frame]];
  r.size.width = kWindowWidth;
  r.size.height = kWindowHeight;
  [mainWnd setFrame:[mainWnd frameRectForContentRect:r] display:YES];
}


- (IBAction)reload:(id)sender {
    if (g_handler.get() && g_handler->GetBrowserHwnd())
        g_handler->GetBrowser()->Reload();
}

- (IBAction)showDevTools:(id)sender {
  if(g_handler.get() && g_handler->GetBrowserHwnd()) {
    CefRefPtr<CefBrowser> browser = g_handler->GetBrowser();
    browser->ShowDevTools();
  }
}

- (IBAction)hideDevTools:(id)sender {
  if(g_handler.get() && g_handler->GetBrowserHwnd()) {
    CefRefPtr<CefBrowser> browser = g_handler->GetBrowser();
    browser->CloseDevTools();
  }
}

// Sent by the default notification center immediately before the application
// terminates.
- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Shut down CEF.
  g_handler = NULL;
  CefShutdown();

  [self release];

  // Release the AutoRelease pool.
  [g_autopool release];
}

@end


int main(int argc, char* argv[])
{
  // Retrieve the current working directory.
  getcwd(szWorkingDir, sizeof(szWorkingDir));

  // Initialize the AutoRelease pool.
  g_autopool = [[NSAutoreleasePool alloc] init];

  // Initialize the ClientApplication instance.
  [ClientApplication sharedApplication];

  // Initialize CEF.
  CefSettings settings;
  
  // Set persistence cache "~/Library/Caches/com.adobe.Brackets.cefCache"
  NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];   
  NSString *cefCacheDirectory = [NSString stringWithFormat:@"%@/%@.cefCache", libraryDirectory, bundleIdentifier];
  std::string cachePath = [cefCacheDirectory UTF8String];
  
  CefString(&settings.cache_path).FromASCII(cachePath.c_str());

  // Use the Chinese language locale.
  // CefString(&settings.locale).FromASCII("zh-cn");

  CefInitialize(settings);

  // Initialize Brackets extensions
  InitBracketsExtensions();
    
  // Create the application delegate and window.
  NSObject* delegate = [[ClientAppDelegate alloc] init];
  [delegate performSelectorOnMainThread:@selector(createApp:) withObject:nil
                          waitUntilDone:NO];

  // Run the application message loop.
  CefRunMessageLoop();

  // Don't put anything below this line because it won't be executed.
  return 0;
}

// Global functions

std::string AppGetWorkingDirectory()
{
  return szWorkingDir;
}
