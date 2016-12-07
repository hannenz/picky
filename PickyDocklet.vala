/**
 * PickyDocklet
 *
 * A little color picker docklet for Plank
 *
 * @author Johannes Braun <johannes.braun@hannenz.de>
 * @package picky
 * @version 2016-12-02
 * 
 * @todo	Settings dialog
 */

public static void docklet_init(Plank.DockletManager manager) {
	manager.register_docklet(typeof(Picky.PickyDocklet));
}

namespace Picky {


	/**
	 * Resource path for the icon
	 */
	public const string G_RESOURCE_PATH = "/de/hannenz/picky";

	/**
	 * Filename for palette storage (in home directory)
	 */
	public const string PALETTE_FILE = ".picky";


	public class PickyDocklet : Object, Plank.Docklet {

		public unowned string get_id() {
			return "picky";
		}

		public unowned string get_name() {
			return "Picky";
		}

		public unowned string get_description() {
			return "A color picker docklet for plank/docky";
		}

		public unowned string get_icon() {
			return "resource://" + Picky.G_RESOURCE_PATH + "/icons/color_picker.png";
		}

		public bool is_supported() {
			return false;
		}

		public Plank.DockElement make_element(string launcher, GLib.File file) {
			return new PickyDockItem.with_dockitem_file(file);
		}
	}
}


