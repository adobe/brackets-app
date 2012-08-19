using Gtk;
using WebKit;

public class BracketsWindow : Browser {

    private string script_fname;
    private string html_fname;
    private DateTime startup_time;

    private WebView web_inspector;
    private ScrolledWindow inspector_container;

    public signal void close_window();
    public signal WebView new_window();

    public BracketsWindow (string basename, DateTime startup_time) {
        base();

        this.startup_time = startup_time;
        if (!GLib.Path.is_absolute(basename)) {
            this.script_fname = basename + Config.script_path;
            this.html_fname = basename + Config.index_path;
        } else {
            this.script_fname = Config.script_path;
            this.html_fname = Config.index_path;
        }
    }

    protected override WebView createWebView() {
        Frame frame = Frame.create();
        frame.init(this.script_fname, this.web_inspector, this.startup_time);

        return frame;
    }

    protected override void create_widgets() {
        web_inspector = new WebView();

        inspector_container = new ScrolledWindow (null, null);

        inspector_container.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        inspector_container.add (web_inspector);

        base.create_widgets();
    }

    protected override void connect_signals() {
        base.connect_signals();

        this.destroy.connect ((source) => {
            this.close_window();
        });

        this.web_view.create_web_view.connect((source, frame) => {
            return this.new_window();
        });

        this.web_view.close_web_view.connect((source) => {
            this.destroy();
            return true;
        });

        (this.web_view as Frame).toggle_developer_tools.connect ((source, do_show) => {
            if (do_show) {
                vbox.add (inspector_container);
                inspector_container.show();
            } else {
                vbox.remove (inspector_container);
            }
        });
    }

    public override void init() {
        base.init();
        web_view.open (html_fname);
    }
}

