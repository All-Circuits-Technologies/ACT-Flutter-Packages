// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "splash_image_loader.h"

#include <glib.h>

#include "splash_config_reader.h"

namespace act_splash_screen
{

    GdkPixbuf *LoadSplashImage(const std::string &image_path)
    {
        const std::string asset_dir = AssetDirectory();
        if (asset_dir.empty())
        {
            return nullptr;
        }

        const std::string path = asset_dir + "/" + image_path;

        g_autoptr(GError) error = nullptr;
        GdkPixbuf *image = gdk_pixbuf_new_from_file(path.c_str(), &error);
        if (image == nullptr)
        {
            g_warning(
                "Failed to read the splash screen image %s: %s", path.c_str(), error->message);
        }

        return image;
    }

} // namespace act_splash_screen
