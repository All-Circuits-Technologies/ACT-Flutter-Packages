// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_PLUGIN_H_
#define FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_PLUGIN_H_

/// @file act_splash_screen_manager_plugin.h
/// @brief GObject plugin the Flutter tooling registers to wire the method channel of the splash
///        screen.

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _ActSplashScreenManagerPlugin ActSplashScreenManagerPlugin;
typedef struct
{
    GObjectClass parent_class;
} ActSplashScreenManagerPluginClass;

/// @brief Returns the GType of the plugin, declared by G_DEFINE_TYPE.
FLUTTER_PLUGIN_EXPORT GType act_splash_screen_manager_plugin_get_type();

/**
 * @brief Declares the plugin to the application and opens its method channel.
 *
 * @param registrar Registrar the Flutter tooling gives to attach the plugin to the engine.
 */
FLUTTER_PLUGIN_EXPORT void act_splash_screen_manager_plugin_register_with_registrar(
    FlPluginRegistrar *registrar);

G_END_DECLS

#endif // FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_PLUGIN_H_
