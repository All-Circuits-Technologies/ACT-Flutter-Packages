// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_DESKTOP_PLUGIN_H_
#define FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_DESKTOP_PLUGIN_H_

/// @file act_splash_screen_manager_desktop_plugin.h
/// @brief Flutter plugin which answers the calls of the application on the method channel of the
///        splash screen.

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace act_splash_screen_manager_desktop
{

    /// @brief Answers the calls of the application asking for the splash screen to be removed.
    class ActSplashScreenManagerDesktopPlugin : public flutter::Plugin
    {
      public:
        /**
         * @brief Declares the plugin to the application and opens its method channel.
         *
         * @param registrar Registrar the Flutter tooling gives to attach the plugin to the engine.
         */
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

        ActSplashScreenManagerDesktopPlugin();
        ~ActSplashScreenManagerDesktopPlugin() override;

        ActSplashScreenManagerDesktopPlugin(const ActSplashScreenManagerDesktopPlugin &) = delete;
        ActSplashScreenManagerDesktopPlugin &operator=(
            const ActSplashScreenManagerDesktopPlugin &) = delete;

        /**
         * @brief Answers one call of the application.
         *
         * @param method_call Call the application makes on the method channel.
         * @param result Result to answer the call with.
         */
        void handleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue> &method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    };

} // namespace act_splash_screen_manager_desktop

#endif // FLUTTER_PLUGIN_ACT_SPLASH_SCREEN_MANAGER_DESKTOP_PLUGIN_H_
