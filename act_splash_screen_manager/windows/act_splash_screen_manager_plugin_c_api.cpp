// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "include/act_splash_screen_manager/act_splash_screen_manager_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "act_splash_screen_manager_plugin.h"

void ActSplashScreenManagerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
    act_splash_screen_manager::ActSplashScreenManagerPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
