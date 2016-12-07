using Plank;
using Cairo;

namespace Picky {
	
	public class PickyDockItem : DockletItem {
		
		Gtk.Clipboard clipboard;

		Gee.ArrayList<Color?> colors;

		int cur_position = 0;

		ColorSpecType type = ColorSpecType.HEX;

		GLib.File palette;
		
		Gdk.Pixbuf icon_pixbuf;


		public PickyDockItem.with_dockitem_file(GLib.File file) {
			GLib.Object(Prefs: new PickyPreferences.with_file(file));
		}


		construct {

			Logger.initialize("picky");
			Logger.DisplayLevel = LogLevel.NOTIFY;
			unowned PickyPreferences prefs = (PickyPreferences) Prefs;
			
			Icon = "resource://" + Picky.G_RESOURCE_PATH + "/icons/color_picker.png";
			CountVisible = false;

			try {
				icon_pixbuf = new Gdk.Pixbuf.from_resource(Picky.G_RESOURCE_PATH + "/icons/color_picker.png");
			}
			catch (Error e) {
				warning("Error: " + e.message);
			}
			
			clipboard = Gtk.Clipboard.get(Gdk.Atom.intern("CLIPBOARD", true));
			
			switch (prefs.Format) {
				case "rgb":
					type = ColorSpecType.RGB;
					break;
				case "x11name":
					type = ColorSpecType.X11NAME;
					break;
				case "hex":
				default:
					type = ColorSpecType.HEX;
					break;
			}

			colors = new Gee.ArrayList<Color?>();


			var filepath = GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, Environment.get_home_dir(), Picky.PALETTE_FILE);
			palette = GLib.File.new_for_path(filepath);

			load_palette();

			updated();
		}


		~PickyDockItem () {
			save_palette();
		}



		protected override void draw_icon(Plank.Surface surface) {

			Color color;
			if (colors.size == 0) {
				return;
			}
			else if (cur_position == 0 || cur_position > colors.size) {
				color = colors.get(colors.size - 1);
			}
			else {
				color = colors.get(cur_position - 1);
			}

			Cairo.Context ctx = surface.Context;
			/* var pixbuf = color.get_pixbuf(); */

			Gdk.Pixbuf pb = icon_pixbuf.scale_simple(surface.Width, surface.Height, Gdk.InterpType.BILINEAR);
			Gdk.cairo_set_source_pixbuf(ctx, pb, 0, 0);
			ctx.paint();

			ctx.set_line_width(1);
			ctx.set_tolerance(0.1);

			ctx.set_source_rgb(color.red, color.green, color.blue);
			ctx.arc(surface.Width / 2, surface.Height / 2, surface.Width / 6, 0, 2 * Math.PI);

			ctx.fill();
			surface.Internal.mark_dirty();
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

			Count = colors.size;
			save_palette();

			/* needs_redraw(); */
			reset_icon_buffer();
		}



		protected override AnimationType on_scrolled(Gdk.ScrollDirection direction, Gdk.ModifierType mod, uint32 event_time) {
			
			switch (direction) {
				case Gdk.ScrollDirection.UP:
					if (++cur_position >= colors.size) {
						cur_position = 0;
					}
					break;
				case Gdk.ScrollDirection.DOWN:
					if (--cur_position < 0) {
						cur_position = colors.size - 1;
					}
					break;
			}

			copy_entry_at(cur_position);
			/* needs_redraw(); */
			reset_icon_buffer();

			return AnimationType.NONE;
		}



		void add_color(Color color) {

			unowned PickyPreferences prefs = (PickyPreferences) Prefs;

			if (has_color(color)) {
				return;
			}

			colors.add(color);

			while (colors.size > prefs.MaxEntries) {
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


		/* void copy_entry() { */
		/* 	if (cur_position == 0) { */
		/* 		copy_entry_at(colors.size); */
		/* 	} */
		/* 	else { */
		/* 		copy_entry_at(cur_position); */
		/* 	} */
		/* } */


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
					State = ItemState.URGENT;
					Logger.notification("Pcked a color: " + color.get_string(type));
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

				var label = color.get_string(type);
				if (type != ColorSpecType.X11NAME) {
					label += " - %s".printf(color.to_x11name());
				}

				var item = create_menu_item_with_pixbuf(label, color.get_pixbuf(16), true);
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
