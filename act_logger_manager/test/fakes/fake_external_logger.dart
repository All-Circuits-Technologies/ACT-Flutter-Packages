// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:equatable/equatable.dart';

/// A message given to a fake external logger.
class FakeExternalLogRecord extends Equatable {
  /// The categories which came with the message.
  final List<String>? categories;

  /// The error which came with the message.
  final Object? error;

  /// The level the message was logged at.
  final LogsLevel level;

  /// The logged message.
  final Object? message;

  /// The stack trace which came with the message.
  final StackTrace? stackTrace;

  /// The time the message was logged at.
  final DateTime? time;

  /// Class constructor
  const FakeExternalLogRecord({
    required this.level,
    required this.message,
    this.categories,
    this.error,
    this.stackTrace,
    this.time,
  });

  @override
  String toString() => "FakeExternalLogRecord(level: $level, categories: $categories, "
      "message: $message, error: $error)";

  @override
  List<Object?> get props => [categories, error, level, message, stackTrace, time];
}

/// An external logger which records the messages instead of writing them anywhere.
///
/// This is the logger to give to the classes of the package which log through an external logger,
/// so that a test asserts on what reached it. It also counts its own initializations and disposals,
/// which is what the loggers owning other loggers have to be checked on.
class FakeExternalLogger with MixinWithLifeCycleDispose, MixinWithLifeCycle, MixinExternalLogger {
  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.getter}
  ///
  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.setter}
  @override
  LogsLevel minLevel;

  /// The messages the logger has been given, in the order they were logged.
  final List<FakeExternalLogRecord> records = [];

  /// The number of times the logger has been initialized.
  int initCount = 0;

  /// The number of times the logger has been disposed.
  int disposeCount = 0;

  /// Class constructor
  FakeExternalLogger({this.minLevel = LogsLevel.all});

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    initCount++;
  }

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
  }) => records.add(
    FakeExternalLogRecord(
      level: level,
      message: message,
      categories: categories,
      error: error,
      stackTrace: stackTrace,
      time: time,
    ),
  );

  /// {@macro act_logger_manager.MixinExternalLogger.wouldBeLogged}
  @override
  bool wouldBeLogged({required LogsLevel level, List<String>? categories}) =>
      level.index >= minLevel.index;

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    disposeCount++;
    await super.disposeLifeCycle();
  }
}

/// The keys the tests register their fake loggers with.
enum FakeLoggers {
  /// The first fake logger.
  first,

  /// The second fake logger.
  second,
}
