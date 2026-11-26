// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#ifndef ACT_SPLASH_SCREEN_SPLASH_IMAGE_LOADER_H_
#define ACT_SPLASH_SCREEN_SPLASH_IMAGE_LOADER_H_

/// @file splash_image_loader.h
/// @brief Reads the splash screen image from the assets bundled with a Linux application.

#include <gdk-pixbuf/gdk-pixbuf.h>

#include <string>

namespace act_splash_screen
{

    /**
     * @brief Reads the image of the splash screen from the assets of the application.
     *
     * @param image_path Path of the image in the assets, the very one the application gives to
     * Flutter.
     * @return The loaded image, or null (and says why) when the image cannot be read.
     */
    GdkPixbuf *LoadSplashImage(const std::string &image_path);

} // namespace act_splash_screen

#endif // ACT_SPLASH_SCREEN_SPLASH_IMAGE_LOADER_H_
