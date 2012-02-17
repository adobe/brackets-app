// This is the JavaScript code for bridging to native functionality
// See brackets_extentions.mm for implementation of native methods.
//
// Note: All file native file i/o functions are synchronous, but are exposed
// here as asynchronous calls. 

var brackets;
if (!brackets)
   brackets = {};
if (!brackets.fs)
    brackets.fs = {};
if (!brackets.app)
    brackets.app = {};

(function() {
    // Internal function to get the last error code.
    native function GetLastError();
    function getLastError() {
        return GetLastError();
    }
    
    // For debug purposes. When true, a 10 millisecond timeout is
    // run before the callback is called. See invokeCallback() below
    // for details.
    brackets.forceAsyncCallbacks = false;
        
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
     * @constant Specified path does not point to a file.
     */
    brackets.fs.ERR_NOT_FILE                = 8;
    
    /**
     * @constant Specified path does not point to a directory.
     */
    brackets.fs.ERR_NOT_DIRECTORY           = 9;
    
    /**
     * Display the OS File Open dialog, allowing the user to select
     * files or directories.
     *
     * @param {boolean} allowMultipleSelection If true, multiple files/directories can be selected.
     * @param {boolean} chooseDirectory If true, only directories can be selected. If false, only 
     *        files can be selected.
     * @param {string} title Tile of the open dialog.
     * @param {string} initialPath Initial path to display in the dialog. Pass NULL or "" to 
     *        display the last path chosen.
     * @param {Array.<string>} fileTypes Array of strings specifying the selectable file extensions. 
     *        These strings should not contain '.'. This parameter is ignored when 
     *        chooseDirectory=true.
     * @param {function(err, selection)} callback Asynchronous callback function. The callback gets two arguments 
     *        (err, selection) where selection is an array of the names of the selected files.
     *        Possible error values:
     *          NO_ERROR
     *          ERR_INVALID_PARAMS
     *
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
    native function ShowOpenDialog();
    brackets.fs.showOpenDialog = function(allowMultipleSelection, chooseDirectory, title, initialPath, fileTypes, callback) {
        setTimeout(function() {
           var resultString = ShowOpenDialog(allowMultipleSelection, chooseDirectory, 
                                             title || 'Open', initialPath || '', 
                                             fileTypes ? fileTypes.join(' ') : '');
           var result = JSON.parse(resultString || '[]');
           invokeCallback(callback, getLastError(), result);
        }, 0);
    };
    
    /**
     * Reads the contents of a directory. 
     *
     * @param {string} path The path of the directory to read.
     * @param {function(err, files)} callback Asynchronous callback function. The callback gets two arguments 
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
    native function ReadDir();
    brackets.fs.readdir = function(path, callback) {
        var resultString = ReadDir(path);
        var result = JSON.parse(resultString || '[]');
        invokeCallback(callback, getLastError(), result);
    };
    
    /**
     * Get information for the selected file or directory.
     *
     * @param {string} path The path of the file or directory to read.
     * @param {function(err, stats)} callback Asynchronous callback function. The callback gets two arguments 
     *        (err, stats) where stats is an object with isFile() and isDirectory() functions.
     *        Possible error values:
     *          NO_ERROR
     *          ERR_UNKNOWN
     *          ERR_INVALID_PARAMS
     *          ERR_NOT_FOUND
     *                 
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
    native function IsDirectory();
    native function GetFileModificationTime();
    brackets.fs.stat = function(path, callback) {
        var isDir = IsDirectory(path);
        var modtime = GetFileModificationTime(path);

        invokeCallback(callback, getLastError(), {
            isFile: function() {
                return !isDir;
            },
            isDirectory: function() {
                return isDir;
            },
            mtime: modtime
        });
    };


    /**
     * Performs native quit
     */
     native function QuitApplication();
     brackets.app.quit = function() {
        QuitApplication();
     };
    
    /**
     * Reads the entire contents of a file. 
     *
     * @param {string} path The path of the file to read.
     * @param {string} encoding The encoding for the file. The only supported encoding is 'utf8'.
     * @param {function(err, data)} callback Asynchronous callback function. The callback gets two arguments 
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
    native function ReadFile();
    brackets.fs.readFile = function(path, encoding, callback) {
        var contents = ReadFile(path, encoding);
        invokeCallback(callback, getLastError(), contents);
    };
    
    /**
     * Write data to a file, replacing the file if it already exists. 
     *
     * @param {string} path The path of the file to write.
     * @param {string} data The data to write to the file.
     * @param {string} encoding The encoding for the file. The only supported encoding is 'utf8'.
     * @param {function(err)} callback Asynchronous callback function. The callback gets one argument (err).
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
    native function WriteFile();
    brackets.fs.writeFile = function(path, data, encoding, callback) {
        WriteFile(path, data, encoding);
        if (callback)
            invokeCallback(callback, getLastError());
    };
    
    /**
     * Set permissions for a file or directory.
     *
     * @param {string} path The path of the file or directory
     * @param {number} mode The permissions for the file or directory, in numeric format (ie 0777)
     * @param {function(err)} callback Asynchronous callback function. The callback gets one argument (err).
     *        Possible error values:
     *          NO_ERROR
     *          ERR_UNKNOWN
     *          ERR_INVALID_PARAMS
     *          ERR_CANT_WRITE
     *
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
    native function SetPosixPermissions();
    brackets.fs.chmod = function(path, mode, callback) {
        SetPosixPermissions(path, mode);
        invokeCallback(callback, getLastError());
    };
    
    /**
     * Delete a file.
     *
     * @param {string} path The path of the file to delete
     * @param {function(err)} callback Asynchronous callback function. The callback gets one argument (err).
     *        Possible error values:
     *          NO_ERROR
     *          ERR_UNKNOWN
     *          ERR_INVALID_PARAMS
     *          ERR_NOT_FOUND
     *          ERR_NOT_FILE
     *
     * @return None. This is an asynchronous call that sends all return information to the callback.
     */
    native function DeleteFileOrDirectory();
    native function IsDirectory();
    brackets.fs.unlink = function(path, callback) {
        // Unlink can only delete files
        if (IsDirectory(path)) {
            callback(brackets.fs.ERR_NOT_FILE);
            return;
        }
        DeleteFileOrDirectory(path);
        invokeCallback(callback, getLastError());
    };

    /**
     * Return the number of milliseconds that have elapsed since the application
     * was launched. 
     */
    native function GetElapsedMilliseconds();
    brackets.app.getElapsedMilliseconds = function() {
        return GetElapsedMilliseconds();
    }

    /**
     * Invoke a callback function.
     *
     * If the variable "brackets.forceAsyncCallbacks" is true, the callback is called after a 10
     * ms timer is run. If brackets.forceAsyncCallbacks is false, the callback is called
     * immediately.
     */
    function invokeCallback(callback /* callback args */) {
        var args = [].splice.call(arguments, 1);
    
        function doCallback() {
            callback.apply(this, args);
        }
        
        if (brackets.forceAsyncCallbacks) {
            setTimeout(doCallback, 10);
        } else {
            doCallback();
        }        
    }
})();;
