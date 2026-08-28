// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "splash_image_loader.h"

#include "splash_config_reader.h"

namespace act_splash_screen
{

    std::unique_ptr<Gdiplus::Image> LoadSplashImage(const std::string &image_path)
    {
        const std::wstring asset_dir = AssetDirectory();
        if (asset_dir.empty())
        {
            return nullptr;
        }

        std::unique_ptr<Gdiplus::Image> image(
            Gdiplus::Image::FromFile((asset_dir + L"\\" + PlatformPath(image_path)).c_str()));
        if (image == nullptr || image->GetLastStatus() != Gdiplus::Ok)
        {
            OutputDebugStringW(L"Failed to read the splash screen image\n");
            return nullptr;
        }

        return image;
    }

} // namespace act_splash_screen
