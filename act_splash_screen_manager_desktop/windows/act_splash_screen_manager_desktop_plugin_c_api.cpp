// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "include/act_splash_screen_manager_desktop/act_splash_screen_manager_desktop_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "act_splash_screen_manager_desktop_plugin.h"

void ActSplashScreenManagerDesktopPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
    act_splash_screen_manager_desktop::ActSplashScreenManagerDesktopPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
