// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/src/services/abs_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// This extends the [DefaultLoggerBuilder] to create a logger manager by getting the config
/// from the global manager.
///
/// This is a convenient builder to use if you want to use the default logger manager.
class ExtDefaultLoggerBuilder<C extends MixinDefaultLoggerConfig> extends DefaultLoggerBuilder<C> {
  /// Class constructor
  ExtDefaultLoggerBuilder() : super(loggerConfigGetter: globalGetIt().get<C>);
}
