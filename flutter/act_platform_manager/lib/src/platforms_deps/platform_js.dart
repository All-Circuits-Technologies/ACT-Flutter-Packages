// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This file is used with for Javascript
library;

import 'package:flutter/foundation.dart';

/// This is the platform environment
Map<String, String> get environment => {};

/// Tells if the current platform is Android
bool get isAndroid => false;

/// Tells if the current platform is iOS
bool get isIos => false;

/// Tells if the current platform is Fuchsia
bool get isFuchsia => false;

/// Tells if the current platform is Linux
bool get isLinux => false;

/// Tells if the current platform is MacOS
bool get isMacOS => false;

/// Tells if the current platform is Windows
bool get isWindows => false;

/// Tells if the current platform is Web
bool get isWeb => kIsWeb;
