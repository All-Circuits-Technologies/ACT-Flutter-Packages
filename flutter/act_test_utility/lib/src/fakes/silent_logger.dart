// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/src/fakes/fake_logger.dart';

/// A logger which drops every message.
///
/// This is the logger to give to a class under test which needs a logger but whose logs are not
/// part of what the test asserts. It keeps nothing in memory and never writes to the console, so
/// the output of the test run stays readable.
///
/// Use [FakeLogger] instead when the test asserts on what was logged.
class SilentLogger with MixinActLogger {
  /// Class constructor.
  const SilentLogger();

  /// {@macro act_foundation.MixinActLogger.log}
  @override
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void log(dynamic message, {required LogsLevel level, dynamic error, StackTrace? stackTrace}) {}

  /// {@macro act_foundation.MixinActLogger.logMessages}
  @override
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void logMessages(dynamic message) {}

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  ///
  /// A sub logger of a silent logger is a silent logger too.
  @override
  SilentLogger createAbsSubLogger({required String subCategory}) => const SilentLogger();

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  ///
  /// A sub logger of a silent logger is a silent logger too.
  @override
  SilentLogger createAbsSubLoggerMinLevel({required String subCategory, LogsLevel? minLevel}) =>
      const SilentLogger();

  /// {@macro act_foundation.MixinActLogger.wouldBeLogged}
  @override
  bool wouldBeLogged(LogsLevel level) => false;
}
