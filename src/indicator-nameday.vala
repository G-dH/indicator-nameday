/*# © 2011-2020 GdH <georgdh@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

using Gtk;
using AppIndicator;

public Data data;
public string APPNAME;
//public string app_version;
public SearchNamedays search_nd;
//public string app_path;
//public string app_dir;
//public string names_dir;
//const  string GETTEXT_PACKAGE = "indicator-nameday";


public class IndicatorNameday : GLib.Object {
    private bool timeout = false;
    private int idle;
    private DateTime selected_date;
    public SearchDialog search_dialog = null;

    private string desktop_filename = 
                "%s/.config/autostart/indicator-nameday.desktop".printf(
                Environment.get_variable("HOME")
                );
        // Pomocí GLib.Environment si přečtu systémovou proměnnou $HOME
        // printf pro konverzi proměnných do stringu a formátování

    private Indicator indicator;
    private string name_today;
    private DateTime today;
    private DateTime last_day = 
            new DateTime.now_local().add_days(1); // +1 kvůli první aktualizaci

    private Gtk.MenuItem[] next_nm_items;


    public void build_indicator(string[] args) {

        APPNAME = "Indicator NameDay";
//        app_version = "0.3.5";

        
//        try {
//            app_path = FileUtils.read_link("/proc/self/exe");
//        } catch (FileError e) {stderr.printf(e.message); }

//        app_dir  = Regex.split_simple("/[^/]*$", app_path)[0];
//        names_dir = app_dir;

        // lokalizaci řeším automaticky podle systémové proměnné LANG
        // pokud není soubor se jmény nalezen, použije se čeština
        unowned string? locale;
        string loc;
        // z main jsem si předal pole args, ve kterém
        // je rozsekaný příkaz, kterým byl program spuštěn
        if (args[1] != null) {
            loc = args[1];
        }
        else {
            locale = (Environment.get_variable("LANGUAGE"));
            if (locale == null) locale = (Environment.get_variable("LANG"));
            if (locale == null) loc = "cs";
            else loc = (locale.split("_"))[0];
        }
        // proměnná data bude odkazovat na instanci třídy Data
        // s 
        data = new Data(loc);
        indicator = new Indicator(APPNAME, "indicator-nameday-status",
            IndicatorCategory.APPLICATION_STATUS);
            indicator.set_status(IndicatorStatus.ACTIVE);
        // signály se oproti PyGObject/PyGTK napojují přes vlastní objekty:
        indicator.scroll_event.connect ((source, x ,direction)
                                => {on_scroll_event(direction);});
        // výše je také vidět použití anonymní lambda funkce
        // oproti PyGObject/PYGtk není vůbec třeba přebírat argumenty, které signál posílá,
        // nebo jich můžete odebrat pouze část.
        indicator.set_menu(build_menu());
        Timeout.add_seconds(60, update_names);
        // každou minutu se bude kontrolovat, zda již není další den
    }

    public void on_scroll_event(uint direction) {
        // Otáčení kolečka nad indikátorem v panelu,
        // bude možno procházet další dny
        // Aby uživatel viděl včerejší, nebo zítřejší svátek,
        // stačí pootočit kolečkem myši a nemusí do menu
        if (! timeout) {
            // v proměnné timeout bude informace, zda se již počítá čas
            // po kterém se na panel vrátí aktuální svátek
            // pokud timeout neběží, spustí se:
            Timeout.add_seconds(1, timeout_call);
            selected_date = last_day;
            timeout = true;
        }
        if (direction == 0) {
            selected_date = selected_date.add_days(-1);
        } else {
            selected_date = selected_date.add_days(1);
        }
        var d = selected_date.get_day_of_month();
        var m = selected_date.get_month();
        indicator.label = "%s %02d.%02d.".printf(
                data.names[m-1,d], d, m
            );
        idle = 0; // při každém otočení kolečka se časomíra resetuje
    }

    public bool timeout_call() {
        // při otočení kolečka nad indikátorem se současně
        // začne počítat čas
        idle++;
        if (idle > 4) {
            // a po pěti sekundách se vrátí
            // jméno pro aktuální den
            timeout = false;
            indicator.label = name_today;
            // časovač funguje, dokud mu nevrátíte false
            return false;
        }
        return true;
    }

    public Gtk.Menu build_menu() {
        // výroba menu pro indikátor
        var menu = new Gtk.Menu();

        // Svátky na další dny
        // Jednotlivé položky menu jsou plněny
        // řetězci ze seznamu podle lokalizace ->
        var item = new Gtk.MenuItem.with_mnemonic(_("Names for next days"));
        var smenu = new Gtk.Menu();
        item.set_submenu(smenu);
        menu.append(item);
        // proměnná next_nm_items bude obsahovat pole
        // popisků položek menu, které budou zobrazovat
        // svátky na další dny
        next_nm_items = {};

        // zatím se jen vytvoří položky do menu
        // plnit se budou až za chvíli
        for ( int i=1; i<15; i++) {
            item = new Gtk.MenuItem.with_label("");
            smenu.append(item);
            // protože se budou zobrazovat svátky i tři dny zpět,
            // separátory se orámuje svátek aktuální
            if ((i==3) | (i==4)) {
                smenu.append(new SeparatorMenuItem());
            }
            next_nm_items += item;
            }
        update_names();

        // Hledat datum
        item = new Gtk.MenuItem.with_mnemonic (_("Search"));
        item.activate.connect(search_date);
        menu.append(item);

        // Dny pracovního klidu
        item  = new Gtk.MenuItem.with_mnemonic (_("Public Holidays"));
        item.set_submenu(data.holidays_menu);
        menu.append(item);


/*        foreach (string h in data.holidays) {
            item = new Gtk.MenuItem.with_mnemonic(h);
            smenu.append(item);
            if (":" in h){
                smenu.append(new Gtk.SeparatorMenuItem());
            }
        }
*/
        menu.append(new Gtk.SeparatorMenuItem());

        // Lokalizace
        item = new Gtk.MenuItem.with_mnemonic(_("Names Pack"));
        item.set_submenu( get_names_set_menu () );
        menu.append(item);
        Gtk.CheckMenuItem chitem;       

        // Spustit při přihlášení
        chitem = new Gtk.CheckMenuItem.with_mnemonic(_("Autostart"));
        if (FileUtils.test(desktop_filename, FileTest.EXISTS)) {
            chitem.set_active(true);
        }
        chitem.activate.connect(launch_at_startup);
        menu.append(chitem);

        // O aplikaci
        item = new Gtk.MenuItem.with_mnemonic(_("About"));
        item.activate.connect(() => {
            var about = new About();
            about.run();
            about.destroy();
            });
        menu.append(item);

        menu.append(new Gtk.SeparatorMenuItem());

        // Ukončit
        item = new Gtk.MenuItem.with_mnemonic(_("Quit"));
        item.activate.connect(Gtk.main_quit);
        menu.append(item);
        menu.show_all();
        return menu;
    }

    private Gtk.Menu get_names_set_menu () {
        var menu = new Gtk.Menu();
        try {
            FileEnumerator enumerator = GLib.File.new_for_path(@"$DATADIR/db").enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS, 
                null);
            FileInfo info = null;
        
            var re = new GLib.Regex (".names$");
            while ((info = enumerator.next_file ()) != null) {
                var name = info.get_name ();
                if (re.match (name)){
                    var name_split = name.split(".");
                    var item = new Gtk.CheckMenuItem.with_label(name_split[0]);
                        item.set_draw_as_radio (true);
                    if (data.loc == name_split[0]) item.activate ();
                    item.activate.connect(() => {
                        indicator.get_menu().destroy();
                        var loc = name_split[0];
                        data = new Data(loc);
                        last_day = last_day.add_days(1);
                        indicator.set_menu(build_menu());
                        update_names();
                    });
                    menu.append (item);
                }
            }
        } catch (Error e) {
            stderr.printf("%s \n", e.message);
        }
        return menu;
    }

    public bool update_names() {
        // plnění indikátoru potřebnými jmény
        // pokud je třeba aktualizovat, je třeba,
        // aby se proměnné today a last_day lišily
        today = new DateTime.now_local();
        var t = today.get_day_of_month();
        var l = last_day.get_day_of_month();
        if (t != l) {
            int d = today.get_day_of_month();
            int m = today.get_month();
            name_today = data.names[m-1,d];
            indicator.label = name_today;

            DateTime dt;
            int i = -3;
            string name;
            foreach (var lbl in next_nm_items) {
                dt = today.add_days(i);
                int td = dt.get_day_of_month();
                name = data.names[dt.get_month()-1, td];

                lbl.set_label(
                    "%02d. %s     \t%s".printf(
                        td,
                        dt.format("%a"),
                        name
                        )
                    );
                i++;
            } 
        }
        last_day = today;
        return true;
    }

    public void launch_at_startup() {
        // položka "Spustit při přihlášení" zapisuje/maže
        // desktopový spouštěč do ~/.config/autostart/
        // nezáleží na tom, odkud byl program spuštěn, 
        // do spouštěče bude zapsána cesta k právě spuštěnému
        // s přepínačem podle aktuální lokalizace
        try {
            
            if (FileUtils.test (desktop_filename, FileTest.EXISTS)){
                FileUtils.remove (desktop_filename);
            } else {
                var desktop_content = "[Desktop Entry]
Type=Application
Name=Indicator NameDay
Exec=indicator-nameday %s
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=false".printf(data.loc);
                FileUtils.set_contents(desktop_filename, desktop_content);
            }

        } catch (FileError e) {
            stderr.printf ("%s\n", e.message);
        }
    }
    
    public void search_date() {
        // metoda položky menu "Hledat datum"
        // vytvoří okno a rovnou nechá
        // vyhledat aktuální jméno
        if (search_dialog == null) search_dialog = new SearchDialog();
        search_dialog.show_all();
        search_dialog.present();
        search_dialog.search_entry.set_text(name_today);
        // grab_focus aktivuje vstupní pole dialogu
        // a současně označí obsažený text,
        // takže můžete rovnou psát
        search_dialog.search_entry.grab_focus();
        search_dialog.response.connect (() => {search_dialog.destroy();
                                search_dialog = null;});
    }
}

