// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/src/mixins/mixin_csl_logger_config.dart';
import 'package:act_logger_manager/src/mixins/mixin_logger_config.dart';

/// This mixin is used to combine the [MixinLoggerConfig] and the [MixinCslLoggerConfig] mixins, to
/// have a default logger config.
mixin MixinDefaultLoggerConfig on MixinLoggerConfig, MixinCslLoggerConfig {}
