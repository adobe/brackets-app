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


#include "brackets_extensions.h"
#include "client_handler.h"

#import <Cocoa/Cocoa.h>

#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>

extern CefRefPtr<ClientHandler> g_handler;
extern CFAbsoluteTime g_appStartupTime;

// Error values. These MUST be in sync with the error values
// in brackets_extensions.js
static const int NO_ERROR                   = 0;
static const int ERR_UNKNOWN                = 1;
static const int ERR_INVALID_PARAMS         = 2;
static const int ERR_NOT_FOUND              = 3;
static const int ERR_CANT_READ              = 4;
static const int ERR_UNSUPPORTED_ENCODING   = 5;
static const int ERR_CANT_WRITE             = 6;
static const int ERR_OUT_OF_SPACE           = 7;
static const int ERR_NOT_FILE               = 8;
static const int ERR_NOT_DIRECTORY          = 9;



@interface ChromeWindowsTerminatedObserver : NSObject
- (void)appTerminated:(NSNotification *)note;
- (void)timeoutTimer:(NSTimer*)timer;
@end

/**
 * Class for implementing native calls from Brackets JavaScript code to native windows functionality
 */
class BracketsExtensionHandler : public CefV8Handler
{
public:
    BracketsExtensionHandler() : lastError(0), m_chromeTerminateObserver(nil), m_closeLiveBrowserTimeoutTimer(nil) {
        s_instance = this;
    }
    
    virtual ~BracketsExtensionHandler() {
        CloseLiveBrowserKillTimers();        
        s_instance = nil;
    }
    
