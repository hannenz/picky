using Plank;

namespace Picky {

	public class PickyPreferences : DockItemPreferences {

		[Description(nick = "max-entries", blurb="How many colors to keep")]
		public uint MaxEntries { get; set; default = 10; }

		[Description(nick = "format", blurb="Color format, hex or rgb")]
		public string Format { get; set; default = "hex"; }

		public PickyPreferences.with_file(GLib.File file) {
			base.with_file(file);
		}

		protected override void reset_properties() {
			MaxEntries = 10;
			Format = "hex";
		}
	}
}
		
