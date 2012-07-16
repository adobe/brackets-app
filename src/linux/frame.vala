using Gtk;
using WebKit;
using JSCore;

enum Errors {
    NO_ERROR = 0,
    ERR_UNKNOWN = 1,
    ERR_INVALID_PARAMS = 2,
    ERR_NOT_FOUND = 3,
    ERR_CANT_READ = 4,
    ERR_UNSUPPORTED_ENCODING = 5,
    ERR_CANT_WRITE = 6,
    ERR_OUT_OF_SPACE = 7,
    ERR_NOT_FILE = 8,
    ERR_NOT_DIRECTORY = 9
}

public class JSUtils {
    public static string valueToString(Context ctx, JSCore.Value val) {
        var s = val.to_string_copy(ctx, null);
        char[] buffer = new char[s.get_length() + 1];
        s.get_utf8_c_string (buffer, buffer.length);
        return (string)buffer;
    }
}

public class Frame: WebView {

    private static Frame _instance = null;
    private bool initDone = false;
    private bool inspectorVisible = false;
    private int lastError = Errors.NO_ERROR;

    /* We need singleton because it's an only reasonable way to get
        widget instance inside the js function
    */
    public static Frame instance {
        get {
            if (_instance == null) {
                _instance = new Frame();
            }

            return _instance;
        }
        private set {
        }
    }

    public signal void toggle_developer_tools(bool show);

    private Frame() { }

    public void init(string script_url, WebView inspector_view) {
        if (initDone == true) {
            return;
        }

        initDone = true;
        attachScript(script_url);

        this.window_object_cleared.connect ((source, frame, context, window_object) => {
            this.js_set_bindings((JSCore.GlobalContext) context);
        });
        WebSettings settings = new WebSettings();
        settings.enable_file_access_from_file_uris = true;
        settings.enable_developer_extras = true;
        this.set_settings(settings);

        WebInspector inspector =  this.get_inspector();
        inspector.inspect_web_view.connect ((view) => {
            return inspector_view;
        });
    }

    private void attachScript(string fname) {
        string script;
        ulong len;

        GLib.FileUtils.get_contents(fname, out script, out len);
        execute_script (script);
    }

    private void js_set_bindings(GlobalContext ctx) {
        js_set_function(ctx, "GetLastError", js_last_error);
        js_set_function(ctx, "ShowOpenDialog", js_show_open_dialog);
        js_set_function(ctx, "ReadDir", js_read_dir);
        js_set_function(ctx, "IsDirectory", js_is_directory);
        js_set_function(ctx, "GetFileModificationTime", js_get_file_modification_time);
        js_set_function(ctx, "QuitApplication", js_quit_application);
        js_set_function(ctx, "ShowDeveloperTools", js_show_developer_tools);
        js_set_function(ctx, "ReadFile", js_read_file);
        js_set_function(ctx, "WriteFile", js_write_file);
        /*js_set_function(ctx, "SetPosixPermissions", js_set_posix_permissions);*/
        /*js_set_function(ctx, "DeleteFileOrDirectory", js_delete_file_or_directory);*/
        js_set_function(ctx, "GetElapsedMilliseconds", js_get_elapsed_milliseconds);
        /*js_set_function(ctx, "OpenLiveBrowser", js_open_live_browser);*/
        /*js_set_function(ctx, "CloseLiveBrowser", js_close_live_browser);*/
    }

    private void js_set_function(Context ctx, string func_name, ObjectCallAsFunctionCallback func) {
        var s = new String.with_utf8_c_string (func_name);
        var f = new JSCore.Object.function_with_callback (ctx, s, func);
        var global = ctx.get_global_object();
        global.set_property (ctx, s, f, 0, null);
    }

    public static JSCore.Value js_show_open_dialog (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

        /*var s = arguments[0].to_string_copy(ctx, null);*/
        /*char[] buffer = new char[s.get_length() + 1];*/
        /*s.get_utf8_c_string (buffer, buffer.length);*/
        /*string fname = (string)buffer;*/

        string selected_fname = "";

                                                                //possibly need an object here
        var file_chooser = new FileChooserDialog ("Open File", null,
                                      FileChooserAction.OPEN,
                                      Stock.CANCEL, ResponseType.CANCEL,
                                      Stock.OPEN, ResponseType.ACCEPT);

        if (file_chooser.run () == ResponseType.ACCEPT) {
            selected_fname =  file_chooser.get_filename();
        }
        var res = new String.with_utf8_c_string("[" + selected_fname + "]");

        file_chooser.destroy();
        return new JSCore.Value.string(ctx, res);
    }