    // Execute with the specified argument list and return value.  Return true if
    // the method was handled.
    virtual bool Execute(const CefString& name,
                         CefRefPtr<CefV8Value> object,
                         const CefV8ValueList& arguments,
                         CefRefPtr<CefV8Value>& retval,
                         CefString& exception)
    {
        int errorCode = -1;
        
        if (name == "OpenLiveBrowser")
        {
            // OpenLiveBrowser(url)
            //
            // Inputs:
            //  url - url of the document or website to open
            //
            // Error:
            //  NO_ERROR
            //  ERR_INVALID_PARAMS - invalid parameters
            //  ERR_UNKNOWN - unable to launch the browser
            
            errorCode = OpenLiveBrowser(arguments, retval, exception);
        }
        else if (name == "CloseLiveBrowser")
        {
            // CloseLiveBrowser()
            //
            // Inputs:
            //  callback - the function to callback when the window has closed or timed out
            //
            // Error:
            //  NO_ERROR - retuned by the function it means the windows where told to close, returned
            //             in the callback it means the windows are closed
            //  ERR_INVALID_PARAMS - invalid parameters (the callback is either null or must be a function)
            //  ERR_UNKNOWN - the timeout expired without the windows closing
            
            errorCode = CloseLiveBrowser(arguments, retval, exception);
        }
        else if (name == "ShowOpenDialog") 
        {
            // showOpenDialog(allowMultipleSelection, chooseDirectory, title, initialPath, fileTypes)
            //
            // Inputs:
            //  allowMultipleSelection - Boolean
            //  chooseDirectory - Boolean. Choose directory if true, choose file if false
            //  title - title of the dialog
            //  initialPath - initial path to display. Pass "" to show default.
            //  fileTypes - space-delimited string of file extensions, without '.' Pass null to show all file types
            //
            // Output:
            //  "" if no file/directory was selected
            //  JSON-formatted array of full path names if one or more files were selected
            //
            // Error:
            //  NO_ERROR
            //  ERR_INVALID_PARAMS - invalid parameters
            
            errorCode = ExecuteShowOpenDialog(arguments, retval, exception);
        }
        else if (name == "ReadDir")
        {
            // ReadDir(path)
            //
            // Inputs:
            //  path - full path of directory to be read
            //
            // Outputs:
            //  JSON-formatted array of the names of the files in the directory, not including '.' and '..'.
            //
            // Error:
            //   NO_ERROR - no error
            //   ERR_UNKNOWN - unknown error
            //   ERR_INVALID_PARAMS - invalid parameters
            //   ERR_NOT_FOUND - directory could not be found
            //   ERR_CANT_READ - could not read directory
            
            errorCode = ExecuteReadDir(arguments, retval, exception);
        }
        else if (name == "IsDirectory")
        {
            // IsDirectory(path)
            //
            // Inputs:
            //  path - full path of directory to test
            //
            // Outputs:
            //  true if path is a directory, false if error or it is a file
            //
            // Error:
            //  NO_ERROR - no error
            //  ERR_INVALID_PARAMS - invalid parameters
            //  ERR_NOT_FOUND - file/directory could not be found
            
            errorCode = ExecuteIsDirectory(arguments, retval, exception);
        }
        else if (name == "ReadFile")
        {
            // ReadFile(path, encoding)
            //
            // Inputs:
            //  path - full path of file to read
            //  encoding - 'utf8' is the only supported format for now
            //
            // Output:
            //  String - contents of the file
            //
            // Error:
            //  NO_ERROR - no error
            //  ERR_UNKNOWN - unknown error
            //  ERR_INVALID_PARAMS - invalid parameters
            //  ERR_NOT_FOUND - file could not be found
            //  ERR_CANT_READ - file could not be read
            //  ERR_UNSUPPORTED_ENCODING - unsupported encoding value 
            
            errorCode = ExecuteReadFile(arguments, retval, exception);
        }
        else if (name == "WriteFile")
        {
            // WriteFile(path, data, encoding)
            //
            // Inputs:
            //  path - full path of file to write
            //  data - data to write to file
            //  encoding - 'utf8' is the only supported format for now
            //
            // Output:
            //  none
            //
            // Error:
            //  NO_ERROR - no error
            //  ERR_UNKNOWN - unknown error
            //  ERR_INVALID_PARAMS - invalid parameters
            //  ERR_UNSUPPORTED_ENCODING - unsupported encoding value
            //  ERR_CANT_WRITE - file could not be written
            //  ERR_OUT_OF_SPACE - no more space for file
            
            errorCode = ExecuteWriteFile(arguments, retval, exception);
        }
        else if (name == "SetPosixPermissions")
        {
            // SetPosixPermissions(path, mode)
            //
            // Inputs:
            //  path - full path of file or directory
            //  mode - permissions for file or directory, in numeric format
            //
            // Output:
            //  none
            //
            // Errors
            //  NO_ERROR - no error
            //  ERR_UNKNOWN - unknown error
            //  ERR_INVALID_PARAMS - invalid parameters
            //  ERR_NOT_FOUND - can't file file/directory
            //  ERR_UNSUPPORTED_ENCODING - unsupported encoding value
            //  ERR_CANT_WRITE - permissions could not be written
            
            errorCode = ExecuteSetPosixPermissions(arguments, retval, exception);
            
        }
        else if ( name == "GetFileModificationTime")
        {
            // Returns the time stamp for a file or directory
            // 
            // Inputs:
            //  path - full path of file or directory
            //
            // Outputs:
            // Date - timestamp of file
            // 
            // Possible error values:
            //    NO_ERROR
            //    ERR_UNKNOWN
            //    ERR_INVALID_PARAMS
            //    ERR_NOT_FOUND
            
            errorCode = ExecuteGetFileModificationTime( arguments, retval, exception);
        }
        else if (name == "DeleteFileOrDirectory")
        {
            // DeleteFileOrDirectory(path)
            //
            // Inputs:
            //  path - full path of file or directory
            //
            // Ouput:
            //  none
            //
            // Errors
            //  NO_ERROR - no error
            //  ERR_UNKNOWN - unknown error
            //  ERR_INVALID_PARAMS - invalid parameters
            //  ERR_NOT_FOUND - can't file file/directory
            
            errorCode = ExecuteDeleteFileOrDirectory(arguments, retval, exception);
        }
        else if (name == "QuitApplication")
        {
            // QuitApplication
            //
            // Inputs: none
            // Output: none
            errorCode = ExecuteQuitApplication(arguments, retval, exception);
        }
        else if (name == "ShowDeveloperTools")
        {
            errorCode = ExecuteShowDeveloperTools(arguments, retval, exception);
        }
        else if (name == "GetElapsedMilliseconds")
        {
            // Get
            //
            // Inputs: 
            //  none
            // Output: 
            //  Number of milliseconds that have elapsed since the application
            //  was launched.
            errorCode = ExecuteGetElapsedMilliseconds(arguments, retval, exception); 
        }
        else if (name == "GetLastError")
        {
            // Special case private native function to return the last error code.
            retval = CefV8Value::CreateInt(lastError);
            
            // Early exit since we are just returning the last error code
            return true;
        }
        
        if (errorCode != -1) 
        {
            lastError = errorCode;
            return true;
        }
        
        return false;
    }
    
