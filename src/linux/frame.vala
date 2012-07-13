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
        js_set_function(ctx, "GetLastError", js_last_error);
        js_set_function(ctx, "ShowOpenDialog", js_show_open_dialog);
        js_set_function(ctx, "ReadDir", js_read_dir);
        js_set_function(ctx, "IsDirectory", js_is_directory);
        js_set_function(ctx, "GetFileModificationTime", js_get_file_modification_time);
        js_set_function(ctx, "QuitApplication", js_quit_application);
        js_set_function(ctx, "ShowDeveloperTools", js_show_developer_tools);
        js_set_function(ctx, "ReadFile", js_read_file);
        /*js_set_function(ctx, "WriteFile", js_write_file);*/
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
        var res = new String.with_utf8_c_string(selected_fname);

        file_chooser.destroy();
        return new JSCore.Value.string(ctx, res);
    }

    public static JSCore.Value js_read_file (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {
        string script;
        ulong len;

        if (arguments.length < 1) {
            return new JSCore.Value.string(ctx, new String.with_utf8_c_string(""));
        }

        var s = arguments[0].to_string_copy(ctx, null);
        char[] buffer = new char[s.get_length() + 1];
        s.get_utf8_c_string (buffer, buffer.length);
        string fname = (string)buffer;

        GLib.FileUtils.get_contents(fname, out script, out len);
        var res = new String.with_utf8_c_string(script);

        return new JSCore.Value.string(ctx, res);
    }

    //there is no developer tools in api, so we just do a stub
    public static JSCore.Value js_show_developer_tools (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {
        return new JSCore.Value.undefined(ctx);
    }

    public static JSCore.Value js_is_directory (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

        if (arguments.length < 1) {
            return new JSCore.Value.boolean(ctx, false);
        }

        var s = arguments[0].to_string_copy(ctx, null);
        char[] buffer = new char[s.get_length() + 1];
        s.get_utf8_c_string (buffer, buffer.length);
        string fname = (string)buffer;

        return new JSCore.Value.boolean(ctx, GLib.FileUtils.test(fname, GLib.FileTest.IS_DIR));
    }

    public static JSCore.Value js_quit_application (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {
        Gtk.main_quit();
        return new JSCore.Value.undefined(ctx);
    }

    public static JSCore.Value js_get_file_modification_time (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {
        return new JSCore.Value.number (ctx, 100);
    }

    public static JSCore.Value js_get_elapsed_milliseconds (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {
        return new JSCore.Value.number (ctx, 100);
    }

    public static JSCore.Value js_last_error (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {
        return new JSCore.Value.number (ctx, 0);
    }

    public static JSCore.Value js_read_dir (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

        if (arguments.length < 1) {
            return ctx.evaluate_script(new String.with_utf8_c_string("[]" ), null, null, 0, null);
        }

        var s = arguments[0].to_string_copy(ctx, null);
        char[] buffer = new char[s.get_length() + 1];
        s.get_utf8_c_string (buffer, buffer.length);
        string dirname = (string)buffer;

        StringBuilder json = new StringBuilder();
        json.assign("[");

        try{
            var dir = Dir.open(dirname);

            while(true) {
                var name = dir.read_name();
                if (name == null) {
                    break;
                }

                json.append("'%s',".printf(name));
            }

            if (json.str [json.len - 1] == ',') {
                json.erase (json.len - 1, 1);
            }
        }
        catch(Error e){
            return ctx.evaluate_script(new String.with_utf8_c_string("[]" ), null, null, 0, null);
        }

        json.append("]");
        s = new String.with_utf8_c_string(json.str);

        var r = ctx.evaluate_script(s, null, null, 0, null);
        s = null;
        buffer = null;

        return r;
    }

    public static JSCore.Value js_simple_func (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

        return new JSCore.Value.boolean (ctx, true);
    }
}
