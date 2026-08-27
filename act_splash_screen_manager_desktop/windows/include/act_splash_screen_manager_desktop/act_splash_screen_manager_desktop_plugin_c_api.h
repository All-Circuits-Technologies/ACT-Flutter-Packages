// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_DESKTOP_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_DESKTOP_PLUGIN_C_API_H_

/// @file act_splash_screen_manager_desktop_plugin_c_api.h
/// @brief C entry point the Flutter tooling registers the Windows plugin through.

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C"
{
#endif

    /**
     * @brief Declares the plugin to the application and opens its method channel.
     *
     * @param registrar Registrar the Flutter tooling gives to attach the plugin to the engine.
     */
    FLUTTER_PLUGIN_EXPORT void ActSplashScreenManagerDesktopPluginCApiRegisterWithRegistrar(
        FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
} // extern "C"
#endif

#endif // FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_DESKTOP_PLUGIN_C_API_H_