    int OpenLiveBrowser(const CefV8ValueList& args,
                              CefRefPtr<CefV8Value>& retval,
                              CefString& exception)
    {
        // Parse the arguments
        if (args.size() != 1 || !args[0]->IsString())
            return ERR_INVALID_PARAMS;
        std::string argURL = args[0]->GetStringValue();
        NSString *urlString = [NSString stringWithUTF8String:argURL.c_str()];
        NSURL *url = [NSURL URLWithString:urlString];
        
        // Find instances of the Browser
        NSString *appId = @"com.google.Chrome";
        NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:appId];
        NSWorkspace * ws = [NSWorkspace sharedWorkspace];
        NSUInteger launchOptions = NSWorkspaceLaunchDefault | NSWorkspaceLaunchWithoutActivation;

        // Launch Browser
        if(apps.count == 0) {
            
            // Create the configuration dictionary for launching with custom parameters.
            NSArray *parameters = [NSArray arrayWithObjects:
                                   @"--remote-debugging-port=9222", 
                                   @"--allow-file-access-from-files",
                                   urlString,
                                   nil];
            NSMutableDictionary* appConfig = [NSDictionary dictionaryWithObject:parameters forKey:NSWorkspaceLaunchConfigurationArguments];

            NSURL *appURL = [ws URLForApplicationWithBundleIdentifier:appId];
            if( !appURL ) {
                return ERR_NOT_FOUND; //Chrome not installed
            }
            NSError *error = nil;
            if( ![ws launchApplicationAtURL:appURL options:launchOptions configuration:appConfig error:&error] ) {
                return ERR_UNKNOWN;
            }
            return NO_ERROR;
        }
        
        // Tell the Browser to load the url
        [ws openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:appId options:launchOptions additionalEventParamDescriptor:nil launchIdentifiers:nil];
        
