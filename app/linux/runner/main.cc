#include <gtk/gtk.h>

#include <cstdlib>

#include "my_application.h"

int main(int argc, char** argv) {
  // GTK's Wayland backend reads GNOME's xsettings schema and aborts on
  // systems where that schema lacks keys it expects. Prefer X11 (XWayland)
  // and fall back to Wayland; an explicit GDK_BACKEND still wins.
  if (getenv("GDK_BACKEND") == nullptr) {
    gdk_set_allowed_backends("x11,wayland");
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
