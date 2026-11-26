// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/src/models/fake_log_record.dart';

/// A logger which records the messages instead of writing them anywhere.
///
/// This is the logger to give to a class under test when the test wants to assert on what was
/// logged. When the test does not care about the logs, prefer the silent logger, which keeps
/// nothing in memory.
///
/// The sub loggers created from a fake logger share the records of their parent: whatever the
/// depth of the logger which logged a message, the message is visible from the root logger.
class FakeLogger with MixinActLogger {
  /// The categories of the logger.
  ///
  /// The first category is the main category of the logger and the last one is the most specific.
  final List<String> categories;

  /// The level used by [logMessages], when the message level is unknown.
  final LogsLevel defaultLogLevel;

  /// The minimum level of the messages which are recorded.
  ///
  /// A message logged at a lower level is dropped, exactly as a real logger would drop it. When
  /// null, every message is recorded.
  final LogsLevel? minLevel;

  /// The records shared by this logger and all the sub loggers created from it.
  final List<FakeLogRecord> _records;

  /// Class constructor.
  FakeLogger({String? category, this.minLevel, this.defaultLogLevel = LogsLevel.debug})
    : categories = [?category],
      _records = [];

  /// Creates a sub logger which appends [subCategory] to the categories of [parentLogger] and
  /// shares its records.
  FakeLogger._createSubLogger({
    required FakeLogger parentLogger,
    required String subCategory,
    LogsLevel? minLevel,
  }) : categories = [...parentLogger.categories, subCategory],
       defaultLogLevel = parentLogger.defaultLogLevel,
       minLevel = minLevel ?? parentLogger.minLevel,
       _records = parentLogger._records;

  /// The messages recorded by this logger and by its sub loggers, in the order they were logged.
  List<FakeLogRecord> get records => List.unmodifiable(_records);

  /// The messages recorded at the given [level].
  List<FakeLogRecord> recordsAtLevel(LogsLevel level) =>
      _records.where((record) => record.level == level).toList();

  /// Forgets every recorded message.
  ///
  /// This also clears the records of the sub loggers, because the records are shared.
  void clearRecords() => _records.clear();

  /// {@macro act_foundation.MixinActLogger.log}
  @override
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void log(dynamic message, {required LogsLevel level, dynamic error, StackTrace? stackTrace}) {
    if (!wouldBeLogged(level)) {
      return;
    }

    _records.add(
      FakeLogRecord(
        categories: categories,
        level: level,
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// {@macro act_foundation.MixinActLogger.logMessages}
  ///
  /// The message is recorded at the [defaultLogLevel] level.
  @override
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void logMessages(dynamic message) => log(message, level: defaultLogLevel);

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  @override
  FakeLogger createAbsSubLogger({required String subCategory}) =>
      FakeLogger._createSubLogger(parentLogger: this, subCategory: subCategory);

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  @override
  FakeLogger createAbsSubLoggerMinLevel({required String subCategory, LogsLevel? minLevel}) =>
      FakeLogger._createSubLogger(parentLogger: this, subCategory: subCategory, minLevel: minLevel);

  /// {@macro act_foundation.MixinActLogger.wouldBeLogged}
  @override
  bool wouldBeLogged(LogsLevel level) => minLevel == null || level.index >= minLevel!.index;
}