        return NO_ERROR;
    }

    bool IsChromeRunning()
    {
        NSString *appId = @"com.google.Chrome";
        NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:appId];
        for (NSUInteger i = 0; i < apps.count; i++) {
            NSRunningApplication* curApp = [apps objectAtIndex:i];
            if( curApp && !curApp.terminated ) {
                return true;
            }
        }
        return false;
    }
    
    void CloseLiveBrowserKillTimers() {
        if (m_closeLiveBrowserTimeoutTimer) {
            [m_closeLiveBrowserTimeoutTimer invalidate];
            [m_closeLiveBrowserTimeoutTimer release];
            m_closeLiveBrowserTimeoutTimer = nil;
        }
        
        if (m_chromeTerminateObserver) {
            [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:m_chromeTerminateObserver];
            [m_chromeTerminateObserver release];
            m_chromeTerminateObserver = nil;
        }
    }
    
    void CloseLiveBrowserFireCallback(int valToSend) {
        if (!m_closeLiveBrowserCallback.get() || !g_handler.get()) {
            return;
        }
        
        //kill the timers
        CloseLiveBrowserKillTimers();
        
        CefRefPtr<CefV8Context> context = g_handler->GetBrowser()->GetMainFrame()->GetV8Context();
        CefRefPtr<CefV8Value> objectForThis = context->GetGlobal();
        CefV8ValueList args;
        args.push_back( CefV8Value::CreateInt( valToSend ) );
        CefRefPtr<CefV8Value> r;
        CefRefPtr<CefV8Exception> e;
        
        m_closeLiveBrowserCallback->ExecuteFunctionWithContext( context , objectForThis, args, r, e, false );
        
        m_closeLiveBrowserCallback = NULL;
    }
  
    static void CheckForChromeRunning()
    {
        if( !s_instance ) {
            return;
        }
        
        if( s_instance->IsChromeRunning() ) {
            return;
        }
        
        s_instance->CloseLiveBrowserFireCallback(NO_ERROR);
    }
    
    static void CheckForChromeRunningTimeout()
    {
        if( !s_instance ) {
            return;
        }
        
        int retVal = (s_instance->IsChromeRunning() ? ERR_UNKNOWN : NO_ERROR);
        //notify back to the app
        s_instance->CloseLiveBrowserFireCallback(retVal);
    }
  
    int CloseLiveBrowser(const CefV8ValueList& args,
                      CefRefPtr<CefV8Value>& retval,
                      CefString& exception)
    {
        // Reset timeout timer
        CloseLiveBrowserKillTimers();
        
        //We can only handle a single async callback at a time. If there is already one that hasn't fired then
        //we kill it now and get ready for the next. 
        m_closeLiveBrowserCallback = NULL;
        
        if (args.size() > 0) {
            if( !args[0]->IsFunction() ) {
                return ERR_INVALID_PARAMS;
            }
            //Currently, brackets is mainly designed around a single main browser instance. We only support calling
            //back this function in that context. When we add support for multiple browser instances this will need
            //to update to get the correct context and track it's lifespan accordingly.
            if(!g_handler.get()) {
                return ERR_UNKNOWN;
            }
            
            if( ! g_handler->GetBrowser()->GetMainFrame()->GetV8Context()->IsSame(CefV8Context::GetCurrentContext()) ) {
                ASSERT(FALSE); //Getting called from not the main browser window.
                return ERR_UNKNOWN;
            }
            
            m_closeLiveBrowserCallback = args[0];
        }
        
        // Find instances of the Browser and terminate them
        NSString *appId = @"com.google.Chrome";
        NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:appId];
        
        //register an observer to watch for the app terminations
        if( apps.count > 0 && !m_chromeTerminateObserver ) {
            m_chromeTerminateObserver = [[ChromeWindowsTerminatedObserver alloc] init];
            
            [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:m_chromeTerminateObserver 
                    selector:@selector(appTerminated:) 
                    name:NSWorkspaceDidTerminateApplicationNotification 
                    object:nil
             ];
        }
        
        for (NSUInteger i = 0; i < apps.count; i++) {
            NSRunningApplication* curApp = [apps objectAtIndex:i];
            if( curApp && !curApp.terminated ) {
                [curApp terminate];
            }
        }
        
        //start a timeout timer
        NSTimeInterval timeoutInSeconds (apps.count == 0 ? 0.0001 : 3 * 60);
        m_closeLiveBrowserTimeoutTimer = [[NSTimer scheduledTimerWithTimeInterval:timeoutInSeconds target:m_chromeTerminateObserver selector:@selector(timeoutTimer:) userInfo:nil repeats:NO] retain];
        
        return NO_ERROR;
    }
    
    int ExecuteShowOpenDialog(const CefV8ValueList& arguments,
                               CefRefPtr<CefV8Value>& retval,
                               CefString& exception)
    {
        if (arguments.size() != 5 || !arguments[2]->IsString() || !arguments[3]->IsString() || !arguments[4]->IsString())
            return ERR_INVALID_PARAMS;
        
        // Grab the arguments
        bool allowsMultipleSelection = arguments[0]->GetBoolValue();
        bool canChooseDirectories = arguments[1]->GetBoolValue();
        bool canChooseFiles = !canChooseDirectories;
        std::string title = arguments[2]->GetStringValue();
        std::string initialPath = arguments[3]->GetStringValue();
        std::string fileTypesStr = arguments[4]->GetStringValue();
        std::string result = "";
        
        NSArray* allowedFileTypes = nil;
        
        if (fileTypesStr != "")
        {
            // fileTypesStr is a Space-delimited string
            allowedFileTypes = 
            [[NSString stringWithUTF8String:fileTypesStr.c_str()] 
             componentsSeparatedByString:@" "];
        }
        
        // Initialize the dialog
        NSOpenPanel* openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseFiles:canChooseFiles];
        [openPanel setCanChooseDirectories:canChooseDirectories];
        [openPanel setCanCreateDirectories:canChooseDirectories];
        [openPanel setAllowsMultipleSelection:allowsMultipleSelection];
        [openPanel setTitle: [NSString stringWithUTF8String:title.c_str()]];
        
        if (initialPath != "")
            [openPanel setDirectoryURL:[NSURL URLWithString:[NSString stringWithUTF8String:initialPath.c_str()]]];
        
        [openPanel setAllowedFileTypes:allowedFileTypes];
        
        if ([openPanel runModal] == NSOKButton)
        {
            NSArrayToJSONString([openPanel filenames], result);
        }
        
        retval = CefV8Value::CreateString(result);
        
        return NO_ERROR;
        
        
    }
    
    int ExecuteReadDir(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 1 || !arguments[0]->IsString())
            return ERR_INVALID_PARAMS;
        
        std::string pathStr = arguments[0]->GetStringValue();
        std::string result = "";
        NSString* path = [NSString stringWithUTF8String:pathStr.c_str()];
        NSError* error = nil;
        
        NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
        
        if (contents != nil)
        {
            NSArrayToJSONString(contents, result);
            retval = CefV8Value::CreateString(result);
            return NO_ERROR; 
        }
        
        return ConvertNSErrorCode(error, true);
    }
    
    int ExecuteIsDirectory(const CefV8ValueList& arguments,
                            CefRefPtr<CefV8Value>& retval,
                            CefString& exception)
    {
        if (arguments.size() != 1 || !arguments[0]->IsString())
            return ERR_INVALID_PARAMS;
        
        std::string pathStr = arguments[0]->GetStringValue();
        NSString* path = [NSString stringWithUTF8String:pathStr.c_str()];
        BOOL isDirectory;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
        {
            retval = CefV8Value::CreateBool(isDirectory);
            return NO_ERROR;
        }
        
        return ERR_NOT_FOUND;
    }
    
    int ExecuteReadFile(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 2 || !arguments[0]->IsString() || !arguments[1]->IsString())
            return ERR_INVALID_PARAMS;

        std::string pathStr = arguments[0]->GetStringValue();
        std::string encodingStr = arguments[1]->GetStringValue();
        NSString* path = [NSString stringWithUTF8String:pathStr.c_str()];
        
        NSStringEncoding encoding;
        NSError* error = nil;
        
        if (encodingStr == "utf8")
            encoding = NSUTF8StringEncoding;
        else
            return ERR_UNSUPPORTED_ENCODING; 
        
        NSString* contents = [NSString stringWithContentsOfFile:path encoding:encoding error:&error];
        
        if (contents) 
        {
            retval = CefV8Value::CreateString([contents UTF8String]);
            return NO_ERROR;
        }
        
        return ConvertNSErrorCode(error, true);
    }
    
    int ExecuteWriteFile(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 3 || !arguments[0]->IsString() || !arguments[1]->IsString() || !arguments[2]->IsString())
            return ERR_INVALID_PARAMS;

        std::string pathStr = arguments[0]->GetStringValue();
        std::string contentsStr = arguments[1]->GetStringValue();
        std::string encodingStr = arguments[2]->GetStringValue();
        
        NSString* path = [NSString stringWithUTF8String:pathStr.c_str()];
        NSString* contents = [NSString stringWithUTF8String:contentsStr.c_str()];
        NSStringEncoding encoding;
        NSError* error = nil;
        
        if (encodingStr == "utf8")
            encoding = NSUTF8StringEncoding;
        else
            return ERR_UNSUPPORTED_ENCODING;
        
        const NSData* encodedContents = [ contents dataUsingEncoding:encoding ];
        NSUInteger len = [ encodedContents length ];
        NSOutputStream* oStream = [NSOutputStream outputStreamToFileAtPath:path append:NO ];
        
        [ oStream open ];
        NSInteger res = [ oStream write:(const uint8_t*)[encodedContents bytes] maxLength:len];
        [ oStream close ];
        
        if (res == -1) {
            error = [ oStream streamError ];
        }        
        return ConvertNSErrorCode(error, false);
    }
    
    int ExecuteGetFileModificationTime(const CefV8ValueList& arguments,
                                       CefRefPtr<CefV8Value>& retval,
                                       CefString& exception)
    {
        if (arguments.size() != 1 || !arguments[0]->IsString())
            return ERR_INVALID_PARAMS;
        
        std::string pathStr = arguments[0]->GetStringValue();
        NSString* path = [NSString stringWithUTF8String:pathStr.c_str()];
        
        NSError* error = nil;
        NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        NSDate *modDate = [fileAttribs valueForKey:NSFileModificationDate];
        retval = CefV8Value::CreateDate(CefTime([modDate timeIntervalSince1970]));
        
        return ConvertNSErrorCode(error, true);
    }
    
    int ExecuteSetPosixPermissions(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 2 || !arguments[0]->IsString() || !arguments[1]->IsInt())
            return ERR_INVALID_PARAMS;
        
        std::string pathStr = arguments[0]->GetStringValue();
        int mode = arguments[1]->GetIntValue();
        NSError* error = nil;
        
        NSString* path = [NSString stringWithUTF8String:pathStr.c_str()];
        NSDictionary* attrs = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:mode] forKey:NSFilePosixPermissions];
        
        if ([[NSFileManager defaultManager] setAttributes:attrs ofItemAtPath:path error:&error])
            return NO_ERROR;
        
        return ConvertNSErrorCode(error, false);
    }
    
    int ExecuteDeleteFileOrDirectory(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 1 || !arguments[0]->IsString())
            return ERR_INVALID_PARAMS;
        
        std::string pathStr = arguments[0]->GetStringValue();
        NSError* error = nil;
        
        NSString* path = [NSString stringWithUTF8String:pathStr.c_str()];
        
        if ([[NSFileManager defaultManager] removeItemAtPath:path error:&error])
            return NO_ERROR;
        
        return ConvertNSErrorCode(error, false);
    }
  
    int ExecuteQuitApplication(const CefV8ValueList& arguments,
                               CefRefPtr<CefV8Value>& retval,
                               CefString& exception)
    {
      if (g_handler.get()) {
        if( !g_handler->DispatchQuitToAllBrowsers() ) {
          return NO_ERROR;
        }
      }
      
      CefQuitMessageLoop();
      [NSApp stop:nil];
      return NO_ERROR;
    }

    int ExecuteShowDeveloperTools(const CefV8ValueList& arguments,
                                  CefRefPtr<CefV8Value>& retval,
                                  CefString& exception)
    {
        if (g_handler.get()) {
            g_handler->GetBrowser()->ShowDevTools();
        }

        return NO_ERROR;
    }

    int ExecuteGetElapsedMilliseconds(const CefV8ValueList& arguments,
                               CefRefPtr<CefV8Value>& retval,
                               CefString& exception)
    {
        CFAbsoluteTime elapsed = CFAbsoluteTimeGetCurrent() - g_appStartupTime;
        
        retval = CefV8Value::CreateDouble(round(elapsed * 1000));
        return NO_ERROR;
    }

    // Escapes characters that have special meaning in JSON
    void EscapeJSONString(const std::string& str, std::string& result) {
        result = "";
        
        for(size_t pos = 0; pos != str.size(); ++pos) {
                switch(str[pos]) {
                    case '\a':  result.append("\\a");   break;
                    case '\b':  result.append("\\b");   break;
                    case '\f':  result.append("\\f");   break;
                    case '\n':  result.append("\\n");   break;
                    case '\r':  result.append("\\r");   break;
                    case '\t':  result.append("\\t");   break;
                    case '\v':  result.append("\\v");   break;
                    // Note: single quotes are OK for JSON
                    case '\"':  result.append("\\\"");  break; // double quote
                    case '\\':  result.append("\\\\");  break; // backslash
                        
                        
                default:   result.append( 1, str[pos]); break;
                        
            }
        }
    }

    
    void NSArrayToJSONString(NSArray* array, std::string& result)
    {        
        int numItems = [array count];
        std::string escapedStr = "";
        
        result = "[";
        std::string item;
        for (int i = 0; i < numItems; i++)
        {
            result += "\"";
            
            item = [[array objectAtIndex:i] UTF8String];
            EscapeJSONString(item, escapedStr);
            
            result += escapedStr + "\"";
            
            if (i < numItems - 1)
                result += ", ";
        }
        result += "]";
    }
    
    int ConvertNSErrorCode(NSError* error, bool isReading)
    {
        if (!error)
            return NO_ERROR;
        
        if( [[error domain] isEqualToString: NSPOSIXErrorDomain] )
        {
            switch ([error code]) 
            {
                case ENOENT:
                    return ERR_NOT_FOUND;
                    break;
                case EPERM:
                case EACCES:
                    return (isReading ? ERR_CANT_READ : ERR_CANT_WRITE);
                    break;
                case EROFS:
                    return ERR_CANT_WRITE;
                    break;
                case ENOSPC:
                    return ERR_OUT_OF_SPACE;
                    break;
            }
            
        }
        
            
        switch ([error code]) 
        {
            case NSFileNoSuchFileError:
            case NSFileReadNoSuchFileError:
                return ERR_NOT_FOUND;
                break;
            case NSFileReadNoPermissionError:
                return ERR_CANT_READ;
                break;
            case NSFileReadInapplicableStringEncodingError:
                return ERR_UNSUPPORTED_ENCODING;
                break;
            case NSFileWriteNoPermissionError:
                return ERR_CANT_WRITE;
                break;
            case NSFileWriteOutOfSpaceError:
                return ERR_OUT_OF_SPACE;
                break;
        }
        
        // Unknown error
        return ERR_UNKNOWN;
    }
    
