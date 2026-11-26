// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "splash_config.h"

#include <cstdlib>
#include <istream>
#include <string>

namespace act_splash_screen
{
    namespace
    {

        /// Number of characters a colour is written with, once its leading hash is dropped.
        constexpr size_t kColorDigits = 6;

        /// @brief Removes the spaces at both ends of a line or of a value read from the
        /// configuration.
        std::string Trimmed(const std::string &value)
        {
            const size_t first = value.find_first_not_of(" \t\r\n");
            if (first == std::string::npos)
            {
                return "";
            }

            return value.substr(first, value.find_last_not_of(" \t\r\n") - first + 1);
        }

        /**
         * @brief Reads a colour written in the "#RRGGBB" or "RRGGBB" form.
         *
         * @param value Text of the colour to read.
         * @param fallback Colour returned when the value is not a colour.
         * @param[out] warnings Message added when the value is not a colour.
         * @return The parsed colour, or the fallback when the value is not written that way.
         */
        unsigned int ParsedColor(const std::string &value,
                                 unsigned int fallback,
                                 std::vector<std::string> *warnings)
        {
            const std::string digits = value.front() == '#' ? value.substr(1) : value;

            char *end = nullptr;
            const unsigned long parsed = std::strtoul(digits.c_str(), &end, 16);
            if (digits.size() != kColorDigits || *end != '\0')
            {
                warnings->push_back("The colour " + value +
                                    " of the splash screen is not written as #RRGGBB");
                return fallback;
            }

            return static_cast<unsigned int>(parsed);
        }

    } // namespace

    bool ParseSplashConfig(std::istream &input,
                           SplashConfig *config,
                           std::vector<std::string> *warnings)
    {
        std::string line;
        while (std::getline(input, line))
        {
            const std::string trimmed = Trimmed(line);
            if (trimmed.empty() || trimmed.front() == '#')
            {
                continue;
            }

            const size_t separator = trimmed.find('=');
            if (separator == std::string::npos)
            {
                warnings->push_back("The line " + trimmed +
                                    " of the splash screen configuration has no "
                                    "value");
                continue;
            }

            const std::string key = Trimmed(trimmed.substr(0, separator));
            const std::string value = Trimmed(trimmed.substr(separator + 1));
            if (value.empty())
            {
                warnings->push_back("The key " + key +
                                    " of the splash screen configuration has no value");
                continue;
            }

            if (key == "image")
            {
                config->imagePath = value;
            }
            else if (key == "background_color")
            {
                config->backgroundColor = ParsedColor(value, config->backgroundColor, warnings);
            }
            else if (key == "fit")
            {
                config->fit = value == "contain" ? SplashFit::CONTAIN : SplashFit::COVER;
            }
            else
            {
                warnings->push_back("The splash screen configuration does not know the key " + key);
            }
        }

        if (config->imagePath.empty())
        {
            warnings->emplace_back("The splash screen configuration names no image");
            return false;
        }

        return true;
    }

} // namespace act_splash_screen
