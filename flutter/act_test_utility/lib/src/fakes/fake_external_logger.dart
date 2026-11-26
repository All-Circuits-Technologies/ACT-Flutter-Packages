// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/src/fakes/fake_logger.dart';
import 'package:act_test_utility/src/models/fake_log_record.dart';

/// An external logger which records the messages instead of writing them anywhere.
///
/// A class which owns a `LogsHelper` rather than an interface cannot be given a [FakeLogger]: the
/// helper is a concrete class, and what it writes to is its external logger. This is the external
/// logger to build such a helper with:
///
/// ```dart
/// final external = FakeExternalLogger();
/// final manager = MyManager(logsHelper: external.buildHelper(category: "myManager"));
/// ```
class FakeExternalLogger extends AbsWithLifeCycle with MixinExternalLogger {
  /// The messages which have been logged, in the order they were logged.
  final List<FakeLogRecord> records = [];

  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.getter}
  @override
  LogsLevel minLevel;

  /// Class constructor.
  FakeExternalLogger({this.minLevel = LogsLevel.all});

  /// Builds a logs helper which writes to this logger.
  LogsHelper buildHelper({String? category, LogsLevel? minLevel}) =>
      LogsHelper.withExternalLogger(externalLogger: this, category: category, minLevel: minLevel);

  /// The messages recorded at the given [level].
  List<FakeLogRecord> recordsAtLevel(LogsLevel level) =>
      records.where((record) => record.level == level).toList();

  /// Forgets every recorded message.
  void clearRecords() => records.clear();

  /// {@macro act_logger_manager.MixinExternalLogger.log}
  @override
  void log({
    // We don't know the type of the objects we pass to the log messages
    // ignore: avoid_annotating_with_dynamic
    required dynamic message,
    required LogsLevel level,
    // We don't know the type of the objects we pass to the log messages
    // ignore: avoid_annotating_with_dynamic
    dynamic error,
    StackTrace? stackTrace,
    List<String>? categories,
    DateTime? time,
  }) {
    if (!wouldBeLogged(level: level, categories: categories)) {
      return;
    }

    records.add(
      FakeLogRecord(
        categories: categories ?? const [],
        level: level,
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// {@macro act_logger_manager.MixinExternalLogger.wouldBeLogged}
  @override
  bool wouldBeLogged({required LogsLevel level, List<String>? categories}) =>
      level.index >= minLevel.index;
}