private:
    int lastError;
    ChromeWindowsTerminatedObserver* m_chromeTerminateObserver;
    NSTimer* m_closeLiveBrowserTimeoutTimer;
    CefRefPtr<CefV8Value> m_closeLiveBrowserCallback;
    static BracketsExtensionHandler* s_instance;
    IMPLEMENT_REFCOUNTING(BracketsExtensionHandler);
};

BracketsExtensionHandler* BracketsExtensionHandler::s_instance = nil;


void InitBracketsExtensions()
{
    // Register a V8 extension with JavaScript code that calls native
    // methods implemented in BracketsExtensionHandler.
    
    // The JavaScript code for the extension lives in Resources/brackets_extensions.js
    
    NSString* sourcePath = [[NSBundle mainBundle] pathForResource:@"brackets_extensions" ofType:@"js"];
    NSString* jsSource = [[NSString alloc] initWithContentsOfFile:sourcePath encoding:NSUTF8StringEncoding error:nil];
    
    CefRegisterExtension("brackets", [jsSource UTF8String], new BracketsExtensionHandler());
    
    [jsSource release];
}


@implementation ChromeWindowsTerminatedObserver

- (void) appTerminated:(NSNotification *)note
{
    BracketsExtensionHandler::CheckForChromeRunning();
}