public class SearchDialog : Gtk.Dialog {
    // Třída SearchDialog je odvozena od Gtk.Dialog (ta je odvozena od Gtk.Window)
    public Gtk.Entry search_entry;
    public Gtk.Label[] result;
    public Gtk.Calendar calendar;
    public bool calendar_sel_signal_block = false;

    public SearchDialog() {
        // Metoda stejného jména jako třída
        // se provede při inicializaci.
        // Definice vlastností okna: 
        this.title = _("Name Days - Search");
        this.border_width = 10;
        this.set_keep_above(true);
        this.stick();
        this.set_size_request(280, 80);
        this.set_resizable(false);
        this.set_position(Gtk.WindowPosition.MOUSE);
        create_widgets();
        connect_signals();
        search_nd = new SearchNamedays();
    }

    private void create_widgets () {
        // Výroba okna a widgetů
        search_entry = new Gtk.Entry();
        search_entry.expand = true;
        search_entry.set_placeholder_text(_("Enter Name"));
        //var search_label = new Gtk.Label.with_mnemonic ("Prdel");
        //search_label.mnemonic_widget = search_entry;
        result = {new Gtk.Label(""), new Gtk.Label("")};
        result[0].set_alignment(0, 0.5f);
        result[1].set_alignment(0, 0.5f);
        calendar = new Gtk.Calendar();
        calendar.show_details = false;
        calendar.set_detail_func(calendar_detail);

        // Poskládání dohromady
        var grid = new Gtk.Grid();
        grid.column_homogeneous = false;
        grid.column_spacing = 10;
        grid.row_spacing = 10;
        //grid.attach( search_label, 0, 0, 2, 1);
        grid.attach( search_entry, 0, 0, 6, 1);
        grid.attach( result[0], 0, 1, 6, 1);
        grid.attach( result[1], 0, 2, 6, 1);
        grid.attach( calendar, 0, 3, 6, 6);
        var content = (Box)get_content_area();
        content.pack_start (grid, false, true, 0);

        add_button (_("_Close"), ResponseType.CLOSE);

    }

