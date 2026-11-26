// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_ACT_SPLASH_SCREEN_H_
#define ACT_SPLASH_SCREEN_ACT_SPLASH_SCREEN_H_

/// @file act_splash_screen.h
/// @brief Entry points the runner of a Windows application drives the splash screen with.

#include <windows.h>

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
     * @brief Displays the splash screen of the application in the given window.
     *
     * The runner calls this once the window is created and before it is shown, so that the image is
     * on the screen before the engine is started. An application which bundles no splash screen
     * displays nothing, and the runner has nothing to handle.
     *
     * @param host Window of the application the splash screen is displayed in.
     */
    FLUTTER_PLUGIN_EXPORT void ActSplashScreenAttach(HWND host);

    /**
     * @brief Tells the splash screen which window it covers, and hides that window until it is
     * removed.
     *
     * The runner calls this once the Flutter view is created, with the window of that view.
     *
     * @param content Window of the Flutter view, hidden while the splash screen is displayed.
     */
    FLUTTER_PLUGIN_EXPORT void ActSplashScreenSetContent(HWND content);

    /**
     * @brief Removes the splash screen of the application, and uncovers the view of the
     * application.
     *
     * The application asks for it by itself, through the splash screen manager.
     *
     * @note A runner only needs this to give up on a startup which fails before the application can
     *       ask.
     */
    FLUTTER_PLUGIN_EXPORT void ActSplashScreenHide();

#if defined(__cplusplus)
} // extern "C"
#endif

#endif // ACT_SPLASH_SCREEN_ACT_SPLASH_SCREEN_H_
