using Gtk;
using Gdk;
using Cairo;

namespace Picky {

	public class PickerWindow : Gtk.Window {

		protected Gdk.Window window;
		protected ColorPreview preview;
		protected ColorSpecType color_format;
		protected string color_string;
		protected Clipboard clipboard;
		protected Gdk.Display display;
		protected Gdk.Device mouse;
		protected Gdk.Device keyboard;

		// Constants 
		protected const int previewSize = 150;

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
					case Gdk.Key.space:
						pick();
						if ((Gdk.ModifierType.SHIFT_MASK & event_key.state) == 0) {
							close_picker();
						}
						break;

					case Gdk.Key.Escape:
						close_picker();
						break;

					case Gdk.Key.F9:
						preview.size -= 10;
						break;
					case Gdk.Key.F10:
						preview.size += 10;
						break;
					default:
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
						preview.scale_up();
						break;

					case ScrollDirection.DOWN:
						preview.scale_down();
						break;
				}
				return true;
			});


			preview = new ColorPreview();
			preview.size = 150;
			this.add(preview);

			window = Gdk.get_default_root_window();
			display = Display.get_default();
			var manager = display.get_device_manager();
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
			picked(preview.color);
		}


		public void pick_color() {

			// Update the preview
			preview.queue_draw();

			// Move window (track mouse position)
			int x, y, posX, posY, offset = 75;

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