    private void connect_signals() {
        // Připojení signálu změny v poli pro zadání jména
        // Vyhledávat se bude okamžitě po zadání/smazání
        // každého nového znaku
        search_entry.changed.connect(() =>
            {
                var et =  search_entry.text.strip();
                if (et != "")
                    search(et);

            // Pokud není zadáno nic, vyhledá se nesmysl
            // aby se zobrazila informace, že nebylo nic nalezeno
            // místo aby se vypsaly dva první svátky v roce (nic je ve všem ;)
            else search("#");
        });
        search_entry.activate.connect (() => {search_entry.grab_focus();});
        calendar.day_selected.connect (() => {
                    if ( ! calendar_sel_signal_block)
                        search_entry.set_text(
                            data.names[calendar.month, calendar.day]);
                }
        );

 /*       calendar.day_selected_double_click.connect (() =>
                            {
                                calendar.mark_day(calendar.day);
                            } );
*/

    }

    public void search(string pattern) {
        // metoda vyhledávání zadaného řetězce

        search_nd.search_pattern(pattern);
        if (search_nd.results < 2)  result[1].set_label("");
        if (search_nd.results == 0) result[0].set_label(_("Not found"));
        else {
            calendar_sel_signal_block = true;
            calendar.day = search_nd.days[0];
            calendar.month = search_nd.months[0];
            calendar_sel_signal_block = false;
            for (int i=0; i<search_nd.results; i++){
                result[i].set_text("%02d.%02d.  %s".printf(search_nd.days[i], search_nd.months[i]+1, search_nd.names[i]));
            }
        }
        if ((search_nd.results == 0) & (pattern.length == 4)) { //po zadání letopočtu se najde velikonoční pondělí pro tento rok
            int yr = int.parse(pattern);
            if (yr != 0) {
                var em = Easter.get_date(yr,1);

                result[0].set_label("%02d.%02d.  %s %04d".printf(
                    em[2], em[1], _("Easter Monday"), em[0] ));

                calendar_sel_signal_block = true;
                calendar.year = em[0];
                calendar.month = em[1]-1;
                calendar.day = em[2];
                calendar_sel_signal_block = false;
            }
        }

    }

