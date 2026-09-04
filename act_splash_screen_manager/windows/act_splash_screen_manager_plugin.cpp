// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "act_splash_screen_manager_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "include/act_splash_screen_manager/act_splash_screen.h"

namespace act_splash_screen_manager
{
    namespace
    {

        /// Name of the channel the application removes the splash screen through.
        constexpr char kChannelName[] = "act_splash_screen";

    } // namespace

    void ActSplashScreenManagerPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarWindows *registrar)
    {
        auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), kChannelName, &flutter::StandardMethodCodec::GetInstance());

        auto plugin = std::make_unique<ActSplashScreenManagerPlugin>();

        channel->SetMethodCallHandler(
            [plugin_pointer = plugin.get()](const auto &call, auto result) {
                plugin_pointer->handleMethodCall(call, std::move(result));
            });

        registrar->AddPlugin(std::move(plugin));
    }

    ActSplashScreenManagerPlugin::ActSplashScreenManagerPlugin()
    {
    }

    ActSplashScreenManagerPlugin::~ActSplashScreenManagerPlugin()
    {
    }

    void ActSplashScreenManagerPlugin::handleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
    {
        if (method_call.method_name() == "hide")
        {
            ActSplashScreenHide();
            result->Success();
        }
        else
        {
            result->NotImplemented();
        }
    }

} // namespace act_splash_screen_manager
