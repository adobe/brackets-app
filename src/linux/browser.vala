using Gtk;
using WebKit;

public class Browser : Window {

    protected WebView web_view;
    protected VBox vbox;

    public Browser() {
        set_default_size (800, 600);
    }

    public virtual void init() {
        create_widgets();
        connect_signals();
        show_all();
    }

    public void open(string url) {
        web_view.open(url);
    }

    protected virtual WebView createWebView() {
        return new WebView();
    }

    public WebView getWebView() {
        return web_view;
    }

    protected virtual void create_widgets() {
        web_view = createWebView();
        var scrolled_window = new ScrolledWindow (null, null);

        scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scrolled_window.add (web_view);

        vbox = new VBox (false, 4);
        vbox.add (scrolled_window);
        add (vbox);
    }

    protected virtual void connect_signals() {
        this.web_view.title_changed.connect ((source, frame, title) => {
            this.title = "%s".printf (title);
        });
    }
}