    public static JSCore.Value js_read_file (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        if (arguments.length < 1) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string fname = JSUtils.valueToString(ctx, arguments[0]);
        /*string encoding = JSUtils.valueToString(ctx, arguments[1]);*/

        /* seems like there are no checks for encoding in the editor */
        /*if (encoding != "utf8") {*/
        /*    instance.lastError = Errors.ERR_UNSUPPORTED_ENCODING;*/
        /*    return new JSCore.Value.undefined(ctx);*/
        /*}*/

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.IS_REGULAR))) {
            instance.lastError = Errors.ERR_NOT_FILE;
            return new JSCore.Value.undefined(ctx);
        }

        string script;
        ulong len;

        try {
            GLib.FileUtils.get_contents(fname, out script, out len);
        } catch(FileError e) {
            //need to check for specific errors here
            instance.lastError = Errors.ERR_CANT_READ;
            return new JSCore.Value.undefined(ctx);
        }

        var res = new String.with_utf8_c_string(script);

        instance.lastError = Errors.NO_ERROR;
        return new JSCore.Value.string(ctx, res);
    }

    public static JSCore.Value js_write_file (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        if (arguments.length < 2) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string fname = JSUtils.valueToString(ctx, arguments[0]);
        string data = JSUtils.valueToString(ctx, arguments[1]);
        /*string encoding = JSUtils.valueToString(ctx, arguments[2]);*/

        /* seems like there are no checks for encoding in the editor */
        /*if (encoding != "utf8") {*/
        /*    instance.lastError = Errors.ERR_UNSUPPORTED_ENCODING;*/
        /*    return new JSCore.Value.undefined(ctx);*/
        /*}*/

        try {
            GLib.FileUtils.set_contents(fname, data);
        } catch(FileError e) {
            //need to check for specific errors here
            instance.lastError = Errors.ERR_CANT_WRITE;
            return new JSCore.Value.undefined(ctx);
        }

        instance.lastError = Errors.NO_ERROR;
        return new JSCore.Value.undefined(ctx);
    }

    //there is no developer tools in api, so we just do a stub
    public static JSCore.Value js_show_developer_tools (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        Frame instance = Frame.instance;
        WebInspector inspector =  instance.get_inspector();

        instance.toggle_developer_tools(!instance.inspectorVisible);

        if (instance.inspectorVisible == false) {
            inspector.show();
        }

        instance.inspectorVisible = !instance.inspectorVisible;

        return new JSCore.Value.undefined(ctx);
    }

    public static JSCore.Value js_is_directory (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        if (arguments.length < 1) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string fname = JSUtils.valueToString(ctx, arguments[0]);

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        instance.lastError = Errors.NO_ERROR;
        return new JSCore.Value.boolean(ctx, GLib.FileUtils.test(fname, GLib.FileTest.IS_DIR));
    }

    public static JSCore.Value js_quit_application (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {
        Gtk.main_quit();
        return new JSCore.Value.undefined(ctx);
    }

    public static JSCore.Value js_get_file_modification_time (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        if (arguments.length < 1) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string fname = JSUtils.valueToString(ctx, arguments[0]);

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        var f = File.new_for_path(fname);
        var info = f.query_info("*", FileQueryInfoFlags.NONE);

        TimeVal time = info.get_modification_time();

        instance.lastError = Errors.NO_ERROR;
        return new JSCore.Value.number(ctx, time.tv_sec);
    }

    public static JSCore.Value js_get_elapsed_milliseconds (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {
        return new JSCore.Value.number (ctx, 100);
    }

    public static JSCore.Value js_last_error (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {
        return new JSCore.Value.number (ctx, Frame.instance.lastError);
    }

    public static JSCore.Value js_read_dir (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        if (arguments.length < 1) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        Frame instance = Frame.instance;
        string dirname = JSUtils.valueToString(ctx, arguments[0]);

        if (!(GLib.FileUtils.test(dirname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        if (!(GLib.FileUtils.test(dirname, GLib.FileTest.IS_DIR))) {
            instance.lastError = Errors.ERR_NOT_DIRECTORY;
            return new JSCore.Value.undefined(ctx);
        }

        StringBuilder json = new StringBuilder();
        json.assign("[");

        try{
            var dir = Dir.open(dirname);

            while(true) {
                var name = dir.read_name();
                if (name == null) {
                    break;
                }

                json.append("\"%s\",".printf(name));
            }

            if (json.str [json.len - 1] == ',') {
                json.erase (json.len - 1, 1);
            }
        }
        catch(Error e){
            instance.lastError = Errors.ERR_CANT_READ;
            return new JSCore.Value.undefined(ctx);
        }

        json.append("]");
        var s = new String.with_utf8_c_string(json.str);

        instance.lastError = Errors.NO_ERROR;
        return new JSCore.Value.string(ctx, s);
    }
}
