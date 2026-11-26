// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_SPLASH_PRESENTER_H_
#define ACT_SPLASH_SCREEN_SPLASH_PRESENTER_H_

/// @file splash_presenter.h
/// @brief Interface a splash screen is displayed and removed through, whatever the way it occupies
///        the screen.

#include <windows.h>

namespace act_splash_screen
{

    /**
     * @brief Displays the splash screen of the application, and removes it when the application is
     *        ready.
     *
     * How the splash screen occupies the screen is what a derived class chooses: over the view of
     * the application, in its window, or in a window of its own. Which one an application uses is
     * decided by its runner, before the engine is started, and the application sees no difference.
     */
    class ASplashPresenter
    {
      public:
        virtual ~ASplashPresenter() = default;

        /**
         * @brief Displays the splash screen in the given window.
         *
         * The window is not shown yet when the method is called, and the view of the application
         * does not exist yet either.
         *
         * @param host Window of the application the splash screen is displayed in.
         */
        virtual void attach(HWND host) = 0;

        /**
         * @brief Tells the splash screen which window it covers, and hides that window until it is
         *        removed.
         *
         * @param content Window of the Flutter view, hidden while the splash screen is displayed.
         */
        virtual void setContent(HWND content) = 0;

        /**
         * @brief Removes the splash screen, and uncovers the view of the application.
         *
         * @note Removing a splash screen which is already removed does nothing.
         */
        virtual void hide() = 0;
    };

} // namespace act_splash_screen

#endif // ACT_SPLASH_SCREEN_SPLASH_PRESENTER_H_
