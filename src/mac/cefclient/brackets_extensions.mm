#include "brackets_extensions.h"

#import <Cocoa/Cocoa.h>

#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>

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

class BracketsExtensionHandler : public CefV8Handler
{
public:
    BracketsExtensionHandler() : lastError(0) {}
    virtual ~BracketsExtensionHandler() {}
    
    // Execute with the specified argument list and return value.  Return true if
    // the method was handled.
    virtual bool Execute(const CefString& name,
                         CefRefPtr<CefV8Value> object,
                         const CefV8ValueList& arguments,
                         CefRefPtr<CefV8Value>& retval,
                         CefString& exception)
    {        
        int errorCode = -1;
        
        if (name == "ShowOpenDialog") 
        {
            // showOpenDialog(allowMultipleSelection, chooseDirectory, title, initialPath, fileTypes)
            //
            // Inputs:
            //  allowMultipleSelection - Boolean
            //  chooseDirectory - Boolean. Choose directory if true, choose file if false
            //  title - title of the dialog
            //  initialPath - initial path to display. Pass "" to show default.
            //  fileTypes - space-delimited string of file extensions, without '.'
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
            //  ERR_UNSUPPORTED_ENCODING - unsupported encoding value
            //  ERR_CANT_WRITE - permissions could not be written
            
            errorCode = ExecuteSetPosixPermissions(arguments, retval, exception);
            
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
        
        return ConvertNSErrorCode(error);
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
        
        return ConvertNSErrorCode(error);
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
            
        [contents writeToFile:path atomically:YES encoding:encoding error:&error];
        
        return ConvertNSErrorCode(error);
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
        
        return ConvertNSErrorCode(error);
    }
    
    void NSArrayToJSONString(NSArray* array, std::string& result)
    {
        int numItems = [array count];
        
        result = "[";
        for (int i = 0; i < numItems; i++)
        {
            result += "\"";
            result += [[array objectAtIndex:i] UTF8String];
            result += "\"";
            
            if (i < numItems - 1)
                result += ", ";
        }
        result += "]";
    }
    
    int ConvertNSErrorCode(NSError* error)
    {
        if (!error)
            return NO_ERROR;
            
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
    IMPLEMENT_REFCOUNTING(BracketsExtensionHandler);
};


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
