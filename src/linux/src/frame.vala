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

    public static uint64 getMillisecondsFromDate(DateTime d) {
        //Is seconds precise, whereas should be ms precise
        uint64 tstamp = d.to_unix();
        double msecs = d.get_seconds() - Math.round(d.get_seconds());

        if (msecs < -0.001) { //tsamp was rounding to seconds and we recover information back
            tstamp--;
            msecs += 1.0;
        }

        uint64 ts = tstamp * 1000 + (uint64) (msecs * 1000.0);
        return ts;
    }

    public static JSCore.Value stringArrToValue(Context ctx, string[] arr) {
        StringBuilder json = new StringBuilder();
        json.assign("[");

        if (arr.length != 0) {
            for (int i = 0; i < arr.length; ++i) {
                if (i > 0) {
                    json.append(",");
                }

                json.append("\"%s\"".printf(arr[i].replace("\"", "\\\"")));
            }
        }

        json.append("]");

        return new JSCore.Value.string(ctx, new String.with_utf8_c_string(json.str));
    }
}

public class Frame: WebView {

    private static Frame[] frames = {};

    private bool initDone = false;
    private bool inspectorVisible = false;
    private int lastError = Errors.NO_ERROR;
    private uint64 startTime = 0;
    private int frameid;

    public signal void toggle_developer_tools(bool show);

    private Frame(int id) {
        frameid = id;
    }

    public static Frame create() {
        int newid = frames.length + 1;
        var frame = new Frame(newid);

        frames += frame;

        return frame;
    }

    public static Frame getByContext(Context ctx) {
        var script = new String.with_utf8_c_string("window.top.__frame_id");
        int id = ctx.evaluate_script(script, null, null, 0, null).to_number(ctx, null);
        foreach(Frame frame in frames) {
            if (frame.frameid == id) {
                return frame;
            }
        }

        return null;
    }

    public void init(string script_url, WebView inspector_view, DateTime startup_time) {
        if (initDone == true) {
            return;
        }

        initDone = true;
        startTime = JSUtils.getMillisecondsFromDate(startup_time);

        this.window_object_cleared.connect ((source, frame, ctx, window_object) => {
            this.js_set_bindings((JSCore.GlobalContext) ctx);
            //the only way found to identify widget by js context
            execute_script("window.top.__frame_id = %d".printf(frameid));
            attachScript(script_url);
        });

        WebSettings settings = new WebSettings();
        settings.enable_file_access_from_file_uris = true;
        settings.enable_developer_extras = true;
        settings.javascript_can_open_windows_automatically = true;
        this.set_settings(settings);

        WebInspector inspector =  this.get_inspector();
        inspector.inspect_web_view.connect ((view) => {
            return inspector_view;
        });
    }

    private void attachScript(string fname) {
        string script;
        ulong len;

        try {
            GLib.FileUtils.get_contents(fname, out script, out len);
            execute_script (script);
        } catch(FileError err) {
            stderr.printf("Warn: %s has not been executed\n", fname);
        }
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
        js_set_function(ctx, "SetPosixPermissions", js_set_posix_permissions);
        js_set_function(ctx, "DeleteFileOrDirectory", js_delete_file_or_directory);
        js_set_function(ctx, "GetElapsedMilliseconds", js_get_elapsed_milliseconds);
        js_set_function(ctx, "OpenLiveBrowser", js_open_live_browser);
        js_set_function(ctx, "CloseLiveBrowser", js_close_live_browser);
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
            JSCore.Value[] arguments) {

        Frame instance = Frame.getByContext(ctx);

        if (arguments.length < 5) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        bool multiple_selection = arguments[0].to_boolean(ctx);
        bool choose_directory = arguments[1].to_boolean(ctx);
        string title = JSUtils.valueToString(ctx, arguments[2]);
        string initial_path = JSUtils.valueToString(ctx, arguments[3]);
        string ext_str = JSUtils.valueToString(ctx, arguments[4]);

        var file_chooser = new FileChooserDialog (title, null,
                                      choose_directory ? FileChooserAction.SELECT_FOLDER :
                                                            FileChooserAction.OPEN,
                                      Stock.CANCEL, ResponseType.CANCEL,
                                      Stock.OPEN, ResponseType.ACCEPT);

        file_chooser.select_multiple = multiple_selection;

        if (initial_path != "") {
            file_chooser.set_current_folder(initial_path);
        }

        if (!choose_directory && ext_str.length > 0) {
            string[] exts = ext_str.split(" ");

            if (exts.length > 0) {
                FileFilter filter = new FileFilter();
                for (int i = 0; i < exts.length; ++i) {
                    filter.add_pattern("*." + exts[i]);
                }

                filter.set_name(ext_str.replace(" ", ", "));
                file_chooser.add_filter(filter);
            }
        }

        string[] selection = {};
        if (file_chooser.run() == ResponseType.ACCEPT) {
            file_chooser.get_filenames()
                    .foreach((str) => { selection += str; });
        }

        file_chooser.destroy();
        instance.lastError = Errors.NO_ERROR;

        return JSUtils.stringArrToValue(ctx, selection);
    }

