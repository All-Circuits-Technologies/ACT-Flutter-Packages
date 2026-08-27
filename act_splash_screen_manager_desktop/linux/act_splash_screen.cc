// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "include/act_splash_screen_manager_desktop/act_splash_screen.h"

#include <memory>

#include "overlay_splash_presenter.h"
#include "splash_config_reader.h"
#include "splash_image_loader.h"
#include "splash_presenter.h"

namespace
{

    /**
     * @brief The splash screen of the application, null when it draws none.
     *
     * The application has one window and one splash screen, and the runner displays it before
     * anything else exists: there is nothing to hang the presenter on but the process itself.
     *
     * @return A reference to the process-wide presenter.
     */
    std::unique_ptr<act_splash_screen::ASplashPresenter> &Presenter()
    {
        static std::unique_ptr<act_splash_screen::ASplashPresenter> PRESENTER;

        return PRESENTER;
    }

} // namespace

GtkWidget *act_splash_screen_attach(GtkWindow *window)
{
    act_splash_screen::SplashConfig config;
    if (!act_splash_screen::ReadSplashConfig(&config))
    {
        return GTK_WIDGET(window);
    }

    GdkPixbuf *image = act_splash_screen::LoadSplashImage(config.imagePath);
    if (image == nullptr)
    {
        return GTK_WIDGET(window);
    }

    Presenter() = std::make_unique<act_splash_screen::OverlaySplashPresenter>(config, image);

    return Presenter()->attach(window);
}

void act_splash_screen_hide()
{
    if (Presenter() == nullptr)
    {
        return;
    }

    Presenter()->hide();
    // The image is not needed any more, and an application which starts on a small board is glad to
    // have the memory back.
    Presenter().reset();
}
