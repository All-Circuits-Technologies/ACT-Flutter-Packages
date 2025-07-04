// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This allows to access Platform io elements
library;

import "dart:io";

/// This is the platform environment
Map<String, String> get environment => Platform.environment;

/// Tells if the current platform is Android
bool get isAndroid => Platform.isAndroid;

/// Tells if the current platform is iOS
bool get isIos => Platform.isIOS;

/// Tells if the current platform is Fuchsia
bool get isFuchsia => Platform.isFuchsia;

/// Tells if the current platform is Linux
bool get isLinux => Platform.isLinux;

/// Tells if the current platform is MacOS
bool get isMacOS => Platform.isMacOS;

/// Tells if the current platform is Windows
bool get isWindows => Platform.isWindows;

/// Tells if the current platform is Web
bool get isWeb => false;
