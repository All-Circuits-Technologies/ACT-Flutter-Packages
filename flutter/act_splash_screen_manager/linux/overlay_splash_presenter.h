// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_OVERLAY_SPLASH_PRESENTER_H_
#define ACT_SPLASH_SCREEN_OVERLAY_SPLASH_PRESENTER_H_

/// @file overlay_splash_presenter.h
/// @brief Splash screen drawn over the view of the application, in the window of the application.

#include "splash_config.h"
#include "splash_presenter.h"

namespace act_splash_screen
{

    /**
     * @brief Displays the splash screen over the view of the application, in the window of the
     *        application.
     *
     * This is what the mobile platforms do: one window, the image first, the application
     * afterwards. The window is shown as soon as it is built, so the image covers the start of the
     * engine, and the view of the application is added underneath and uncovered when the
     * application is ready.
     */
    class OverlaySplashPresenter : public ASplashPresenter
    {
      public:
        /**
         * @brief Class constructor, taking ownership of the image.
         *
         * @param config What the splash screen looks like.
         * @param image Image drawn by the splash screen, owned from now on.
         */
        OverlaySplashPresenter(SplashConfig config, GdkPixbuf *image);
        ~OverlaySplashPresenter() override;

        OverlaySplashPresenter(const OverlaySplashPresenter &) = delete;
        OverlaySplashPresenter &operator=(const OverlaySplashPresenter &) = delete;

        GtkWidget *attach(GtkWindow *window) override;
        void hide() override;

        /**
         * @brief Draws the image on the area it is given, as the configuration asks for.
         *
         * @param area Drawing area the image is painted on.
         * @param cr Cairo context the drawing area gives to paint with.
         */
        void draw(GtkWidget *area, cairo_t *cr) const;

      private:
        const SplashConfig m_config; ///< What the splash screen looks like.
        GdkPixbuf *m_image;          ///< Image drawn by the splash screen.
        GtkWidget *m_area = nullptr; ///< Area the image is drawn on, null once the splash screen is
                                     ///< removed.
    };

} // namespace act_splash_screen

#endif // ACT_SPLASH_SCREEN_OVERLAY_SPLASH_PRESENTER_H_