    public string calendar_detail(Gtk.Calendar widget, uint year, uint month, uint day) {
        // if (day == 15) return "prdel plná vody";
        return null;
    }
}

public class SearchNamedays : GLib.Object {
    public int[]     days = {};
    public int[]     months = {};
    public string[]  names = {};
    private string[] di = {"(ž|Ž|z|Z)","(š|Š|s|S)","(č|Č|c|C)","(ř|Ř|r|R)",
              "(í|Í|i|I)","(á|Á|a|A)","(ě|Ě|e|E|é|É)","(ý|Ý|y|Y)",
              "(ť|Ť|t|T)","(ď|Ď|d|D)","(ň|Ň|n|N)","(ú|ů|Ů|u|U)",
              "(ľ|Ľ|l|L)"};
    public int count;
    public int results;

    public void search_pattern (string pattern, int count=2) {

        var pat = pattern;
        int[] _days = {};
        int[] _months = {};
        string[] _names = {};

        try {

            foreach (string i in di) {
                var re = new Regex(i);
                pat = re.replace(pat, -1, 0, i);
            }

            var flag = RegexMatchFlags.ANCHORED;
            results = 0; // tato proměnná bude počítat nalezené shody
            var re = new Regex(pat, RegexCompileFlags.CASELESS);
            for (int i = 0; i < 2; i++) {
                for (int mnt=0; mnt < 12; mnt++) {
                    for (int day=1; day < 32; day++) {
                        if (results == count) {
                            break;
                        }
                        var name = data.names[mnt, day];
                        if (name == null) continue;
                        if ((re.match( name, flag)) & !(name in _names)) {
                            var r = new Regex(pat+"$", RegexCompileFlags.CASELESS|RegexCompileFlags.ANCHORED);
                            if (    (results != 0)
                                  & (r.match (name)) ) {

                                int[] d = {day,};
                                foreach (int x in _days) d+=x;
                                int[] m = {(mnt),};
                                foreach (int x in _months) m+=x;
                                string[] n = {name,};
                                foreach (string x in _names) n+=x;
                                _days = d;
                                _months = m;
                                _names = n;
                            }
                            else {
                                _names += name;
                                _days += day;
                                _months += (mnt);
                            }
                            results ++;
                        }
                    }
                }
            // Pokud program došel sem, nebyly nalezeny oba záznamy,
            // které umí okno vyhledávání zobrazit
            // a zkusí se to ještě jednou, bez ohledu na místo výskytu
            // hledaného vzoru:
                flag = RegexMatchFlags.PARTIAL;
            }
            // Nebylo-li nalezeno nic a zadaný řetězec má 4 znaky,
            // zkusí se převést na číslo a vyhledat Velikonční pondělí
            // v pro rok, který číslo reprezentuje

        }   catch (RegexError e) { // mám v try bloku celou metodu
            // pokud někde něco neprojde, prostě se to zahodí
            // catch funkce může být i prázdná
        }
        days = _days;
        months = _months;
        names = _names;
    }
}


