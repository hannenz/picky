using Gtk;
using Gdk;
using Cairo;

namespace Picky {

	public class PickerWindow : Gtk.Window {


		protected Gdk.Window window;

		protected Gdk.Display display;

		protected DeviceManager manager;

		protected Gdk.Device mouse;

		protected Gdk.Device keyboard;

		protected Gtk.DrawingArea preview;

		protected ColorSpecType color_format;

		protected string color_string;

		protected Color current_color;

		protected Clipboard clipboard;


		// Constants 
		protected const int previewSize = 150;
		protected const double minPreviewScale = 1;
		protected const double maxPreviewScale = 10;
		protected double previewScale = 4;

		public signal void picked(Color color_string);

		/**
		 * Constructor
		 */
		public PickerWindow(ColorSpecType type) {
			Object(type: Gtk.WindowType.POPUP);

			color_format = type;

			skip_pager_hint = true;
			skip_taskbar_hint = true;
			decorated = false;

			this.add_events(
				EventMask.KEY_PRESS_MASK |
				EventMask.BUTTON_PRESS_MASK |
				EventMask.SCROLL_MASK
			);

			this.key_press_event.connect( (event_key) => {
				switch (event_key.keyval){
					case 32:
						pick();
						break;

					default:
						close_picker ();
						break;

				}
				return false;
			});

			this.button_press_event.connect( (event_button) => {
				if (event_button.type == EventType.BUTTON_PRESS) {
					switch (event_button.button) {
						case 1:
						default:
							pick();
							close_picker();
							break;
						case 3:
							pick();
							break;
					}
				}
				return true;
			});

			this.scroll_event.connect( (event_scroll) => {
				switch (event_scroll.direction) {
					case ScrollDirection.UP:
						if (previewScale < maxPreviewScale) {
							previewScale += 1;
						}
						break;
					case ScrollDirection.DOWN:
						if (previewScale > minPreviewScale) {
							previewScale -= 1;
						}
						break;
				}
				return true;
			});


			preview = new Gtk.DrawingArea();
			preview.set_size_request(previewSize, previewSize);
			preview.draw.connect(on_draw);
			this.add(preview);

			window = Gdk.get_default_root_window();
			display = Display.get_default();
			manager = display.get_device_manager();
			mouse = manager.get_client_pointer();
			if (mouse == null) {
				error("Could not get device (mouse)");
			}
			keyboard = mouse.get_associated_device();
			if (keyboard == null) {
				error("Could not get device (keyboard)");
			}

			clipboard = Gtk.Clipboard.get_for_display(display, Gdk.SELECTION_CLIPBOARD);


			Idle.add( () => {
				pick_color();
				return true;
			});

			this.show_all();
		}




		public void open_picker () {

			var crosshair = new Gdk.Cursor.for_display(display, Gdk.CursorType.CROSSHAIR);

			EventMask event_mask_mouse = 
				EventMask.BUTTON_PRESS_MASK |
				EventMask.BUTTON_RELEASE_MASK |
				EventMask.POINTER_MOTION_MASK |
				EventMask.SCROLL_MASK
			;
			EventMask event_mask_keyboard =
				EventMask.KEY_PRESS_MASK |
				EventMask.KEY_RELEASE_MASK
			;

			this.mouse.grab(this.get_window(), Gdk.GrabOwnership.APPLICATION, false, event_mask_mouse, crosshair, Gdk.CURRENT_TIME);
			this.keyboard.grab(this.get_window(), Gdk.GrabOwnership.APPLICATION, false, event_mask_keyboard, null, Gdk.CURRENT_TIME);
			this.show_all();
		}




		protected void close_picker () {
			this.mouse.ungrab(Gdk.CURRENT_TIME);
			this.keyboard.ungrab(Gdk.CURRENT_TIME);
			this.hide();
		}

		

		protected void pick() {

			clipboard.set_text(color_string, -1);
			picked(current_color);
		}



		private bool on_draw(Context ctx) {
			int x, y;

			window.get_device_position(mouse, out x, out y, null);

			Pixbuf pixbuf = Gdk.pixbuf_get_from_window(this.window, x, y, 1, 1);
			weak uint8[] pixel = pixbuf.get_pixels();

			current_color.red = (double)pixel[0] / 255.0;
			current_color.green = (double)pixel[1] / 255.0;
			current_color.blue = (double)pixel[2] / 255.0;

			switch (color_format) {
				case ColorSpecType.HEX: 
					color_string = "#" + pixel[0].to_string("%02X") + pixel[1].to_string("%02X") + pixel[2].to_string("%02X");
					break;
				case ColorSpecType.RGB:
				default:
					color_string = "rgb(%u,%u,%u)".printf(pixel[0], pixel[1], pixel[2]);
					break;
			}

			/** 
			 * Calculate light/dark text color depending on the bg color
			 * Algorithm from: [http://stackoverflow.com/a/1855903]
			 */
			double d = 0.25;
			double a = 1 - ( 0.299 * pixel[0] + 0.587 * pixel[1] + 0.114 * pixel[2])/255;
			if (a >= 0.5) {
				d = 1.0;
			}

			Pixbuf _pixbuf = Gdk.pixbuf_get_from_window(window, x - (int)(previewSize / (2 * previewScale)), y - (int)(previewSize / (2* previewScale)), (int)(previewSize / previewScale), (int)(previewSize / previewScale));
			Pixbuf pixbuf2 = _pixbuf.scale_simple(previewSize, previewSize, InterpType.TILES);
			Gdk.cairo_set_source_pixbuf(ctx, pixbuf2, 0, 0);
			ctx.paint();

			ctx.set_line_width(1);
			ctx.set_tolerance(0.1);
			ctx.set_source_rgb(d,d,d);
			ctx.arc(previewSize / 2, previewSize / 2, 3, 0, 2 * Math.PI);
			ctx.stroke();

			ctx.rectangle(0, 0, previewSize, previewSize);
			ctx.stroke();
			ctx.set_source_rgb(0, 0, 0);
			ctx.rectangle(1, 1, previewSize - 2, previewSize - 2);
			ctx.stroke();

			ctx.set_source_rgba(current_color.red, current_color.green, current_color.blue, 1.0);
			ctx.rectangle(2, previewSize - 24, previewSize - 4, 22);
			ctx.fill();

			ctx.set_source_rgb(d, d, d);
			ctx.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
			ctx.set_font_size (13.0);
			ctx.move_to (4, previewSize - 8);
			ctx.show_text (color_string + "/%.1f".printf(previewScale));
			return false;
		}


		public void pick_color() {

			// Update the preview
			preview.queue_draw();

			// Move window (track mouse position)
			int x, y, posX, posY, offset = 50;

			window.get_device_position(mouse, out x, out y, null);
			posX = x + offset;
			posY = y + offset;

			if (posX + previewSize >= display.get_default_screen().get_width()) {
				posX = x - (offset + previewSize);
			}
			if (posY + previewSize >= display.get_default_screen().get_height()) {
				posY = y - (offset + previewSize);
			}

			move(posX, posY);
		}
	}
}