- (void) timeoutTimer:(NSTimer*)timer
{
    BracketsExtensionHandler::CheckForChromeRunningTimeout();
}

@end

//Simple stack class to ensure calls to Enter and Exit are balanced
class StContextScope {
public:
    StContextScope( const CefRefPtr<CefV8Context>& ctx )
    : m_ctx(NULL) {
        if( ctx && ctx->Enter() ) {
            m_ctx = ctx;
        }
    }
  
    ~StContextScope() {
        if(m_ctx) {
            m_ctx->Exit();
        }
    }
  
    const CefRefPtr<CefV8Context>& GetContext() const { 
        return m_ctx;
    }
  
private:
    CefRefPtr<CefV8Context> m_ctx;
  
};

/**
 * Class for implementing native calls from native windows functionality to Brackets JavaScript code
 */
bool BracketsShellAPI::DispatchQuitToBracketsJS(const CefRefPtr<CefBrowser>& browser)
{
	return DispatchBracketsJSCommand(browser, FILE_QUIT);
}

bool BracketsShellAPI::DispatchCloseToBracketsJS(const CefRefPtr<CefBrowser>& browser)
{
	return DispatchBracketsJSCommand(browser, FILE_CLOSE_WINDOW);
}

bool BracketsShellAPI::DispatchReloadToBracketsJS(const CefRefPtr<CefBrowser>& browser)
{
	return DispatchBracketsJSCommand(browser, FILE_RELOAD);
}

