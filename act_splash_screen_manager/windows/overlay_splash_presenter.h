// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_OVERLAY_SPLASH_PRESENTER_H_
#define ACT_SPLASH_SCREEN_OVERLAY_SPLASH_PRESENTER_H_

/// @file overlay_splash_presenter.h
/// @brief Splash screen drawn over the view of the application, in the window of the application.

#include <memory>

#include "splash_config.h"
#include "splash_image_loader.h"
#include "splash_presenter.h"

namespace act_splash_screen
{

    /**
     * @brief Displays the splash screen over the view of the application, in the window of the
     *        application.
     *
     * This is what the mobile platforms do: one window, the image first, the application
     * afterwards. The splash screen is a child window of the window of the application, drawn as
     * soon as the window is shown, and the view of the application stays hidden underneath until it
     * is removed.
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
        OverlaySplashPresenter(SplashConfig config, std::unique_ptr<Gdiplus::Image> image);
        ~OverlaySplashPresenter() override;

        OverlaySplashPresenter(const OverlaySplashPresenter &) = delete;
        OverlaySplashPresenter &operator=(const OverlaySplashPresenter &) = delete;

        void attach(HWND host) override;
        void setContent(HWND content) override;
        void hide() override;

        /**
         * @brief Draws the image on the window it is given, as the configuration asks for.
         *
         * @param window Window the image is painted in.
         * @param device_context Device context the window gives to paint with.
         */
        void draw(HWND window, HDC device_context) const;

      private:
        const SplashConfig m_config;                   ///< What the splash screen looks like.
        const std::unique_ptr<Gdiplus::Image> m_image; ///< Image drawn by the splash screen.
        HWND m_window = nullptr;  ///< Window the image is drawn in, null once the splash screen is
                                  ///< removed.
        HWND m_content = nullptr; ///< Window of the view of the application, hidden while the
                                  ///< splash screen is displayed.
    };

} // namespace act_splash_screen

#endif // ACT_SPLASH_SCREEN_OVERLAY_SPLASH_PRESENTER_H_
