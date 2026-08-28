// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_ACT_SPLASH_SCREEN_H_
#define ACT_SPLASH_SCREEN_ACT_SPLASH_SCREEN_H_

/// @file act_splash_screen.h
/// @brief Entry points the runner of a Linux application drives the splash screen with.

#include <gtk/gtk.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

/**
 * @brief Displays the splash screen of the application in the given window, and returns the
 *        container the Flutter view has to be added to.
 *
 * The runner calls this once the window is built and before it is shown, so that the image is on
 * the screen before the engine is started.
 *
 * @param window Window of the application the splash screen is displayed in.
 * @return The container the Flutter view has to be added to; the window itself when the application
 *         bundles no splash screen, so a runner has nothing to handle.
 */
FLUTTER_PLUGIN_EXPORT GtkWidget *act_splash_screen_attach(GtkWindow *window);

/**
 * @brief Removes the splash screen of the application.
 *
 * The application asks for it by itself, through the splash screen manager.
 *
 * @note A runner only needs this to give up on a startup which fails before the application can
 *       ask.
 */
FLUTTER_PLUGIN_EXPORT void act_splash_screen_hide();

G_END_DECLS

#endif // ACT_SPLASH_SCREEN_ACT_SPLASH_SCREEN_H_
