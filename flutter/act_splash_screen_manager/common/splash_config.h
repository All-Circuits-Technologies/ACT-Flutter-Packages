// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_COMMON_SPLASH_CONFIG_H_
#define ACT_SPLASH_SCREEN_COMMON_SPLASH_CONFIG_H_

/// @file splash_config.h
/// @brief Model of the splash screen configuration and its parser, shared by every platform and
///        free of any platform code.

#include <iosfwd>
#include <string>
#include <vector>

namespace act_splash_screen
{

    /// Name of the file the configuration is read from, in the asset directory of the bundle.
    constexpr char kSplashConfigAsset[] = "assets/act_splash_screen.properties";

    /// @brief How the image of the splash screen occupies the window.
    enum class SplashFit
    {
        COVER,   ///< The image is enlarged until it covers the window, and what overflows is cut.
        CONTAIN, ///< The image is enlarged until it touches the window, and the background is seen
                 ///< around it.
    };

    /// @brief What the runner needs to draw the splash screen, read before the engine is started.
    struct SplashConfig
    {
        /// Path of the image, relative to the asset directory of the bundle, as the application
        /// names it.
        std::string imagePath;
        unsigned int backgroundColor = 0; ///< Colour drawn behind the image, in the 0xRRGGBB form.
        SplashFit fit = SplashFit::COVER; ///< How the image occupies the window.
    };

    /**
     * @brief Reads the configuration of the splash screen from the text of the configuration file.
     *
     * Every key which is absent keeps the value it already has in the configuration, and everything
     * which is wrong is described in the warnings, which the caller writes where its platform
     * writes.
     *
     * @param input Text of the configuration file to read from.
     * @param[out] config Configuration filled from the input, left untouched for the absent keys.
     * @param[out] warnings Messages describing everything wrong in the input.
     * @return false when the configuration names no image, which is how an application says it
     * wants no splash screen.
     */
    bool ParseSplashConfig(std::istream &input,
                           SplashConfig *config,
                           std::vector<std::string> *warnings);

} // namespace act_splash_screen

#endif // ACT_SPLASH_SCREEN_COMMON_SPLASH_CONFIG_H_
