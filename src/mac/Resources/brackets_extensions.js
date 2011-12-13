// This is the JavaScript code for bridging to native functionality
// See brackets_extentions.mm for implementation of native methods.
//
// Note: All file native file i/o functions are synchronous, but are exposed
// here as asynchronous calls. The error code from the last synchronous call
// is stored in brackets.file._lastError. 

var brackets;
if (!brackets)
   brackets = {};
if (!brackets.file)
   brackets.file = {};
if (!brackets.fs)
    brackets.fs = {};
(function() {
    // Begin prototype functions. These functions are from the original
    // Brackets prototype and will eventually be removed.
    brackets.file.getDirectoryListing = function(dir) {
       native function GetDirectoryListing();
       return GetDirectoryListing(dir);
    };
    brackets.file.isDirectory = function(dir) {
       native function IsDirectory();
       return IsDirectory(dir);
    };
    brackets.file.readFile = function(fname) {
       native function ReadFileIntoString();
       return ReadFileIntoString(fname);
    };
    brackets.file.saveFile = function(fname, contents) {
       native function SaveStringIntoFile();
       return SaveStringIntoFile(fname, contents);
    };
    brackets.file.showOpenPanel = function(canChooseFiles, canChooseDirectories, title) {
       native function ShowOpenPanel();
       return ShowOpenPanel(canChooseFiles, canChooseDirectories, title);
    };
    // End prototype functions. All functions below this point are "for real".
    
    // Internal function to get the last error code.
    function getLastError() {
        native function GetLastError();
        return GetLastError();
    }
    
    // Error values. These MUST be in sync with the error values
    // at the top of brackets_extensions.mm.
    brackets.fs.NO_ERROR                    = 0;
    brackets.fs.ERR_UNKNOWN                 = 1;
    brackets.fs.ERR_INVALID_PARAMS          = 2;
    brackets.fs.ERR_NOT_FOUND               = 3;
    brackets.fs.ERR_CANT_READ               = 4;
    brackets.fs.ERR_UNSUPPORTED_ENCODING    = 5;
    
    brackets.fs.showOpenDialog = function(allowMultipleSelection, chooseDirectory, title, initialPath, fileTypes, callback) {
       native function ShowOpenDialog();
       var resultString = ShowOpenDialog(allowMultipleSelection, chooseDirectory, 
                                         title || 'Open', initialPath || '', 
                                         fileTypes ? fileTypes.join(' ') : '');
       var result = JSON.parse(resultString || '[]');
       callback(getLastError(), result);
    };
    brackets.fs.readdir = function(path, callback) {
        native function ReadDir();
        var resultString = ReadDir(path);
        var result = JSON.parse(resultString || '[]');
        callback(getLastError(), result);
    };
    brackets.fs.stat = function(path, callback) {
        native function IsDirectory();
        var isDir = IsDirectory(path);
        callback(getLastError(), {
            isFile: function() {
                return !isDir;
            },
            isDirectory: function() {
                return isDir;
            }
        });
    };
    brackets.fs.readFile = function(path, encoding, callback) {
        native function ReadFile();
        var enc, cb;
        // encoding is optional. If omitted, use "".
        if (typeof encoding == 'function') {
            enc = "";
            cb = encoding;
        } else {
            enc = encoding;
            cb = callback;
        }
        var contents = ReadFile(path, enc);
        cb(getLastError(), contents);
    };
})();;
