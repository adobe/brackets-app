using Gtk;
using WebKit;

public class BracketsApp : Window {

    private const string TITLE = "Brackets editor";
    private string script_fname;
    private string html_fname;

    private Frame web_view;
    private WebView web_inspector;

    public BracketsApp (string basename) {
        this.title = BracketsApp.TITLE;
        this.script_fname = basename + "/../../src/linux/brackets_extensions.js";
        this.html_fname = basename + "/../../brackets/src/index.html";
        set_default_size (800, 600);

        create_widgets ();
    }

    private void create_widgets () {
        this.web_inspector = new WebView();
        this.web_view = Frame.instance;
        this.web_view.init(this.script_fname, this.web_inspector);
        var scrolled_window = new ScrolledWindow (null, null);

        scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scrolled_window.add (this.web_view);

        var scrolled_inspector_window = new ScrolledWindow (null, null);

        scrolled_inspector_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scrolled_inspector_window.add (this.web_inspector);

        var vbox = new VBox (false, 0);
        vbox.add (scrolled_window);
        add (vbox);

        this.destroy.connect (Gtk.main_quit);
        this.web_view.title_changed.connect ((source, frame, title) => {
            this.title = "%s - %s".printf (title, BracketsApp.TITLE);
        });

        this.web_view.toggle_developer_tools.connect ((source, do_show) => {
            if (do_show) {
                vbox.add (scrolled_inspector_window);
                scrolled_inspector_window.show();
            } else {
                vbox.remove (scrolled_inspector_window);
            }
        });
    }

    public void start () {
        show_all ();
        this.web_view.open (this.html_fname);
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        string basename = GLib.Environment.get_current_dir() + "/" + GLib.Path.get_dirname(args[0]);
        var browser = new BracketsApp (basename);
        browser.start ();

        Gtk.main ();

        return 0;
    }
}
