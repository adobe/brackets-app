#include "brackets_extensions.h"

#import <Cocoa/Cocoa.h>

#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>

class BracketsExtensionHandler : public CefV8Handler
{
public:
    BracketsExtensionHandler() {}
    virtual ~BracketsExtensionHandler() {}
    
    // Execute with the specified argument list and return value.  Return true if
    // the method was handled.
    virtual bool Execute(const CefString& name,
                         CefRefPtr<CefV8Value> object,
                         const CefV8ValueList& arguments,
                         CefRefPtr<CefV8Value>& retval,
                         CefString& exception)
    {
        if (name == "GetDirectoryListing")
        {
            if (arguments.size() != 1 || !arguments[0]->IsString())
                return false;
            
            std::string dirname = arguments[0]->GetStringValue();
            std::string listing = "[";
            
            DIR *dp = ::opendir(dirname.c_str());
            if (dp)
            {
                struct dirent *ep;
                while ((ep = readdir(dp)))
                {
                    listing += "\"";
                    listing += ep->d_name;
                    listing += "\",";
                }
                (void)::closedir(dp);
            }
            
            // Remove final comma
            listing.resize(listing.size() - 1);
            
            listing += "]";
            
            retval = CefV8Value::CreateString(listing);
            
            return retval;
        } 
        else if (name == "IsDirectory")
        {
            if (arguments.size() != 1 || !arguments[0]->IsString())
                return false;
            
            std::string dirname = arguments[0]->GetStringValue();
            bool isDir = false;
            
            DIR *dp = ::opendir(dirname.c_str());
            if (dp)
            {
                isDir = true;
                (void)::closedir(dp);
            }
            
            retval = CefV8Value::CreateBool(isDir);
            return retval;
        }
        else if (name == "ReadFileIntoString")
        {
            if (arguments.size() != 1 || !arguments[0]->IsString())
                return false;
            
            std::string filename = arguments[0]->GetStringValue();
            std::string contents = "";
            
            FILE *fp = ::fopen(filename.c_str(), "r");
            
            if (fp)
            {
                char buffer[4096];  // Hard-coded 4k buffer
                
                while (!::feof(fp))
                {
                    if (::fgets(buffer, 4096, fp) != NULL)
                        contents += buffer;
                }
                ::fclose(fp);
            }
            
            retval = CefV8Value::CreateString(contents);
            return retval;
        }
        else if (name == "SaveStringIntoFile")
        {
            if (arguments.size() != 2 || !arguments[0]->IsString() || !arguments[1]->IsString())
                return false;
            
            std::string filename = arguments[0]->GetStringValue();
            std::string contents = arguments[1]->GetStringValue();
            
            FILE *fp = ::fopen(filename.c_str(), "w");
            
            if (fp)
            {
                ::fputs(contents.c_str(), fp);
                ::fclose(fp);
            }
        }
        else if (name == "ShowOpenPanel")
        {
            if (arguments.size() != 3 || !arguments[2]->IsString())
                return false;
            
            bool canChooseFiles = arguments[0]->GetBoolValue();
            bool canChooseDirectories = arguments[1]->GetBoolValue();
            std::string title = arguments[2]->GetStringValue();
            std::string result = "";
            
            NSOpenPanel* openDlog = [NSOpenPanel openPanel];
            
            [openDlog setCanChooseFiles: canChooseFiles];
            [openDlog setCanChooseDirectories: canChooseDirectories];
            [openDlog setTitle: [NSString stringWithUTF8String:title.c_str()]];
            
            if ([openDlog runModal] == NSOKButton)
            {
                result = [[[openDlog filenames] objectAtIndex:0] UTF8String];
            }
                        
            retval = CefV8Value::CreateString(result);
            
            return retval;
        } 
        else if (name == "ShowOpenDialog") 
        {
            if (arguments.size() != 5 || !arguments[2]->IsString())
                return false;
            
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
                NSArray* filenames = [openPanel filenames];
                int numFiles = [filenames count];
                
                result = "[";
                for (int i = 0; i < numFiles; i++)
                {
                    result += "\"";
                    result += [[filenames objectAtIndex:i] UTF8String];
                    result += "\"";
                    
                    if (i < numFiles - 1)
                        result += ", ";
                }
                result += "]";
            }
            
            retval = CefV8Value::CreateString(result);
            
            return retval;
        }
        
        return false;
    }
    
private:
    IMPLEMENT_REFCOUNTING(BracketsExtensionHandler);
};


void InitBracketsExtensions()
{
    // Register a V8 extension with the below JavaScript code that calls native
    // methods implemented in BracketsExtensionHandler.

    std::string code = "var brackets;"
    "if (!brackets)"
    "   brackets = {};"
    "if (!brackets.file)"
    "   brackets.file = {};"
    "(function() {"
    "   brackets.file.getDirectoryListing = function(dir) {"
    "       native function GetDirectoryListing();"
    "       return GetDirectoryListing(dir);"
    "   };"
    "   brackets.file.isDirectory = function(dir) {"
    "       native function IsDirectory();"
    "       return IsDirectory(dir);"
    "   };"
    "   brackets.file.readFile = function(fname) {"
    "       native function ReadFileIntoString();"
    "       return ReadFileIntoString(fname);"
    "   };"
    "   brackets.file.saveFile = function(fname, contents) {"
    "       native function SaveStringIntoFile();"
    "       return SaveStringIntoFile(fname, contents);"
    "   };"
    "   brackets.file.showOpenPanel = function(canChooseFiles, canChooseDirectories, title) {"
    "       native function ShowOpenPanel();"
    "       return ShowOpenPanel(canChooseFiles, canChooseDirectories, title);"
    "   };"
    "   brackets.file.showOpenDialog = function(allowMultipleSelection, chooseDirectory, title, initialPath, fileTypes, callback) {"
    "       native function ShowOpenDialog();"
    "       var resultString = ShowOpenDialog(allowMultipleSelection, chooseDirectory, "
    "                                         title || 'Open', initialPath || '', "
    "                                         fileTypes ? fileTypes.join(' ') : '');"
    "       var result = JSON.parse(resultString || '[]');"
    "       callback(result);"
    "   };"
    "})();";
    
    CefRegisterExtension("brackets", code, new BracketsExtensionHandler());
}
