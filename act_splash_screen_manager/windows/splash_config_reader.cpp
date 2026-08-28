// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "splash_config_reader.h"

#include <windows.h>

#include <algorithm>
#include <fstream>
#include <vector>

namespace act_splash_screen
{
    namespace
    {

        /// @brief Writes a message of the splash screen where a Windows application writes them.
        void Warn(const std::wstring &message)
        {
            OutputDebugStringW((message + L"\n").c_str());
        }

    } // namespace

    std::wstring AssetDirectory()
    {
        wchar_t executable_path[MAX_PATH];
        const DWORD length = GetModuleFileNameW(nullptr, executable_path, MAX_PATH);
        if (length == 0 || length == MAX_PATH)
        {
            Warn(L"Failed to find the directory of the application");
            return L"";
        }

        const std::wstring path(executable_path, length);
        const size_t separator = path.find_last_of(L'\\');
        if (separator == std::wstring::npos)
        {
            return L"";
        }

        return path.substr(0, separator) + L"\\data\\flutter_assets";
    }

    std::wstring PlatformPath(const std::string &path)
    {
        std::wstring platform_path(path.begin(), path.end());
        std::replace(platform_path.begin(), platform_path.end(), L'/', L'\\');

        return platform_path;
    }

    bool ReadSplashConfig(SplashConfig *config)
    {
        const std::wstring asset_dir = AssetDirectory();
        if (asset_dir.empty())
        {
            return false;
        }

        std::ifstream file(asset_dir + L"\\" + PlatformPath(kSplashConfigAsset));
        if (!file.is_open())
        {
            return false;
        }

        std::vector<std::string> warnings;
        const bool read = ParseSplashConfig(file, config, &warnings);

        for (const std::string &warning : warnings)
        {
            Warn(std::wstring(warning.begin(), warning.end()));
        }

        return read;
    }

} // namespace act_splash_screen
