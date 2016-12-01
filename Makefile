libdocklet-picky.so: 
	valac --library=libdocklet-picky.so PickyDocklet.vala PickyDockItem.vala PickyPreferences.vala PickerWindow.vala Color.vala --pkg gtk+-3.0 --pkg plank -X -fPIC -X -shared -o libdocklet-picky.so

install:
	sudo mv libdocklet-picky.so /usr/lib/x86_64-linux-gnu/plank/docklets/
	killall plank