public class Easter {
    public static int[] get_date (int year, int offset=1) {
    // statická metoda umožní volat get_date
    // bez vytváření nové instance třídy EasterMonday

        // Speciální knihovnu na Velikonoce jsem pro Vala nenašel,
        // ale pan Gauss to kdysi matematicky vyjádřil celkem spolehlivě.
        // Tohle je jedna z adaptací vzorce, počítá neděli
        int month = 3;
        int g = year % 19 + 1;
        int c = year / 100 + 1;
        int x = ( 3 * c ) / 4 - 12;
        int y = ( 8 * c + 5 ) / 25 - 5;
        int z = ( 5 * year ) / 4 - x - 10;
        int e = ( 11 * g + 20 + y - x ) % 30;
        if (e == 24) e++;
        if ((e == 25) && (g > 11)) e++;
        int n = 44 - e;
        if (n < 21) n = n + 30;
        int day = ( n + 7 + offset ) - ( ( z + n ) % 7 );
        // ke dni se připočítává offset pro pátek, či pondělí
        if ( day > 31 ){
            day = day - 31;
            month = 4;
        }
        return { year, month, day };
    }

}

public class About : AboutDialog {
    // Okno "O aplikaci"
    public About() {
        this.set_program_name(APPNAME);
        this.set_version(VERSION);
        this.set_copyright("© 2011 - 2020 GdH");
        this.set_comments(_("Name days and public holidays panel indicator"));
        this.set_website("http://gdhnotes.blogspot.com");
        this.set_website_label("GdH Notes");
        this.set_license(@"$APPNAME is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.");
    }
}

public class Data : GLib.Object {
    public Gtk.Menu  holidays_menu;
    public string[,] names;
    public string    loc;
    public int[,]    marked_days;
    public string[,] names_ar;
    // při vytvoření instance této třídy se naplní proměnné
    // podle zvolené lokalizace
    // a v seznamu dnů pracovního klidu se doplní
    // datum velikonočního pondělí


