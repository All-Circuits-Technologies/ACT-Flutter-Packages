// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_SPLASH_PRESENTER_H_
#define ACT_SPLASH_SCREEN_SPLASH_PRESENTER_H_

/// @file splash_presenter.h
/// @brief Interface a splash screen is displayed and removed through, whatever the way it occupies
///        the screen.

#include <gtk/gtk.h>

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
         * @brief Displays the splash screen and returns the container the view of the application
         * goes in.
         *
         * The window is not shown yet when the method is called, and the view of the application
         * does not exist yet either.
         *
         * @param window Window of the application the splash screen is displayed in.
         * @return The container the Flutter view has to be added to.
         */
        virtual GtkWidget *attach(GtkWindow *window) = 0;

        /**
         * @brief Removes the splash screen, and uncovers the view of the application.
         *
         * @note Removing a splash screen which is already removed does nothing.
         */
        virtual void hide() = 0;
    };

} // namespace act_splash_screen

#endif // ACT_SPLASH_SCREEN_SPLASH_PRESENTER_H_