/**
 * Event constants for TriggerBracketsJSEvent
 * These constants should be kept in sync with Commands.js
 */
const std::string BracketsShellAPI::FILE_QUIT = "file.quit";
const std::string BracketsShellAPI::FILE_CLOSE_WINDOW = "file.close_window";
const std::string BracketsShellAPI::FILE_RELOAD = "debug.refreshWindow";




/**
 * Provides a mechanism to execute Brackets JavaScript commands from native code. This function will
 * call CommandManager.execute(commandName) in JavaScript. 
 * The bool return is the same as the W3 dispatchEvent:
 * The return value of dispatchEvent indicates whether any of the listeners 
 * which handled the event called preventDefault. If preventDefault was called 
 * the value is false, else the value is true.
 */
bool BracketsShellAPI::DispatchBracketsJSCommand(const CefRefPtr<CefBrowser>& browser, BracketsCommandName &command){
	CefRefPtr<CefFrame> frame = browser->GetMainFrame();  
	StContextScope ctx( frame->GetV8Context() );
	if( !ctx.GetContext() ) {
		return true;
	}

	CefRefPtr<CefV8Value> win = ctx.GetContext()->GetGlobal();

	if( !win->HasValue("brackets") ) {
		return true;
	}

	CefRefPtr<CefV8Value> brackets = win->GetValue("brackets");
	if( !brackets ) {
		return true;
	}

	if( !brackets->HasValue("shellAPI") ) {
		return true;
	}

	CefRefPtr<CefV8Value> shellAPI = brackets->GetValue("shellAPI");
	if( !shellAPI ) {
		return true;
	}

	if( !shellAPI->HasValue("executeCommand") ) {
		return true;
	}

	CefRefPtr<CefV8Value> executeCommand = shellAPI->GetValue("executeCommand");
	if( !executeCommand ) {
		return true;
	}

	if( !executeCommand->IsFunction() ) {
		return true;
	}

	CefV8ValueList args;
	args.push_back( CefV8Value::CreateString(command) );
	CefRefPtr<CefV8Value> retval;
	CefRefPtr<CefV8Exception> e;
	bool called = executeCommand->ExecuteFunction(brackets, args, retval, e, false);

	if( !called ) {
		return true; //if we didn't 
	}

	bool preventDefault = false;
	if(called && retval && retval->IsBool() ) {
		preventDefault = retval->GetBoolValue();
	}

	//Return whether we should do the default action or not (this function defaults to the caller should do the default)
	return (!preventDefault);
}
