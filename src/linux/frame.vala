using Gtk;
using WebKit;
using JSCore;

public class Frame: WebView {

    public Frame(string script_url) {
        attachScript(script_url);

        this.window_object_cleared.connect ((source, frame, context, window_object) => {
            this.js_set_bindings((JSCore.GlobalContext) context);
        });
        WebSettings settings = new WebSettings();
        settings.enable_file_access_from_file_uris = true;
        this.set_settings(settings);
    }

    private void attachScript(string fname) {
        string script;
        ulong len;

        GLib.FileUtils.get_contents(fname, out script, out len);
        execute_script (script);
    }

    private void js_set_bindings(GlobalContext ctx) {
        js_set_function(ctx, "simple_func", js_simple_func);
        /*js_set_function(ctx, "GetLastError", js_last_error);*/
        /*js_set_function(ctx, "ShowOpenDialog", js_show_open_dialog);*/
        /*js_set_function(ctx, "ReadDir", js_read_dir);*/
        /*js_set_function(ctx, "IsDirectory", js_is_directory);*/
        /*js_set_function(ctx, "GetFileModificationTime", js_get_file_modification_time);*/
        /*js_set_function(ctx, "QuitApplication", js_quit_application);*/
        /*js_set_function(ctx, "ShowDeveloperTools", js_show_developer_tools);*/
        /*js_set_function(ctx, "ReadFile", js_read_file);*/
        /*js_set_function(ctx, "WriteFile", js_write_file);*/
        /*js_set_function(ctx, "SetPosixPermissions", js_set_posix_permissions);*/
        /*js_set_function(ctx, "DeleteFileOrDirectory", js_delete_file_or_directory);*/
        /*js_set_function(ctx, "GetElapsedMilliseconds", js_get_elapsed_milliseconds);*/
        /*js_set_function(ctx, "OpenLiveBrowser", js_open_live_browser);*/
        /*js_set_function(ctx, "CloseLiveBrowser", js_close_live_browser);*/
    }

    private void js_set_function(Context ctx, string func_name, ObjectCallAsFunctionCallback func) {
        var s = new String.with_utf8_c_string (func_name);
        var f = new JSCore.Object.function_with_callback (ctx, s, func);
        var global = ctx.get_global_object();
        global.set_property (ctx, s, f, 0, null);
    }

    /*public static JSCore.Value js_read_dir (Context ctx,*/
    /*        JSCore.Object function,*/
    /*        JSCore.Object thisObject,*/
    /*        JSCore.Value[] arguments,*/
    /*        out JSCore.Value exception) {*/

    /*    JSCore.Value[1] dirs = {*/
    /*        new JSCore.Value.string( ctx, new String.with_utf8_c_string ("a") )*/
    /*    };*/
    /*    dirs += new JSCore.Value.string( ctx, new String.with_utf8_c_string ("a") );*/
    /*    dirs += new JSCore.Value.string( ctx, new String.with_utf8_c_string ("b") );*/
    /*    JSCore.Value err = new JSCore.Value.null( ctx );*/

    /*    return new JSCore.Object.array( ctx, 2, dirs, out err);*/
    /*}*/

    public static JSCore.Value js_simple_func (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

        return new JSCore.Value.boolean (ctx, true);
    }
}
