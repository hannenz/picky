
public static void docklet_init(Plank.DockletManager manager) {
	manager.register_docklet(typeof(Picky.PickyDocklet));
}

namespace Picky {

	public class PickyDocklet : Object, Plank.Docklet{

		public unowned string get_id() {
			return "picky";
		}

		public unowned string get_name() {
			return "Picky";
		}

		public unowned string get_description() {
			return "A color picker docklet";
		}

		public unowned string get_icon() {
			return "color-select-symbolic";
		}

		public bool is_supported() {
			return false;
		}

		public Plank.DockElement make_element(string launcher, GLib.File file) {
			return new PickyDockItem.with_dockitem_file(file);
		}
	}
}


