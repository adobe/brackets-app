using Gtk;

public class BracketsApp : Window {

    private const string TITLE = "Brackets editor";
    private string script_fname;
    private string html_fname;

    private Entry script_input;
    private Frame web_view;

    public BracketsApp (string basename) {
        this.title = BracketsApp.TITLE;
        this.script_fname = basename + "/brackets_extensions.js";
        this.html_fname = basename + "/../../brackets/src/index.html";
        set_default_size (800, 600);

        create_widgets ();
        connect_signals ();
        this.script_input.grab_focus ();
    }

    private void create_widgets () {
        this.script_input = new Entry ();
        this.web_view = new Frame (this.script_fname);
        var scrolled_window = new ScrolledWindow (null, null);
        scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scrolled_window.add (this.web_view);
        var vbox = new VBox (false, 0);
        vbox.pack_start (this.script_input, false, true, 0);
        vbox.add (scrolled_window);
        add (vbox);
    }

    private void connect_signals () {
        this.destroy.connect (Gtk.main_quit);
        this.script_input.activate.connect (on_activate);
        this.web_view.title_changed.connect ((source, frame, title) => {
            this.title = "%s - %s".printf (title, BracketsApp.TITLE);
        });
    }

    private void on_activate () {
        var script = "console.log(" + this.script_input.text + ")";

        this.web_view.execute_script (script);
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
