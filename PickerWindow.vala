using Gtk;
using Gdk;
using Cairo;

namespace Picky {

	public enum Direction {
		UP,
		DOWN,
		LEFT,
		RIGHT
	}

	public class PickerWindow : Gtk.Window {

		protected Gdk.Window window;
		protected ColorPreview preview;
		protected ColorSpecType color_format;
		protected string color_string;
		protected Clipboard clipboard;
		protected Gdk.Display display;
		protected Gdk.Device mouse;
		protected Gdk.Device keyboard;
		protected int preview_size;
		protected int winposx;
		protected int winposy;

		public signal void picked(Color color_string);

		/**
		 * Constructor
		 *
		 * Consturcts a window containing a color picker preview (ColorPreview)
		 * and set up handlers for keyboard and mouse
		 * 
		 * @param ColorSpecType type			The color format to use (HEX, RGB or X11NAME)
		 * @param int			size			The size of the windo (square)
		 */
		public PickerWindow(ColorSpecType type, int size) {
			Object(type: Gtk.WindowType.POPUP);

			color_format = type;
			preview_size = size;

			skip_pager_hint = true;
			skip_taskbar_hint = true;
			decorated = false;

			this.add_events(
				EventMask.KEY_PRESS_MASK |
				EventMask.BUTTON_PRESS_MASK |
				EventMask.SCROLL_MASK
			);


			// Connect signals

			// Keyboard: SPACE BAR pick color (with SHIFT: keep picking, else pick & close)
			// ESC: Close picker window
			// F9/F10: Change window size (experimental)
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
						set_default_size(preview.size, preview.size);
						break;

					case Gdk.Key.F10:
						preview.size += 10;
						set_default_size(preview.size, preview.size);
						break;

					case Gdk.Key.Down:
						move_pointer(Direction.DOWN);
						break;

					case Gdk.Key.Up:
						move_pointer(Direction.UP);
						break;

					case Gdk.Key.Left:
						move_pointer(Direction.LEFT);
						break;

					case Gdk.Key.Right:
						move_pointer(Direction.RIGHT);
						break;


					default:
						break;

				}
				return false;
			});


			// Mouse:	LEFT CLICK: pick and close
			//			RIGHT CLICK: pick and keep window open
			//			WHEEL UP/DOWN: Zoom preview in/out
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
			preview.size = preview_size;
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
				update_preview();
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

			// Copy current color to clipboard
			clipboard.set_text(preview.color.get_string(color_format), -1);
			// Emit signal
			picked(preview.color);
		}


		public void update_preview() {

			// Update the preview
			preview.queue_draw();

			// Move window (track mouse position)
			int x, y, posX, posY, offset = preview.size / 2;

			window.get_device_position(mouse, out x, out y, null);
			posX = x + offset;
			posY = y + offset;

			if (posX + preview_size >= display.get_default_screen().get_width()) {
				posX = x - (offset + preview_size);
			}
			if (posY + preview_size >= display.get_default_screen().get_height()) {
				posY = y - (offset + preview_size);
			}

			move(posX, posY);
		}

		public void move_pointer(Direction dir) {
			int x,y;
			window.get_device_position(mouse, out x, out y, null);
			switch (dir) {
				case dir.UP:
					y--;
					break;
				case dir.DOWN:
					y++;break;
				case dir.LEFT:
					x--;
					break;
				case dir.RIGHT:
					x++;
					break;
			}

			mouse.warp(Gdk.Screen.get_default(), x, y);
		}
	}
}
