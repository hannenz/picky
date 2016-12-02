PRG = libdocklet-picky.so
CC = gcc
VALAC = valac
PKGCONFIG = $(shell which pkg-config)
PACKAGES = gtk+-3.0 plank
CFLAGS = `$(PKGCONFIG) --cflags $(PACKAGES)`
LIBS = `$(PKGCONFIG) --libs $(PACKAGES)`
VALAFLAGS = $(patsubst %, --pkg %, $(PACKAGES)) -X -fPIC -X -shared --library=$(PRG)

SOURCES = PickyDocklet.vala\
		PickyDockItem.vala\
		PickyPreferences.vala\
		PickerWindow.vala\
		Color.vala

UIFILES =

#Disable implicit rules by empty target .SUFFIXES
.SUFFIXES:

.PHONY: all clean distclean

all: $(PRG)
$(PRG): $(SOURCES) $(UIFILES)
	$(VALAC) -o $(PRG) $(SOURCES) $(VALAFLAGS)

install:
	sudo mv libdocklet-picky.so /usr/lib/x86_64-linux-gnu/plank/docklets/
	killall plank

clean:
	# rm -f $(OBJS)
	rm -f $(PRG)

distclean: clean
	rm -f *.vala.c



#
# libdocklet-picky.so: 
# 	valac --library=libdocklet-picky.so PickyDocklet.vala PickyDockItem.vala PickyPreferences.vala PickerWindow.vala Color.vala --pkg gtk+-3.0 --pkg plank -X -fPIC -X -shared -o libdocklet-picky.so
#


