// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Entry point which loads the configuration from the file system.
///
/// This library is kept apart from the main one because it relies on `dart:io`, which is not
/// available on the web. Only import it from a host which runs on a platform with a file system
/// (a script, a command line tool, a server, a test).
library;

export 'src/loaders/file_config_loader.dart';
