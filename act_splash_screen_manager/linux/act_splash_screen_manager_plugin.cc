// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "include/act_splash_screen_manager/act_splash_screen_manager_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include <cstring>

#include "include/act_splash_screen_manager/act_splash_screen.h"

/// Name of the channel the application removes the splash screen through.
#define ACT_SPLASH_SCREEN_CHANNEL "act_splash_screen"

/// Casts an object to the plugin, checking that it is really one.
#define ACT_SPLASH_SCREEN_MANAGER_PLUGIN(obj)                                              \
    (G_TYPE_CHECK_INSTANCE_CAST((obj),                                                             \
                                act_splash_screen_manager_plugin_get_type(),               \
                                ActSplashScreenManagerPlugin))

struct _ActSplashScreenManagerPlugin
{
    GObject parent_instance;
};

G_DEFINE_TYPE(ActSplashScreenManagerPlugin,
              act_splash_screen_manager_plugin,
              g_object_get_type())

/// @brief Answers the calls of the application.
static void act_splash_screen_manager_plugin_handle_method_call(
    ActSplashScreenManagerPlugin *self, FlMethodCall *method_call)
{
    g_autoptr(FlMethodResponse) response = nullptr;

    if (strcmp(fl_method_call_get_name(method_call), "hide") == 0)
    {
        act_splash_screen_hide();
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
    else
    {
        response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    }

    g_autoptr(GError) error = nullptr;
    if (!fl_method_call_respond(method_call, response, &error))
    {
        g_warning("Failed to answer the splash screen call: %s", error->message);
    }
}

static void act_splash_screen_manager_plugin_dispose(GObject *object)
{
    G_OBJECT_CLASS(act_splash_screen_manager_plugin_parent_class)->dispose(object);
}

static void act_splash_screen_manager_plugin_class_init(
    ActSplashScreenManagerPluginClass *klass)
{
    G_OBJECT_CLASS(klass)->dispose = act_splash_screen_manager_plugin_dispose;
}

static void act_splash_screen_manager_plugin_init(ActSplashScreenManagerPlugin *self)
{
}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call, gpointer user_data)
{
    ActSplashScreenManagerPlugin *plugin =
        ACT_SPLASH_SCREEN_MANAGER_PLUGIN(user_data);
    act_splash_screen_manager_plugin_handle_method_call(plugin, method_call);
}

void act_splash_screen_manager_plugin_register_with_registrar(FlPluginRegistrar *registrar)
{
    ActSplashScreenManagerPlugin *plugin = ACT_SPLASH_SCREEN_MANAGER_PLUGIN(
        g_object_new(act_splash_screen_manager_plugin_get_type(), nullptr));

    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    g_autoptr(FlMethodChannel) channel =
        fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                              ACT_SPLASH_SCREEN_CHANNEL,
                              FL_METHOD_CODEC(codec));
    fl_method_channel_set_method_call_handler(
        channel, method_call_cb, g_object_ref(plugin), g_object_unref);

    g_object_unref(plugin);
}
