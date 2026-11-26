// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "splash_config_reader.h"

#include <glib.h>

#include <fstream>
#include <vector>

namespace act_splash_screen
{

    std::string AssetDirectory()
    {
        g_autofree gchar *executable_path = g_file_read_link("/proc/self/exe", nullptr);
        if (executable_path == nullptr)
        {
            g_warning("Failed to find the directory of the application");
            return "";
        }

        g_autofree gchar *executable_dir = g_path_get_dirname(executable_path);
        g_autofree gchar *asset_dir =
            g_build_filename(executable_dir, "data", "flutter_assets", nullptr);

        return asset_dir;
    }

    bool ReadSplashConfig(SplashConfig *config)
    {
        const std::string asset_dir = AssetDirectory();
        if (asset_dir.empty())
        {
            return false;
        }

        std::ifstream file(asset_dir + "/" + kSplashConfigAsset);
        if (!file.is_open())
        {
            return false;
        }

        std::vector<std::string> warnings;
        const bool read = ParseSplashConfig(file, config, &warnings);

        for (const std::string &warning : warnings)
        {
            g_warning("%s", warning.c_str());
        }

        return read;
    }

} // namespace act_splash_screen