    public static JSCore.Value js_read_file (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        Frame instance = Frame.getByContext(ctx);
        if (arguments.length < 1 || !arguments[0].is_string(ctx)) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string fname = JSUtils.valueToString(ctx, arguments[0]);
        if (arguments.length == 2 && ( !arguments[1].is_string(ctx) ||
                        JSUtils.valueToString(ctx, arguments[1]) != "utf8")) {
            instance.lastError = Errors.ERR_UNSUPPORTED_ENCODING;
            return new JSCore.Value.undefined(ctx);
        }

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.IS_REGULAR))) {
            instance.lastError = Errors.ERR_CANT_READ;
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

        Frame instance = Frame.getByContext(ctx);
        if (arguments.length < 2 || !arguments[0].is_string(ctx)) {
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

    public static JSCore.Value js_show_developer_tools (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        Frame instance = Frame.getByContext(ctx);
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

        Frame instance = Frame.getByContext(ctx);
        if (arguments.length < 1 || !arguments[0].is_string(ctx)) {
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

    /**
    * This function is just stub for future
    */
    public static JSCore.Value js_open_live_browser (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {
        stderr.printf("openLiveBrowser has not been implemented yet\n");
        return new JSCore.Value.undefined(ctx);
    }

    /**
    * This function is just stub for future
    */
    public static JSCore.Value js_close_live_browser (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {
        stderr.printf("closeLiveBrowser has not been implemented yet\n");
        return new JSCore.Value.undefined(ctx);
    }

    public static JSCore.Value js_quit_application (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {
        Gtk.main_quit();
        return new JSCore.Value.undefined(ctx);
    }

    public static JSCore.Value js_set_posix_permissions (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        Frame instance = Frame.getByContext(ctx);

        if (arguments.length < 2) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string fname = JSUtils.valueToString(ctx, arguments[0]);
        int perms = arguments[1].to_number(ctx, null);

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        int ret = GLib.FileUtils.chmod(fname, perms);

        instance.lastError = ret == 0 ? Errors.NO_ERROR : Errors.ERR_UNKNOWN;
        return new JSCore.Value.undefined(ctx);
    }

    public static JSCore.Value js_delete_file_or_directory (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        Frame instance = Frame.getByContext(ctx);

        if (arguments.length < 1 || !arguments[0].is_string(ctx)) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string fname = JSUtils.valueToString(ctx, arguments[0]);

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        int ret = GLib.FileUtils.remove(fname);
        instance.lastError = ret == 0 ? Errors.NO_ERROR : Errors.ERR_UNKNOWN;

        return new JSCore.Value.undefined(ctx);
    }

    public static JSCore.Value js_get_file_modification_time (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        Frame instance = Frame.getByContext(ctx);

        if (arguments.length < 1 || !arguments[0].is_string(ctx)) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string fname = JSUtils.valueToString(ctx, arguments[0]);

        if (!(GLib.FileUtils.test(fname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        var f = File.new_for_path(fname);
        TimeVal time;
        try {
            var info = f.query_info("*", FileQueryInfoFlags.NONE);
            time = info.get_modification_time();
        } catch(Error err) {
            instance.lastError = Errors.ERR_UNKNOWN;
            return new JSCore.Value.undefined(ctx);
        }

        instance.lastError = Errors.NO_ERROR;
        return new JSCore.Value.number(ctx, time.tv_sec * 1000);
    }

    public static JSCore.Value js_get_elapsed_milliseconds (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {
        Frame instance = Frame.getByContext(ctx);
        uint64 diff = JSUtils.getMillisecondsFromDate(new DateTime.now_local()) - instance.startTime;

        return new JSCore.Value.number (ctx, diff);
    }

    public static JSCore.Value js_last_error (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {
        return new JSCore.Value.number (ctx, Frame.getByContext(ctx).lastError);
    }

    public static JSCore.Value js_read_dir (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments) {

        Frame instance = Frame.getByContext(ctx);
        if (arguments.length < 1 || !arguments[0].is_string(ctx)) {
            instance.lastError = Errors.ERR_INVALID_PARAMS;
            return new JSCore.Value.undefined(ctx);
        }

        string dirname = JSUtils.valueToString(ctx, arguments[0]);

        if (!(GLib.FileUtils.test(dirname, GLib.FileTest.EXISTS))) {
            instance.lastError = Errors.ERR_NOT_FOUND;
            return new JSCore.Value.undefined(ctx);
        }

        if (!(GLib.FileUtils.test(dirname, GLib.FileTest.IS_DIR))) {
            instance.lastError = Errors.ERR_NOT_DIRECTORY;
            return new JSCore.Value.undefined(ctx);
        }

        string[] fnames = {};

        try{
            var dir = Dir.open(dirname);

            while(true) {
                var name = dir.read_name();
                if (name == null) {
                    break;
                }

                fnames += name;
            }

        } catch(Error e) {
            instance.lastError = Errors.ERR_CANT_READ;
            return new JSCore.Value.undefined(ctx);
        }

        instance.lastError = Errors.NO_ERROR;
        return JSUtils.stringArrToValue(ctx, fnames);
    }
}
