// This is the JavaScript code for bridging to native functionality
// See brackets_extentions.mm for implementation of native methods.
//
// Note: All file native file i/o functions are synchronous, but are exposed
// here as asynchronous calls. The error code from the last synchronous call
// is stored in brackets.file._lastError. 

var brackets;
if (!brackets)
   brackets = {};
if (!brackets.fs)
    brackets.fs = {};
(function() {
    // Internal function to get the last error code.
    function getLastError() {
        native function GetLastError();
        return GetLastError();
    }
    
    // Error values. These MUST be in sync with the error values
    // at the top of brackets_extensions.mm.
    
    /**
     * @constant No error.
     */
    brackets.fs.NO_ERROR                    = 0;
    
    /**
     * @constant Unknown error occurred.
     */
    brackets.fs.ERR_UNKNOWN                 = 1;
    
    /**
     * @constant Invalid parameters passed to function.
     */
    brackets.fs.ERR_INVALID_PARAMS          = 2;
    
    /**
     * @constant File or directory was not found.
     */
    brackets.fs.ERR_NOT_FOUND               = 3;
    
    /**
     * @constant File or directory could not be read.
     */
    brackets.fs.ERR_CANT_READ               = 4;
    
    /**
     * @constant An unsupported encoding value was specified.
     */
    brackets.fs.ERR_UNSUPPORTED_ENCODING    = 5;
    
    /**
     * @constant File could not be written.
     */
    brackets.fs.ERR_CANT_WRITE              = 6;
    
    /**
     * @constant Target directory is out of space. File could not be written.
     */
    brackets.fs.ERR_OUT_OF_SPACE            = 7;
    
    /**
     * Display the OS File Open dialog, allowing the user to select
     * files or directories.
     *
     * @param allowMultipleSelection If true, multiple files/directories can be selected.
     * @param chooseDirectory If true, only directories can be selected. If false, only 
     *        files can be selected.
     * @param title Tile of the open dialog.
     * @param initialPath Initial path to display in the dialog. Pass NULL or "" to 
     *        display the last path chosen.
     * @param fileTypes Array of strings specifying the selectable file extensions. 
     *        These strings should not contain '.'. This parameter is ignored when 
     *        chooseDirectory=true.
     * @param callback Asynchronous callback function. The callback gets two arguments 
     *        (err, selection) where selection is an array of the names of the selected files.
     *        Possible error values:
     *          NO_ERROR
     *          ERR_INVALID_PARAMS
     *
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
    brackets.fs.showOpenDialog = function(allowMultipleSelection, chooseDirectory, title, initialPath, fileTypes, callback) {
       native function ShowOpenDialog();
       var resultString = ShowOpenDialog(allowMultipleSelection, chooseDirectory, 
                                         title || 'Open', initialPath || '', 
                                         fileTypes ? fileTypes.join(' ') : '');
       var result = JSON.parse(resultString || '[]');
       callback(getLastError(), result);
    };
    
    /**
     * Reads the contents of a directory. 
     *
     * @param path The path of the directory to read.
     * @param callback Asynchronous callback function. The callback gets two arguments 
     *        (err, files) where files is an array of the names of the files
     *        in the directory excluding '.' and '..'.
     *        Possible error values:
     *          NO_ERROR
     *          ERR_UNKNOWN
     *          ERR_INVALID_PARAMS
     *          ERR_NOT_FOUND
     *          ERR_CANT_READ
     *                 
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
    brackets.fs.readdir = function(path, callback) {
        native function ReadDir();
        var resultString = ReadDir(path);
        var result = JSON.parse(resultString || '[]');
        callback(getLastError(), result);
    };
    
    /**
     * Get information for the selected file or directory.
     *
     * @param path The path of the file or directory to read.
     * @param callback Asynchronous callback function. The callback gets two arguments 
     *        (err, stats) where stats is an object with isFile() and isDirectory() functions.
     *        Possible error values:
     *          NO_ERROR
     *          ERR_UNKNOWN
     *          ERR_INVALID_PARAMS
     *          ERR_NOT_FOUND
     *                 
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
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
    
    /**
     * Reads the entire contents of a file. 
     *
     * @param path The path of the file to read.
     * @param encoding The encoding for the file. Optional. Supported values are "" and "utf8".
     * @param callback Asynchronous callback function. The callback gets two arguments 
     *        (err, data) where data is the contents of the file.
     *        Possible error values:
     *          NO_ERROR
     *          ERR_UNKNOWN
     *          ERR_INVALID_PARAMS
     *          ERR_NOT_FOUND
     *          ERR_CANT_READ
     *          ERR_UNSUPPORTED_ENCODING
     *                 
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
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
    
    /**
     * Write data to a file, replacing the file if it already exists. 
     *
     * @param path The path of the file to write.
     * @param data The data to write to the file.
     * @param encoding The encoding for the file. Optional. Supported values are "" and "utf8".
     * @param callback Asynchronous callback function. The callback gets one argument (err).
     *        Possible error values:
     *          NO_ERROR
     *          ERR_UNKNOWN
     *          ERR_INVALID_PARAMS
     *          ERR_UNSUPPORTED_ENCODING
     *          ERR_CANT_WRITE
     *          ERR_OUT_OF_SPACE
     *                 
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
    brackets.fs.writeFile = function(path, data, encoding, callback) {
        native function WriteFile();
        var enc, cb;
        // encoding is optional. If omitted, use "".
        if (typeof encoding == 'function') {
            enc = "";
            cb = encoding;
        } else {
            enc = encoding;
            cb = callback;
        }
        WriteFile(path, data, enc);
        if (cb)
            cb(getLastError());
    };
})();;
