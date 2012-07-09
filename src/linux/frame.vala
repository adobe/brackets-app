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
        /*js_set_function(ctx, "ShowOpenDialog", js_show_open_dialog);*/
        js_set_function(ctx, "ReadDir", js_read_dir);
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

        stdout.printf("123");
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
