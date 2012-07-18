using Gtk;
using WebKit;

public class BracketsWindow : Browser {

    private string script_fname;
    private string html_fname;

    private WebView web_inspector;
    private ScrolledWindow inspector_container;

    public signal void close_window();
    public signal WebView new_window();

    public BracketsWindow (string basename) {
        base();

        this.script_fname = basename + "/../../src/linux/brackets_extensions.js";
        this.html_fname = basename + "/../../brackets/src/index.html";
    }

    protected override WebView createWebView() {
        Frame frame = Frame.create();
        frame.init(this.script_fname, this.web_inspector);

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

