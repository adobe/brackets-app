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
#include "Resource.h"
#include "client_handler.h"

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <CommDlg.h>
#include <ShlObj.h>
#include <Shlwapi.h>
#include <wchar.h>
#include <algorithm>
#include <list>
#include <MMSystem.h>
#include <Psapi.h>

extern CefRefPtr<ClientHandler> g_handler;
extern DWORD g_appStartupTime;

// Error values. These MUST be in sync with the error values
// in brackets_extensions.js
//static const int NO_ERROR                   = 0;
static const int ERR_UNKNOWN                = 1;
static const int ERR_INVALID_PARAMS         = 2;
static const int ERR_NOT_FOUND              = 3;
static const int ERR_CANT_READ              = 4;
static const int ERR_UNSUPPORTED_ENCODING   = 5;
static const int ERR_CANT_WRITE             = 6;
static const int ERR_OUT_OF_SPACE           = 7;
static const int ERR_NOT_FILE               = 8;
static const int ERR_NOT_DIRECTORY          = 9;



/**
 * Class for implementing native calls from Brackets JavaScript code to native windows functionality
 */
class BracketsExtensionHandler : public CefV8Handler
{
public:
    BracketsExtensionHandler() : lastError(0), m_closeLiveBrowserHeartbeatTimerId(0), m_closeLiveBrowserTimeoutTimerId(0) {
        ASSERT(s_instance == NULL);
        s_instance = this;
    }
    virtual ~BracketsExtensionHandler() {
        s_instance = NULL;
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
        else if ( name == "CloseLiveBrowser" )
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
            //  initialPath - initial path to display. Pass null to show all file types
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

    static std::wstring GetPathToLiveBrowser() 
    {
        // Chrome.exe is at C:\Users\{USERNAME}\AppData\Local\Google\Chrome\Application\chrome.exe
        TCHAR localAppPath[MAX_PATH] = {0};
        SHGetFolderPath(NULL, CSIDL_LOCAL_APPDATA, NULL, SHGFP_TYPE_CURRENT, localAppPath);
        std::wstring appPath(localAppPath);
        appPath += L"\\Google\\Chrome\\Application\\chrome.exe";
        
        return appPath;
    }
    
    static bool ConvertToShortPathName(std::wstring & path)
    {
        DWORD shortPathBufSize = _MAX_PATH+1;
        WCHAR shortPathBuf[_MAX_PATH+1];
        DWORD finalShortPathSize = ::GetShortPathName(path.c_str(), shortPathBuf, shortPathBufSize);
        if( finalShortPathSize == 0 ) {
            return false;
        }
        
        path.assign(shortPathBuf, finalShortPathSize);
        return true;
    }
    
    int OpenLiveBrowser(const CefV8ValueList& arguments,
                               CefRefPtr<CefV8Value>& retval,
                               CefString& exception)
    {
        // Parse the arguments
        if (arguments.size() != 2 || !arguments[0]->IsString() || !arguments[1]->IsBool())
            return ERR_INVALID_PARAMS;
        std::wstring argURL = arguments[0]->GetStringValue();
        bool enableRemoteDebugging = arguments[1]->GetBoolValue();

        std::wstring appPath = GetPathToLiveBrowser();

        //When launching the app, we need to be careful about spaces in the path. A safe way to do this
        //is to use the shortpath. It doesn't look as nice, but it always works and never has a space
        if( !ConvertToShortPathName(appPath) ) {
            //If the shortpath failed, we need to bail since we don't know what to call now
            return ConvertWinErrorCode(GetLastError());
        }


        std::wstring args = appPath;
        if (enableRemoteDebugging)
            args += L" --remote-debugging-port=9222 --allow-file-access-from-files ";
        else
            args += L" ";
        args += argURL;

        // Args must be mutable
        int argsBufSize = args.length() +1;
        std::auto_ptr<WCHAR> argsBuf( new WCHAR[argsBufSize]);
        wcscpy(argsBuf.get(), args.c_str());

        STARTUPINFO si = {0};
        si.cb = sizeof(si);
        PROCESS_INFORMATION pi = {0};

        //Send the whole command in through the args param. Windows will parse the first token up to a space
        //as the processes and feed the rest in as the argument string. 
        if (!CreateProcess(NULL, argsBuf.get(), NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
            return ConvertWinErrorCode(GetLastError());
        }
        
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);

        return NO_ERROR;
    }

    static bool IsChromeWindow(HWND hwnd)
    {
        if( !hwnd ) {
            return false;
        }

        //Find the path that opened this window
        DWORD processId = 0;
        ::GetWindowThreadProcessId(hwnd, &processId);

        HANDLE processHandle = ::OpenProcess( PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, processId);
        if( !processHandle ) { 
            return false;
        }

        DWORD modulePathBufSize = _MAX_PATH+1;
        WCHAR modulePathBuf[_MAX_PATH+1];
        DWORD modulePathSize = ::GetModuleFileNameEx(processHandle, NULL, modulePathBuf, modulePathBufSize );
        ::CloseHandle(processHandle);
        processHandle = NULL;

        std::wstring modulePath(modulePathBuf, modulePathSize);

        //See if this path is the same as what we want to launch
        std::wstring appPath = GetPathToLiveBrowser();

        if( !ConvertToShortPathName(modulePath) || !ConvertToShortPathName(appPath) ) {
            return false;
        }

        if(0 != _wcsicmp(appPath.c_str(), modulePath.c_str()) ){
            return false;
        }

        //looks good
        return true;
    }

    struct EnumChromeWindowsCallbackData {
        bool    closeWindow;
        int     numberOfFoundWindows;
    };

    static BOOL CALLBACK EnumChromeWindowsCallback(HWND hwnd, LPARAM userParam)
    {
        if( !hwnd ) {
            return FALSE;
        }

        EnumChromeWindowsCallbackData* cbData = reinterpret_cast<EnumChromeWindowsCallbackData*>(userParam);
        if(!cbData) {
            return FALSE;
        }

        if (!IsChromeWindow(hwnd)) {
            return TRUE;
        }

        cbData->numberOfFoundWindows++;
        //This window belongs to the instance of the browser we're interested in, tell it to close
        if( cbData->closeWindow ) {
            ::SendMessageCallback(hwnd, WM_CLOSE, NULL, NULL, CloseLiveBrowserAsyncCallback, NULL);
        }

        return TRUE;
    }

    static bool IsAnyChromeWindowsRunning() {
        EnumChromeWindowsCallbackData cbData = {0};
        cbData.numberOfFoundWindows = 0;
        cbData.closeWindow = false;
        ::EnumWindows(EnumChromeWindowsCallback, (LPARAM)&cbData);
        return( cbData.numberOfFoundWindows != 0 );
    }

    void CloseLiveBrowserKillTimers()
    {
        if (m_closeLiveBrowserHeartbeatTimerId) {
            ::KillTimer(NULL, m_closeLiveBrowserHeartbeatTimerId);
            m_closeLiveBrowserHeartbeatTimerId = 0;
        }

        if (m_closeLiveBrowserTimeoutTimerId) {
            ::KillTimer(NULL, m_closeLiveBrowserTimeoutTimerId);
            m_closeLiveBrowserTimeoutTimerId = 0;
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

    static void CALLBACK CloseLiveBrowserTimerCallback( HWND hwnd, UINT uMsg, UINT idEvent, DWORD dwTime)
    {        
        if( !s_instance ) {
            ::KillTimer(NULL, idEvent);
            return;
        }

        int retVal =  NO_ERROR;
        if( IsAnyChromeWindowsRunning() )
        {
            retVal = ERR_UNKNOWN;
            //if this is the heartbeat timer, wait for another beat
            if (idEvent == s_instance->m_closeLiveBrowserHeartbeatTimerId) {
                return;
            }
        }

        //notify back to the app
        s_instance->CloseLiveBrowserFireCallback(retVal);
    }

    static void CALLBACK CloseLiveBrowserAsyncCallback( HWND hwnd, UINT uMsg, ULONG_PTR dwData, LRESULT lResult )
    {
        if( !s_instance ) {
            return;
        }

        //If there are no more versions of chrome, then fire the callback
        if( !IsAnyChromeWindowsRunning() ) {
            s_instance->CloseLiveBrowserFireCallback(NO_ERROR);
        }
        else if(s_instance->m_closeLiveBrowserHeartbeatTimerId == 0){
            //start a heartbeat timer to see if it closes after the message returned
            s_instance->m_closeLiveBrowserHeartbeatTimerId = ::SetTimer(NULL, 0, 30, CloseLiveBrowserTimerCallback);
        }
    }

    int CloseLiveBrowser(const CefV8ValueList& arguments,
        CefRefPtr<CefV8Value>& retval,
        CefString& exception)
    {
        //We can only handle a single async callback at a time. If there is already one that hasn't fired then
        //we kill it now and get ready for the next. 
        m_closeLiveBrowserCallback = NULL;

        if (arguments.size() > 0) {
            if( !arguments[0]->IsFunction() ) {
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

            m_closeLiveBrowserCallback = arguments[0];
        }

        EnumChromeWindowsCallbackData cbData = {0};

        cbData.numberOfFoundWindows = 0;
        cbData.closeWindow = true;
        ::EnumWindows(EnumChromeWindowsCallback, (LPARAM)&cbData);

        //set a timeout for up to 3 minutes to close the browser 
        UINT timeoutInMS = (cbData.numberOfFoundWindows == 0 ? USER_TIMER_MINIMUM : 3 * 60 * 1000);

        if( m_closeLiveBrowserCallback ) {
            m_closeLiveBrowserTimeoutTimerId = ::SetTimer(NULL, 0, timeoutInMS, CloseLiveBrowserTimerCallback);
        }

         return NO_ERROR;
    }

    static int CALLBACK SetInitialPathCallback(HWND hWnd, UINT uMsg, LPARAM lParam, LPARAM lpData)
    {
        if (BFFM_INITIALIZED == uMsg && NULL != lpData)
        {
            SendMessage(hWnd, BFFM_SETSELECTION, TRUE, lpData);
        }

        return 0;
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
        std::wstring wtitle = arguments[2]->GetStringValue();
        std::wstring initialPath = arguments[3]->GetStringValue();
        std::wstring fileTypesStr = arguments[4]->GetStringValue();
        std::wstring results = L"[";

        FixFilename(initialPath);

        wchar_t szFile[MAX_PATH];
        szFile[0] = 0;

        // TODO (issue #64) - This method should be using IFileDialog instead of the
        /* outdated SHGetPathFromIDList and GetOpenFileName.
       
        Useful function to parse fileTypesStr:
        template<class T>
        int inline findAndReplaceString(T& source, const T& find, const T& replace)
        {
        int num=0;
        int fLen = find.size();
        int rLen = replace.size();
        for (int pos=0; (pos=source.find(find, pos))!=T::npos; pos+=rLen)
        {
        num++;
        source.replace(pos, fLen, replace);
        }
        return num;
        }
        */

        if (canChooseDirectories) {
            BROWSEINFO bi = {0};
            bi.hwndOwner = GetActiveWindow();
            bi.lpszTitle = wtitle.c_str();
            bi.ulFlags = BIF_NEWDIALOGSTYLE;
            bi.lpfn = SetInitialPathCallback;
            bi.lParam = (LPARAM)initialPath.c_str();

            LPITEMIDLIST pidl = SHBrowseForFolder(&bi);
            if (pidl != 0) {
                if (SHGetPathFromIDList(pidl, szFile)) {
                    // Escape the directory path and add it to the JSON array
                    std::wstring dirPath(szFile);
                    std::wstring escaped;
                    EscapeJSONString(dirPath, escaped);
                    results += L"\"" + escaped + L"\"";
                }
                IMalloc* pMalloc = NULL;
                SHGetMalloc(&pMalloc);
                if (pMalloc) {
                    pMalloc->Free(pidl);
                    pMalloc->Release();
                }
            }
        } else {
            OPENFILENAME ofn;

            ZeroMemory(&ofn, sizeof(ofn));
            ofn.hwndOwner = GetActiveWindow();
            ofn.lStructSize = sizeof(ofn);
            ofn.lpstrFile = szFile;
            ofn.nMaxFile = MAX_PATH;

           // TODO (issue #65) - Use passed in file types. Note, when fileTypesStr is null, all files should be shown
           /* findAndReplaceString( fileTypesStr, std::string(" "), std::string(";*."));
            LPCWSTR allFilesFilter = L"All Files\0*.*\0\0";*/

             ofn.lpstrFilter = L"All Files\0*.*\0Web Files\0*.js;*.css;*.htm;*.html\0\0";
           
            ofn.lpstrInitialDir = initialPath.c_str();
            ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_EXPLORER;
            if (allowsMultipleSelection)
                ofn.Flags |= OFN_ALLOWMULTISELECT;

            if (GetOpenFileName(&ofn)) {
                if (allowsMultipleSelection) {
                    // Multiple selection encodes the files differently

                    // If multiple files are selected, the first null terminator
                    // signals end of directory that the files are all in
                    std::wstring dir(szFile);

                    // Check for two null terminators, which signal that only one file
                    // was selected
                    if (szFile[dir.length() + 1] == '\0') {
                        // Escape the single file path and add it to the JSON array
                        std::wstring escaped;
                        EscapeJSONString(dir, escaped);
                        results += L"\"" + escaped + L"\"";
                    } else {
                        // Multiple files are selected

                        wchar_t fullPath[MAX_PATH];
                        bool firstFile = true;
                        for (int i = dir.length() + 1;;) {
                            // Get the next file name
                            std::wstring file(&szFile[i]);

                            // Two adjacent null characters signal the end of the files
                            if (file.length() == 0)
                                break;

                            // The filename is relative to the directory that was specified as
                            // the first string
                            if (PathCombine(fullPath, dir.c_str(), file.c_str()) != NULL)
                            {
                                // Append a comma separator if it is not the first file in the list
                                if (firstFile)
                                    firstFile = false;
                                else
                                    results += L",";

                                // Escape the path and add it to the list
                                std::wstring escaped;
                                EscapeJSONString(std::wstring(fullPath), escaped);
                                results += L"\"" + escaped + L"\"";
                            }

                            // Go to the start of the next file name
                            i += file.length() + 1;
                        }
                    }
                } else {
                    // If multiple files are not allowed, add the single file
                    std::wstring escaped;
                    EscapeJSONString(std::wstring(szFile), escaped);
                    results += L"\"" + escaped + L"\"";
                }
            }
        }

        results += L"]";
        retval = CefV8Value::CreateString(results);

        return NO_ERROR;
    }
    
    int ExecuteReadDir(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 1 || !arguments[0]->IsString())
            return ERR_INVALID_PARAMS;
        
        std::wstring pathStr = arguments[0]->GetStringValue();
        std::wstring resultDirs;
        std::wstring resultFiles;
        bool addedOneDir = false;
        bool addedOneFile = false;

        FixFilename(pathStr);
        pathStr += L"\\*";

        WIN32_FIND_DATA ffd;
        HANDLE hFind = FindFirstFile(pathStr.c_str(), &ffd);

        if (hFind != INVALID_HANDLE_VALUE) 
        {
            do
            {
                // Ignore '.' and '..'
                if (!wcscmp(ffd.cFileName, L".") || !wcscmp(ffd.cFileName, L".."))
                    continue;

                std::wstring filename;
                EscapeJSONString(ffd.cFileName, filename);

                // Collect file and directory names separately
                if (ffd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
                {
                    if (addedOneDir)
                        resultDirs += L",";
                    else
                        addedOneDir = true;
                    resultDirs += L"\"" + filename + L"\"";
                }
                else
                {
                    if (addedOneFile)
                        resultFiles += L",";
                    else
                        addedOneFile = true;
                    resultFiles += L"\"" + filename + L"\"";
                }
            }
            while (FindNextFile(hFind, &ffd) != 0);

            FindClose(hFind);
        } 
        else {
            return ConvertWinErrorCode(GetLastError());
        }

        // On Windows, list directories first, then files
        std::wstring result = L"[";
        if (addedOneDir)
        {
            result += resultDirs;
            if (addedOneFile)
                result += L",";
        }
        if (addedOneFile)
            result += resultFiles;
        result += L"]";
        retval = CefV8Value::CreateString(result);
        return NO_ERROR;
    }
    
    int ExecuteIsDirectory(const CefV8ValueList& arguments,
                            CefRefPtr<CefV8Value>& retval,
                            CefString& exception)
    {
        if (arguments.size() != 1 || !arguments[0]->IsString())
            return ERR_INVALID_PARAMS;
        
        std::wstring pathStr = arguments[0]->GetStringValue();
        FixFilename(pathStr);

        DWORD dwAttr = GetFileAttributes(pathStr.c_str());

        if (dwAttr == INVALID_FILE_ATTRIBUTES) {
            return ConvertWinErrorCode(GetLastError()); 
        }

        retval = CefV8Value::CreateBool((dwAttr & FILE_ATTRIBUTE_DIRECTORY) != 0);
        return NO_ERROR;
    }
    
    int ExecuteReadFile(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 2 || !arguments[0]->IsString() || !arguments[1]->IsString())
            return ERR_INVALID_PARAMS;

        std::wstring pathStr = arguments[0]->GetStringValue();
        std::wstring encodingStr = arguments[1]->GetStringValue();

        if (encodingStr != L"utf8")
            return ERR_UNSUPPORTED_ENCODING;

        FixFilename(pathStr);
        
        DWORD dwAttr;
        dwAttr = GetFileAttributes(pathStr.c_str());
        if (INVALID_FILE_ATTRIBUTES == dwAttr)
            return ConvertWinErrorCode(GetLastError());

        if (dwAttr & FILE_ATTRIBUTE_DIRECTORY)
            return ERR_CANT_READ;

        HANDLE hFile = CreateFile(pathStr.c_str(), GENERIC_READ,
            0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        int error = NO_ERROR;

        if (INVALID_HANDLE_VALUE == hFile)
            return ConvertWinErrorCode(GetLastError()); 

        DWORD dwFileSize = GetFileSize(hFile, NULL);
        DWORD dwBytesRead;
        char* buffer = (char*)malloc(dwFileSize);
        if (buffer && ReadFile(hFile, buffer, dwFileSize, &dwBytesRead, NULL)) {
            std::string contents(buffer, dwFileSize);
            retval = CefV8Value::CreateString(contents.c_str());
        }
        else {
            if (!buffer)
                error = ERR_UNKNOWN;
            else
                error = ConvertWinErrorCode(GetLastError());
        }
        CloseHandle(hFile);
        if (buffer)
            free(buffer);

        return error; 
    }
    
    int ExecuteWriteFile(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 3 || !arguments[0]->IsString() || !arguments[1]->IsString() || !arguments[2]->IsString())
            return ERR_INVALID_PARAMS;

        std::wstring pathStr = arguments[0]->GetStringValue();
        std::string contentsStr = arguments[1]->GetStringValue();
        std::wstring encodingStr = arguments[2]->GetStringValue();
        FixFilename(pathStr);

        if (encodingStr != L"utf8")
            return ERR_UNSUPPORTED_ENCODING;

        HANDLE hFile = CreateFile(pathStr.c_str(), GENERIC_WRITE,
            0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        DWORD dwBytesWritten;
        int error = NO_ERROR;

        if (INVALID_HANDLE_VALUE == hFile)
            return ConvertWinErrorCode(GetLastError(), false); 

        // TODO (issue 67) -  Should write to temp file and handle encoding
        if (!WriteFile(hFile, contentsStr.c_str(), contentsStr.length(), &dwBytesWritten, NULL)) {
            error = ConvertWinErrorCode(GetLastError(), false);
        }

        CloseHandle(hFile);
        return error;
    }

  int ExecuteQuitApplication(const CefV8ValueList& arguments,
                             CefRefPtr<CefV8Value>& retval,
                             CefString& exception)
  {
    if (g_handler.get()) {
      if (!g_handler->DispatchQuitToAllBrowsers()) {
        return NO_ERROR;
      }
    }
    PostQuitMessage(0);

    return NO_ERROR;
  }

    int ExecuteShowDeveloperTools(const CefV8ValueList& arguments,
                        CefRefPtr<CefV8Value>& retval,
                        CefString& exception)
    {
        HWND hwnd = GetActiveWindow();
        if (hwnd)
        {
            PostMessage(hwnd, WM_COMMAND, ID_TESTS_DEVTOOLS_SHOW, 0);
        }

        return NO_ERROR;
    }

    int ExecuteGetFileModificationTime(const CefV8ValueList& arguments,
                                       CefRefPtr<CefV8Value>& retval,
                                       CefString& exception)
    {
        if (arguments.size() != 1 || !arguments[0]->IsString())
            return ERR_INVALID_PARAMS;

        std::wstring pathStr = arguments[0]->GetStringValue();
        FixFilename(pathStr);

    // Remove trailing "\", if present. _wstat will fail with a "file not found"
    // error if a directory has a trailing '\' in the name.
    if (pathStr[pathStr.length() - 1] == '\\')
      pathStr[pathStr.length() - 1] = 0;

        /* Alternative implementation
        WIN32_FILE_ATTRIBUTE_DATA attribData;
        GET_FILEEX_INFO_LEVELS FileInfosLevel;
        GetFileAttributesEx( pathStr.c_str(), GetFileExInfoStandard, &attribData);*/


        struct _stat buffer;
        if(_wstat(pathStr.c_str(), &buffer) == -1) {
            return ConvertErrnoCode(errno); 
        }

        retval = CefV8Value::CreateDate(buffer.st_mtime);

        return NO_ERROR;
    }
    
    int ExecuteSetPosixPermissions(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 2 || !arguments[0]->IsString() || !arguments[1]->IsInt())
            return ERR_INVALID_PARAMS;
        
        std::wstring pathStr = arguments[0]->GetStringValue();
        int mode = arguments[1]->GetIntValue();
        FixFilename(pathStr);

        // Note, Windows cannot set read-only on directories.
        // See http://support.microsoft.com/kb/326549
        DWORD dwAttr = GetFileAttributes(pathStr.c_str());
        if (dwAttr == INVALID_FILE_ATTRIBUTES) {
            return ConvertWinErrorCode(GetLastError()); 
        }
        bool isDir = (dwAttr & FILE_ATTRIBUTE_DIRECTORY) != 0;
        if(isDir) {
            return NO_ERROR;
        }

        // For now only extract permissions for "owner"
        bool write = (mode & 0200) != 0; 
        bool read = (mode & 0400) != 0;
        int mask = (write ? _S_IWRITE : 0) | (read ? _S_IREAD : 0);

        // Note _wchmod only supports setting FILE_ATTRIBUTE_READONLY so 
        // _S_IREAD is ignored.
        if (_wchmod(pathStr.c_str(), mask) == -1) {
            return ConvertErrnoCode(errno); 
        }

        return NO_ERROR;
    }
    
    int ExecuteDeleteFileOrDirectory(const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception)
    {
        if (arguments.size() != 1 || !arguments[0]->IsString())
            return ERR_INVALID_PARAMS;
        
        std::wstring pathStr = arguments[0]->GetStringValue();
        FixFilename(pathStr);

        if (!DeleteFile(pathStr.c_str()))
            return ConvertWinErrorCode(GetLastError());

        return NO_ERROR;
    }
    
    int ExecuteGetElapsedMilliseconds(const CefV8ValueList& arguments,
                               CefRefPtr<CefV8Value>& retval,
                               CefString& exception)
    {
        DWORD elapsed = timeGetTime() - g_appStartupTime;
        
        retval = CefV8Value::CreateDouble(elapsed);
        return NO_ERROR;
    }

    template<class _Elem,
    class _Traits,
    class _Ax>
    void FixFilename(std::basic_string<_Elem, _Traits, _Ax>& filename)
    {
        // Convert '/' to '\'
        std::replace_if(filename.begin(), filename.end(), std::bind2nd(std::equal_to<_Elem>(), '/'), '\\');
    }

    std::wstring StringToWString(const std::string& s)
    {
        std::wstring temp(s.length(),L' ');
        std::copy(s.begin(), s.end(), temp.begin());
        return temp;
    }

    std::string WStringToString(const std::wstring& s)
    {
        std::string temp(s.length(), ' ');
        std::copy(s.begin(), s.end(), temp.begin());
        return temp;
    }

    // Escapes characters that have special meaning in JSON
    void EscapeJSONString(const std::wstring& str, std::wstring& finalResult) {
        std::wstring result;
        
        for(size_t pos = 0; pos != str.size(); ++pos) {
            switch(str[pos]) {
                case '\a':  result.append(L"\\a");   break;
                case '\b':  result.append(L"\\b");   break;
                case '\f':  result.append(L"\\f");   break;
                case '\n':  result.append(L"\\n");   break;
                case '\r':  result.append(L"\\r");   break;
                case '\t':  result.append(L"\\t");   break;
                case '\v':  result.append(L"\\v");   break;
                // Note: single quotes are OK for JSON
                case '\"':  result.append(L"\\\"");  break; // double quote
                case '\\':  result.append(L"/");     break; // backslash                        
                        
                default:   result.append(1, str[pos]); break;
            }
        }

        finalResult = result;
    }

    // Maps errors from errno.h to the brackets error codes
    // found in brackets_extensions.js
    int ConvertErrnoCode(int errorCode, bool isReading = true)
    {
        switch (errorCode) {
        case NO_ERROR:
            return NO_ERROR;
        case EINVAL:
            return ERR_INVALID_PARAMS;
        case ENOENT:
            return ERR_NOT_FOUND;
        default:
            return ERR_UNKNOWN;
        }
    }

    // Maps errors from  WinError.h to the brackets error codes
    // found in brackets_extensions.js
    int ConvertWinErrorCode(int errorCode, bool isReading = true)
    {
        switch (errorCode) {
        case NO_ERROR:
            return NO_ERROR;
        case ERROR_PATH_NOT_FOUND:
        case ERROR_FILE_NOT_FOUND:
            return ERR_NOT_FOUND;
        case ERROR_ACCESS_DENIED:
            return isReading ? ERR_CANT_READ : ERR_CANT_WRITE;
        case ERROR_WRITE_PROTECT:
            return ERR_CANT_WRITE;
        case ERROR_HANDLE_DISK_FULL:
            return ERR_OUT_OF_SPACE;
        default:
            return ERR_UNKNOWN;
        }
    }


private:
    int lastError;
    UINT                    m_closeLiveBrowserHeartbeatTimerId;
    UINT                    m_closeLiveBrowserTimeoutTimerId;
    CefRefPtr<CefV8Value>   m_closeLiveBrowserCallback;
    static BracketsExtensionHandler* s_instance;

    IMPLEMENT_REFCOUNTING(BracketsExtensionHandler);
};

BracketsExtensionHandler* BracketsExtensionHandler::s_instance = NULL;

void InitBracketsExtensions()
{
    // Register a V8 extension with JavaScript code that calls native
    // methods implemented in BracketsExtensionHandler.
    
    // The JavaScript code for the extension lives in res/brackets_extensions.js
    
    //NSString* sourcePath = [[NSBundle mainBundle] pathForResource:@"brackets_extensions" ofType:@"js"];
    //NSString* jsSource = [[NSString alloc] initWithContentsOfFile:sourcePath encoding:NSUTF8StringEncoding error:nil];

    extern HINSTANCE hInst;

    HRSRC hRes = FindResource(hInst, MAKEINTRESOURCE(IDS_BRACKETS_EXTENSIONS), MAKEINTRESOURCE(256));
    DWORD dwSize;
    LPBYTE pBytes = NULL;

    if(hRes)
    {
        HGLOBAL hGlob = LoadResource(hInst, hRes);
        if(hGlob)
        {
            dwSize = SizeofResource(hInst, hRes);
            pBytes = (LPBYTE)LockResource(hGlob);
        }
    }

    if (pBytes) {
        std::string jsSource((const char *)pBytes, dwSize);
        CefRegisterExtension("brackets", jsSource.c_str(), new BracketsExtensionHandler());
    }
}

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

bool BracketsShellAPI::DispatchShowAboutToBracketsJS(const CefRefPtr<CefBrowser>& browser)
{
  return DispatchBracketsJSCommand(browser, HELP_ABOUT);
}

/**
 * Event constants for TriggerBracketsJSEvent
 * These constants must MATCH the strings in Commands.js
 */
const std::wstring BracketsShellAPI::FILE_QUIT = L"file.quit";
const std::wstring BracketsShellAPI::FILE_CLOSE_WINDOW = L"file.close_window";
const std::wstring BracketsShellAPI::FILE_RELOAD = L"debug.refreshWindow";
const std::wstring BracketsShellAPI::HELP_ABOUT = L"help.about";




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
    return true; //if we didn't call correctly, do the default action
  }

  if( e ) {
    return true; //if there was an exception, do the default action
  }

  bool preventDefault = false;
  if(called && retval && retval->IsBool() ) {
    preventDefault = retval->GetBoolValue();
  }

  //Return whether we should do the default action or not (this function defaults to the caller should do the default)
  return (!preventDefault);
}
