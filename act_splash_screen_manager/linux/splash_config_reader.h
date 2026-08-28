// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_LINUX_SPLASH_CONFIG_READER_H_
#define ACT_SPLASH_SCREEN_LINUX_SPLASH_CONFIG_READER_H_

/// @file splash_config_reader.h
/// @brief Reads the splash screen configuration from the assets bundled with a Linux application.

#include <string>

#include "splash_config.h"

namespace act_splash_screen
{

    /**
     * @brief Returns the directory the assets of the application are bundled in.
     *
     * @return The absolute path of the asset directory, empty when it cannot be found.
     */
    std::string AssetDirectory();

    /**
     * @brief Reads the configuration of the splash screen from the assets of the application.
     *
     * What is wrong in it is written in the warnings of the application.
     *
     * @param[out] config Configuration filled from the assets, left untouched for the keys the file
     *                    does not set.
     * @return false when the application bundles no configuration, which is how it says it wants no
     *         splash screen.
     */
    bool ReadSplashConfig(SplashConfig *config);

} // namespace act_splash_screen

#endif // ACT_SPLASH_SCREEN_LINUX_SPLASH_CONFIG_READER_H_
