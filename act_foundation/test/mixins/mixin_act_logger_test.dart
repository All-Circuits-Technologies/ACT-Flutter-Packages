// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a call to one of the shortcut methods of [MixinActLogger] forwarded to `log`.
class _LoggedCall {
  final Object? message;
  final LogsLevel level;
  final Object? error;
  final StackTrace? stackTrace;

  const _LoggedCall({required this.message, required this.level, this.error, this.stackTrace});
}

/// A logger which only remembers what it was asked to log.
///
/// This package cannot use the shared test utilities, because they depend on it.
class _RecordingLogger with MixinActLogger {
  final List<_LoggedCall> calls = [];

  final List<Object?> messages = [];

  @override
  // The logger interface takes the messages as dynamic values.
  // ignore: avoid_annotating_with_dynamic
  void log(dynamic message, {required LogsLevel level, dynamic error, StackTrace? stackTrace}) =>
      calls.add(
        _LoggedCall(message: message, level: level, error: error, stackTrace: stackTrace),
      );

  @override
  // The logger interface takes the messages as dynamic values.
  // ignore: avoid_annotating_with_dynamic
  void logMessages(dynamic message) => messages.add(message);

  @override
  MixinActLogger createAbsSubLogger({required String subCategory}) => _RecordingLogger();

  @override
  MixinActLogger createAbsSubLoggerMinLevel({required String subCategory, LogsLevel? minLevel}) =>
      _RecordingLogger();

  @override
  bool wouldBeLogged(LogsLevel level) => true;
}

void main() {
  group("MixinActLogger shortcuts", () {
    test("logs at the trace level through t", () {
      final logger = _RecordingLogger();

      logger.t("a message");

      expect(logger.calls.single.level, LogsLevel.trace);
    });

    test("logs at the debug level through d", () {
      final logger = _RecordingLogger();

      logger.d("a message");

      expect(logger.calls.single.level, LogsLevel.debug);
    });

    test("logs at the info level through i", () {
      final logger = _RecordingLogger();

      logger.i("a message");

      expect(logger.calls.single.level, LogsLevel.info);
    });

    test("logs at the warn level through w", () {
      final logger = _RecordingLogger();

      logger.w("a message");

      expect(logger.calls.single.level, LogsLevel.warn);
    });

    test("logs at the error level through e", () {
      final logger = _RecordingLogger();

      logger.e("a message");

      expect(logger.calls.single.level, LogsLevel.error);
    });

    test("logs at the fatal level through f", () {
      final logger = _RecordingLogger();

      logger.f("a message");

      expect(logger.calls.single.level, LogsLevel.fatal);
    });

    test("forwards the message to log", () {
      final logger = _RecordingLogger();

      logger.i("a message");

      expect(logger.calls.single.message, "a message");
    });

    test("forwards the optional error and stack trace to log", () {
      final logger = _RecordingLogger();
      final error = Exception("boom");
      final stackTrace = StackTrace.current;

      logger.e("a message", error, stackTrace);

      expect(logger.calls.single.error, error);
      expect(logger.calls.single.stackTrace, stackTrace);
    });

    test("leaves the error and the stack trace null when they are not given", () {
      final logger = _RecordingLogger();

      logger.e("a message");

      expect(logger.calls.single.error, isNull);
      expect(logger.calls.single.stackTrace, isNull);
    });

    test("accepts a message which is not a string", () {
      final logger = _RecordingLogger();

      logger.i(42);

      expect(logger.calls.single.message, 42);
    });

    test("keeps the messages in the order they were logged", () {
      final logger = _RecordingLogger();

      logger
        ..i("first")
        ..w("second")
        ..e("third");

      expect(
        logger.calls.map((call) => call.message).toList(),
        ["first", "second", "third"],
      );
    });
  });
}