    public static Data(string _loc) {
        loc = _loc;
        if ( (names = load_names ()) == null) {
            stderr.printf("Loading 'cs.*' pack...\n");
            loc = "cs";
            names = load_names ();
            if (names == null) Process.exit(1);

        }
        holidays_menu = get_holidays_menu ();
    }

    private string[,]? load_names () {
        try {
            var filename = "%s/db/%s.names".printf(DATADIR, loc);
            if ( ! GLib.FileUtils.test(filename, GLib.FileTest.EXISTS)){
                stderr.printf("Error: File %s doesn't exist!\n",filename);
                return null;
            }

            var re = new Regex("^#");
        
            var file = GLib.FileStream.open(filename, "r");
            assert (file != null);
            string line;
            names_ar = new string[12,32];
            int d = 0;
            int m = -1;
            while ((line = file.read_line()) != null){
                if ((d>31) | (m>11)) return null;
                if (line.strip() == "") continue;
                if (re.match(line)) {
                    d = 0;
                    names_ar[++m,0] = line.substring(1,-1).strip();
                }
                else {
                    names_ar[m,++d] = line.split(".")[1].strip();
                }
            }
        }
        catch (Error e) {
            stderr.printf ("%s: %s\n", APPNAME, e.message);
            return null;
        }
        return names_ar;
    }

    private Gtk.Menu? get_holidays_menu () {
        var menu = new Gtk.Menu ();
        try {
            var group    = new GLib.Regex(":$");
            var comment  = new GLib.Regex("^#");
            var easterfr   = new GLib.Regex("^@!");
            var eastermo   = new GLib.Regex("^@@");
            var easter = easterfr;
            int eoffset    = 0;
            var filename = "%s/db/%s.holidays".printf(DATADIR, loc);
            if ( ! GLib.FileUtils.test(filename, GLib.FileTest.EXISTS)) return null;

            var file = GLib.FileStream.open(filename, "r");
            assert (file != null);
            string line;
            while ((line = file.read_line()) != null) {
                if (comment.match(line)) continue;
                if (eastermo.match(line)) {
                    eoffset = 1;
                    easter  = eastermo;
                }
                else if (easterfr.match(line)) {
                    eoffset = -2;
                    easter  = easterfr;
                }
                if (eoffset != 0) {
                    var y = new DateTime.now_local().get_year();
                    var e = Easter.get_date(y,eoffset);
                    line = "%02d.%02d.%s %d".printf (e[2], e[1], easter.replace(line, line.length, 0, ""), y);
                    eoffset = 0;
                }

                menu.append (new Gtk.MenuItem.with_label (line));
                if (group.match(line)) {
                    menu.append (new Gtk.SeparatorMenuItem ());
                }
            }
        }
        catch (Error e) {
            stderr.printf ("%s: %s\n", APPNAME, e.message);
            return null;
        }
        return menu;
    }


/*    public void load_events (string file) {
        try {
            var filename = "%s/events".printf(app_dir);
            if ( ! FileUtils.test(filename, FileTest.EXISTS)) return;

            var re = new Regex("^#");
        
            var file = FileStream.open(filename, "r");
            string line;
            
            while ((line = file.read_line()) != null){
                if ( (re.match(line)) | (line.strip() == "")) continue;
                var splt_line = line.split("::");


            }
        } catch (Error e) {}
    }*/
}

public int main(string[] args) {

    Intl.bindtextdomain( GETTEXT_PACKAGE, LOCALEDIR );
    Intl.bind_textdomain_codeset( GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( GETTEXT_PACKAGE );
    Gtk.init(ref args);
    var namedays = new IndicatorNameday();
    namedays.build_indicator(args);
    Gtk.main();
        
    return 0;
}
