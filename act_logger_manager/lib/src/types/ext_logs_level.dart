// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:logger/logger.dart';

/// This extension is used to convert a [LogsLevel] to a [Level] of the Logger package, and vice
/// versa.
extension ExtLogsLevel on LogsLevel {
  /// Convert the [LogsLevel] to a [Level] of the Logger package.
  Level get toLoggerLevel => switch (this) {
        LogsLevel.all => Level.all,
        LogsLevel.trace => Level.trace,
        LogsLevel.debug => Level.debug,
        LogsLevel.info => Level.info,
        LogsLevel.warn => Level.warning,
        LogsLevel.error => Level.error,
        LogsLevel.fatal => Level.fatal,
        LogsLevel.off => Level.off,
      };

  /// Convert a [Level] of the Logger package to a [LogsLevel].
  static LogsLevel fromLoggerLevel(Level level) => switch (level) {
        Level.all => LogsLevel.all,
        // We use the deprecated verbose level to cover every case
        // ignore: deprecated_member_use
        Level.trace || Level.verbose => LogsLevel.trace,
        Level.debug => LogsLevel.debug,
        Level.info => LogsLevel.info,
        Level.warning => LogsLevel.warn,
        Level.error => LogsLevel.error,
        // We use the deprecated wtf level to cover every case
        // ignore: deprecated_member_use
        Level.fatal || Level.wtf => LogsLevel.fatal,
        // We use the deprecated nothing level to cover every case
        // ignore: deprecated_member_use
        Level.off || Level.nothing => LogsLevel.off,
      };
}
