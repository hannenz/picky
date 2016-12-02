/**
 * PickyDocklet
 *
 * A little color picker docklet for Plank
 *
 * @author Johannes Braun <johannes.braun@hannenz.de>
 * @package picky
 * @version 2016-12-02
 * 
 * @todo	Get mouse button working
 * @todo	Save colors to file
 * @todo	Integrate / combine "epick"
 * @todo	Settings dialog
 * @todo	Get x11name working again..
 */

public static void docklet_init(Plank.DockletManager manager) {
	manager.register_docklet(typeof(Picky.PickyDocklet));
}

namespace Picky {

	public class PickyDocklet : Object, Plank.Docklet {

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
			return "preferences-color";
		}

		public bool is_supported() {
			return false;
		}

		public Plank.DockElement make_element(string launcher, GLib.File file) {
			return new PickyDockItem.with_dockitem_file(file);
		}
	}
}


