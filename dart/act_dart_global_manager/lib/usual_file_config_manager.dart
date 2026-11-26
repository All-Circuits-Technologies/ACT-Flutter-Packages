// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The usual config manager of a pure Dart host, which reads its config from the file system.
///
/// This library is kept apart from the main one because it relies on `dart:io`, which is not
/// available on the web. Only import it from a host which runs on a platform with a file system
/// (a script, a command line tool, a server, a test).
library;

export 'src/services/abs_usual_file_config_manager.dart';
