// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "splash_config.h"

#include <gtest/gtest.h>

#include <sstream>
#include <string>
#include <vector>

namespace act_splash_screen
{
    namespace
    {

        // Reads a configuration written as an application would write it.
        bool Read(const std::string &text, SplashConfig *config, std::vector<std::string> *warnings)
        {
            std::istringstream input(text);

            return ParseSplashConfig(input, config, warnings);
        }

        TEST(SplashConfig, ReadsTheImageTheColourAndTheFit)
        {
            SplashConfig config;
            std::vector<std::string> warnings;

            EXPECT_TRUE(Read("image=assets/splash.png\nbackground_color=#123456\nfit=contain\n",
                             &config,
                             &warnings));

            EXPECT_EQ(config.imagePath, "assets/splash.png");
            EXPECT_EQ(config.backgroundColor, 0x123456u);
            EXPECT_EQ(config.fit, SplashFit::CONTAIN);
            EXPECT_TRUE(warnings.empty());
        }

        TEST(SplashConfig, CoversTheWindowWhenTheFitIsNotSaid)
        {
            SplashConfig config;
            std::vector<std::string> warnings;

            EXPECT_TRUE(Read("image=assets/splash.png\n", &config, &warnings));

            EXPECT_EQ(config.fit, SplashFit::COVER);
            EXPECT_EQ(config.backgroundColor, 0u);
            EXPECT_TRUE(warnings.empty());
        }

        TEST(SplashConfig, SkipsTheCommentsAndTheEmptyLines)
        {
            SplashConfig config;
            std::vector<std::string> warnings;

            EXPECT_TRUE(
                Read("# The splash screen\n\n   \nimage=assets/splash.png\n", &config, &warnings));

            EXPECT_EQ(config.imagePath, "assets/splash.png");
            EXPECT_TRUE(warnings.empty());
        }

        TEST(SplashConfig, IgnoresTheSpacesAroundTheKeysAndTheValues)
        {
            SplashConfig config;
            std::vector<std::string> warnings;

            EXPECT_TRUE(Read("  image  =  assets/splash.png  \r\n", &config, &warnings));

            EXPECT_EQ(config.imagePath, "assets/splash.png");
            EXPECT_TRUE(warnings.empty());
        }

        TEST(SplashConfig, ReadsAColourWrittenWithoutItsHash)
        {
            SplashConfig config;
            std::vector<std::string> warnings;

            EXPECT_TRUE(Read("image=a.png\nbackground_color=ABCDEF\n", &config, &warnings));

            EXPECT_EQ(config.backgroundColor, 0xABCDEFu);
            EXPECT_TRUE(warnings.empty());
        }

        TEST(SplashConfig, KeepsTheColourItHasAndWarnsWhenTheOneReadIsMalformed)
        {
            SplashConfig config;
            config.backgroundColor = 0x101010u;
            std::vector<std::string> warnings;

            EXPECT_TRUE(Read("image=a.png\nbackground_color=blue\n", &config, &warnings));

            EXPECT_EQ(config.backgroundColor, 0x101010u);
            ASSERT_EQ(warnings.size(), 1u);
            EXPECT_NE(warnings.front().find("blue"), std::string::npos);
        }

        TEST(SplashConfig, WarnsAboutAKeyItDoesNotKnow)
        {
            SplashConfig config;
            std::vector<std::string> warnings;

            EXPECT_TRUE(Read("image=a.png\nanimation=fade\n", &config, &warnings));

            ASSERT_EQ(warnings.size(), 1u);
            EXPECT_NE(warnings.front().find("animation"), std::string::npos);
        }

        TEST(SplashConfig, WarnsAboutALineWhichSaysNothing)
        {
            SplashConfig config;
            std::vector<std::string> warnings;

            EXPECT_TRUE(Read("image=a.png\nbackground_color\nfit=\n", &config, &warnings));

            EXPECT_EQ(warnings.size(), 2u);
        }

        TEST(SplashConfig, RefusesAConfigurationWhichNamesNoImage)
        {
            SplashConfig config;
            std::vector<std::string> warnings;

            EXPECT_FALSE(Read("background_color=#000000\n", &config, &warnings));

            ASSERT_EQ(warnings.size(), 1u);
            EXPECT_NE(warnings.front().find("no image"), std::string::npos);
        }

    } // namespace
} // namespace act_splash_screen
