using Plank;

namespace Picky {
	
	public class PickyDockItem : DockletItem {
		
		Gtk.Clipboard clipboard;

		Gee.ArrayList<Color?> colors;

		int cur_position = 0;

		ColorSpecType type = ColorSpecType.HEX;

		GLib.File palette;


		public PickyDockItem.with_dockitem_file(GLib.File file) {
			GLib.Object(Prefs: new PickyPreferences.with_file(file));
		}


		construct {

			unowned PickyPreferences prefs = (PickyPreferences) Prefs;
			
			Icon = "preferences-color";
			try {
				ForcePixbuf = new Gdk.Pixbuf.from_file("/home/hannenz/picky/color_picker.png");
			} catch (Error e) {
				error ("Could not load icon");
			}

			clipboard = Gtk.Clipboard.get(Gdk.Atom.intern("CLIPBOARD", true));
			if (prefs.Format == "rgb") {
				type = ColorSpecType.RGB;
			}

			colors = new Gee.ArrayList<Color?>();
			load_palette();

			updated();
		}

		~PickyDockItem () {
			save_palette();
		}


		void updated() {
			if (colors.size == 0) {
				Text = "No colors picked yet..";
			}
			else if (cur_position == 0 || cur_position > colors.size) {
				Text = get_entry_at(colors.size);
			}
			else {
				Text = get_entry_at(cur_position);
			}

			save_palette();
		}


		void add_color(Color color) {

			unowned PickyPreferences prefs = (PickyPreferences) Prefs;

			if (has_color(color)) {
				return;
			}

			colors.add(color);

			while (colors.size >= prefs.MaxEntries) {
				colors.remove_at(0);
			}

			cur_position = colors.size;
			updated();
		}

		
		bool has_color(Color color) {
			foreach (Color col in colors) {
				if (col.red == color.red && col.green == color.green && col.blue == color.blue) {
					return true;
				}
			}
			return false;
		}


		string get_entry_at(int pos) {
			Color color = colors.get(pos - 1);
			return color.get_string(type);
		}


		void copy_entry_at(int pos) {
			if (pos < 1 || pos > colors.size) {
				return;
			}
			var color = colors.get(pos - 1 );
			string str = color.get_string(type);
			clipboard.set_text(str, (int)str.length);
			
			updated();
		}


		void copy_entry() {
			if (cur_position == 0) {
				copy_entry_at(colors.size);
			}
			else {
				copy_entry_at(cur_position);
			}
		}


		void clear() {
			clipboard.set_text("", 0);
			clipboard.clear();
			colors.clear();
			cur_position = 0;
			updated();
		}


		protected override AnimationType on_clicked(PopupButton button, Gdk.ModifierType mod, uint32 event_time) {

			if (button == PopupButton.LEFT) {

				var picker_window = new Picky.PickerWindow(type);
				picker_window.picked.connect( (color) => {
					add_color(color);
				});
				picker_window.open_picker();

				return AnimationType.BOUNCE;
			}
			return AnimationType.NONE;
		}


		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items() {
			var items = new Gee.ArrayList<Gtk.MenuItem>();

			for (var i = colors.size; i > 0; i--) {
				Color color = colors.get(i - 1);

				var item = create_menu_item_with_pixbuf("%s - %s".printf(color.get_string(type), color.to_x11name()), color.get_pixbuf(16), true);
				var pos = i;
				item.activate.connect( () => {
					copy_entry_at(pos);
				});
				items.add(item);
			}

			if (colors.size > 0) {
				var item = create_menu_item("_Clear", "edit-clear-all", true);
				item.activate.connect(clear);
				items.add(item);
			}

			return items;
		}


		protected bool load_palette() {
			try {
				var filepath = GLib.Path.build_path(Path.DIR_SEPARATOR_S, Environment.get_home_dir(), ".palettes", "1.default");
				palette = GLib.File.new_for_path(filepath);

				if (!palette.query_exists()) {
					return false;
				}

				string line;
				var dis = new DataInputStream(palette.read());

				while ((line = dis.read_line(null)) != null) {
					var color = Color();

					if (color.parse(line)) {
						add_color(color);
					}
				}
			}
			catch (Error e) {
				return false;
			}
			return true;
			
		}


		protected bool save_palette() {
		
			try {
				if (palette.query_exists()) {
					palette.delete();
				}

				// Don't save empty palettes
				if (colors.size > 0) {

					var dos = new DataOutputStream(palette.create(FileCreateFlags.REPLACE_DESTINATION));

					foreach (Color color in colors) {
						dos.put_string(color.get_string(type) + "\n");
					}
				}
			}
			catch (Error e) {
				return false;
			}

			return true;
		}
	}
}	
