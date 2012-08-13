public class WindowManager {
    private int win_counter = 0;
    private string basename = "";
    private DateTime startup_time;

    public WindowManager(string basename) {
        startup_time = new DateTime.now_local();
        this.basename = basename;
    }

    public BracketsWindow populate_window() {
        var win = new BracketsWindow(basename, startup_time);

        win.close_window.connect((source) => {
            close_window(win);
        });

        win.new_window.connect((source) => {
            var new_win = populate_window();
            new_win.init();

            return new_win.getWebView();
        });

        win_counter++;
        return win;
    }

    public void close_window(BracketsWindow win) {
        win_counter--;

        if (win_counter == 0) {
            Gtk.main_quit();
        }
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        string basename = GLib.Path.get_dirname(args[0]);
        var manager = new WindowManager(basename);
        var win = manager.populate_window();

        win.init();
        Gtk.main();

        return 0;
    }
}
