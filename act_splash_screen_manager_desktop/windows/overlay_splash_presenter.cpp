// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "overlay_splash_presenter.h"

#include <algorithm>
#include <utility>

namespace act_splash_screen
{
    namespace
    {

        /// Name of the class of the window the splash screen is drawn in.
        constexpr wchar_t kWindowClass[] = L"ActSplashScreen";

        /// Bit position of the red channel in a 0xRRGGBB colour.
        constexpr unsigned int kRedShift = 16;
        /// Bit position of the green channel in a 0xRRGGBB colour.
        constexpr unsigned int kGreenShift = 8;
        /// Mask keeping the low byte of a colour channel.
        constexpr unsigned int kChannelMask = 0xFF;
        /// Alpha of a fully opaque colour.
        constexpr BYTE kAlphaOpaque = 255;

        /// @brief Answers the messages of the window of the splash screen.
        LRESULT CALLBACK SplashWindowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam)
        {
            auto *presenter =
                reinterpret_cast<OverlaySplashPresenter *>(GetWindowLongPtr(window, GWLP_USERDATA));

            if (message == WM_PAINT && presenter != nullptr)
            {
                PAINTSTRUCT paint;
                HDC device_context = BeginPaint(window, &paint);
                presenter->draw(window, device_context);
                EndPaint(window, &paint);

                return 0;
            }

            if (message == WM_ERASEBKGND)
            {
                // The whole window is painted, so erasing it first would only make it blink.
                return 1;
            }

            return DefWindowProc(window, message, wparam, lparam);
        }

        /// @brief Declares the class of the window of the splash screen, once for the process.
        void RegisterSplashWindowClass()
        {
            static bool registered = false;
            if (registered)
            {
                return;
            }

            WNDCLASSW window_class = {};
            window_class.lpfnWndProc = SplashWindowProc;
            window_class.hInstance = GetModuleHandle(nullptr);
            window_class.lpszClassName = kWindowClass;
            window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
            RegisterClassW(&window_class);

            registered = true;
        }

    } // namespace

    OverlaySplashPresenter::OverlaySplashPresenter(SplashConfig config,
                                                   std::unique_ptr<Gdiplus::Image> image)
        : m_config(std::move(config)),
          m_image(std::move(image))
    {
    }

    OverlaySplashPresenter::~OverlaySplashPresenter()
    {
        hide();
    }

    void OverlaySplashPresenter::attach(HWND host)
    {
        RegisterSplashWindowClass();

        RECT client_area;
        GetClientRect(host, &client_area);

        m_window = CreateWindowExW(0,
                                   kWindowClass,
                                   L"",
                                   WS_CHILD | WS_VISIBLE,
                                   0,
                                   0,
                                   client_area.right - client_area.left,
                                   client_area.bottom - client_area.top,
                                   host,
                                   nullptr,
                                   GetModuleHandle(nullptr),
                                   nullptr);
        if (m_window == nullptr)
        {
            return;
        }

        SetWindowLongPtr(m_window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    }

    void OverlaySplashPresenter::setContent(HWND content)
    {
        m_content = content;

        if (m_window != nullptr && m_content != nullptr)
        {
            // The view of the application is only uncovered when the splash screen is removed.
            ShowWindow(m_content, SW_HIDE);
        }
    }

    void OverlaySplashPresenter::hide()
    {
        if (m_content != nullptr)
        {
            ShowWindow(m_content, SW_SHOW);
            m_content = nullptr;
        }

        if (m_window != nullptr)
        {
            DestroyWindow(m_window);
            m_window = nullptr;
        }
    }

    void OverlaySplashPresenter::draw(HWND window, HDC device_context) const
    {
        RECT area;
        GetClientRect(window, &area);
        const auto area_width = static_cast<double>(area.right - area.left);
        const auto area_height = static_cast<double>(area.bottom - area.top);

        Gdiplus::Graphics graphics(device_context);
        graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);

        const Gdiplus::Color background(
            kAlphaOpaque,
            static_cast<BYTE>((m_config.backgroundColor >> kRedShift) & kChannelMask),
            static_cast<BYTE>((m_config.backgroundColor >> kGreenShift) & kChannelMask),
            static_cast<BYTE>(m_config.backgroundColor & kChannelMask));
        const Gdiplus::SolidBrush brush(background);
        graphics.FillRectangle(
            &brush, 0, 0, static_cast<INT>(area_width), static_cast<INT>(area_height));

        const auto image_width = static_cast<double>(m_image->GetWidth());
        const auto image_height = static_cast<double>(m_image->GetHeight());
        const double horizontal_scale = area_width / image_width;
        const double vertical_scale = area_height / image_height;
        const double scale = m_config.fit == SplashFit::COVER
                                 ? (std::max)(horizontal_scale, vertical_scale)
                                 : (std::min)(horizontal_scale, vertical_scale);

        const double drawn_width = image_width * scale;
        const double drawn_height = image_height * scale;
        graphics.DrawImage(m_image.get(),
                           static_cast<INT>((area_width - drawn_width) / 2),
                           static_cast<INT>((area_height - drawn_height) / 2),
                           static_cast<INT>(drawn_width),
                           static_cast<INT>(drawn_height));
    }

} // namespace act_splash_screen
