// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "include/act_splash_screen_manager_desktop/act_splash_screen.h"

#include <memory>
#include <utility>

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

    /**
     * @brief Token of the drawing library, held while the image of the splash screen is.
     *
     * @return A reference to the process-wide GDI+ token.
     */
    ULONG_PTR &GdiplusToken()
    {
        static ULONG_PTR TOKEN = 0;

        return TOKEN;
    }

} // namespace

void ActSplashScreenAttach(HWND host)
{
    act_splash_screen::SplashConfig config;
    if (!act_splash_screen::ReadSplashConfig(&config))
    {
        return;
    }

    const Gdiplus::GdiplusStartupInput startup_input;
    if (Gdiplus::GdiplusStartup(&GdiplusToken(), &startup_input, nullptr) != Gdiplus::Ok)
    {
        OutputDebugStringW(L"Failed to start the drawing library of the splash screen\n");
        return;
    }

    std::unique_ptr<Gdiplus::Image> image = act_splash_screen::LoadSplashImage(config.imagePath);
    if (image == nullptr)
    {
        Gdiplus::GdiplusShutdown(GdiplusToken());
        GdiplusToken() = 0;
        return;
    }

    Presenter() =
        std::make_unique<act_splash_screen::OverlaySplashPresenter>(config, std::move(image));
    Presenter()->attach(host);
}

void ActSplashScreenSetContent(HWND content)
{
    if (Presenter() != nullptr)
    {
        Presenter()->setContent(content);
    }
}

void ActSplashScreenHide()
{
    if (Presenter() == nullptr)
    {
        return;
    }

    Presenter()->hide();
    // The image is not needed any more, and an application which starts on a small board is glad to
    // have the memory back.
    Presenter().reset();

    Gdiplus::GdiplusShutdown(GdiplusToken());
    GdiplusToken() = 0;
}
