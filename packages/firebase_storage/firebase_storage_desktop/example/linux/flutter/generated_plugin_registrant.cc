//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <gtk/gtk_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) gtk_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "GtkPlugin");
  gtk_plugin_register_with_registrar(gtk_registrar);
}
