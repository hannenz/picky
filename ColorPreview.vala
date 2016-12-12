using Gtk;
using Gdk;
using Cairo;

namespace Picky {
	
	public class ColorPreview : Gtk.DrawingArea {
		
		public int size { get; set; default = 64; }
		public double scale { get; set; default = 4.0; }
		public double scaling_factor { get; set; default = 1.3333; }
		public double min_scale { get; set; default = 1.0; }
		public double max_scale { get; set; default = 16.0; }
		public Color color {get; set; }
		public ColorSpecType color_format { get; set; default = ColorSpecType.HEX; }
		private Gdk.Window window;
		private Gdk.Device mouse;

		public ColorPreview() {
			
			set_size_request(size, size);

			this.notify["size"].connect( (s, p) => {
				if (size < 20) {
					size = 20;
				}
				if (size > 500) {
					size = 500;
				}
				set_size_request(size, size);
			});

			draw.connect(on_draw);

			window = Gdk.get_default_root_window();
			var display = Display.get_default();
			var manager = display.get_device_manager();
			mouse = manager.get_client_pointer();
		}

		public void scale_up() {
			scale = double.min(scale * scaling_factor, max_scale);
		}
		
		public void scale_down() {
			scale = double.max(scale / scaling_factor, min_scale);
		}

		protected bool on_draw(Context ctx) {

			Gdk.Pixbuf pixel_pb, tmp_pb, pb;
			Color fgcol;
			weak uint8[] pixel;
			int x, y;
			string color_string;

			window.get_device_position(mouse, out x, out y, null);
			pixel_pb = Gdk.pixbuf_get_from_window(window, x, y, 1, 1);
			pixel = pixel_pb.get_pixels();
			color = Color() {
				red = (double)pixel[0] / 255,
				green = (double)pixel[1] / 255,
				blue = (double)pixel[2] / 255
			};
			color_string = color.get_string(color_format);
			fgcol = Color.from_bgcolor(color);

			tmp_pb = Gdk.pixbuf_get_from_window(
				window,
				x - (int)(size / (2 * scale)),
				y - (int)(size / (2 * scale)),
				(int)(size / scale),
				(int)(size / scale)
			);
			pb = tmp_pb.scale_simple(size, size, InterpType.TILES);

			Gdk.cairo_set_source_pixbuf(ctx, pb, 0, 0);
			ctx.paint();

			ctx.set_line_width(1);
			ctx.set_tolerance(0.1);
			ctx.set_source_rgb(fgcol.red, fgcol.green, fgcol.blue);
			ctx.arc(size / 2, size / 2, 3, 0, 2 * Math.PI);
			ctx.stroke();

			ctx.rectangle(0, 0, size, size);
			ctx.stroke();
			ctx.set_source_rgb(0.2, 0.2, 0.2);
			ctx.rectangle(1, 1, size - 2, size - 2);
			ctx.stroke();

			ctx.set_source_rgb(color.red, color.green, color.blue);
			ctx.rectangle(2, size - 24, size - 4, 22);
			ctx.fill();

			ctx.set_source_rgb(fgcol.red, fgcol.green, fgcol.blue);
			ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
			ctx.set_font_size(13);	
			ctx.move_to(4, size - 8);
			ctx.show_text(color_string);

			return false;
		}
	}
}
