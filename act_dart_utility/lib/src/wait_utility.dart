// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

/// Utility class which contains methods to wait specific events
sealed class WaitUtility {
  /// The method waits for an expected status (thanks to the method [isExpectedStatus]).
  ///
  /// The method waits forever unless you give a [timeout].
  ///
  /// If you want to call a method while the status is listened, you can give a [doAction] method.
  /// If [doAction] returns false, it means that a problem occurred and we do no more need to wait
  /// for a status. In that case, the method returns the current value (got with [valueGetter]).
  ///
  /// The timeout (if given) is not operational while [doAction] is called.
  static Future<T> waitForStatus<T>({
    required FutureOr<bool> Function(T status) isExpectedStatus,
    required FutureOr<T> Function() valueGetter,
    required Stream<T> statusEmitter,
    FutureOr<bool> Function()? doAction,
    Duration? timeout,
  }) async {
    final result = await nullableWaitForStatus<T>(
      isExpectedStatus: isExpectedStatus,
      valueGetter: valueGetter,
      statusEmitter: statusEmitter,
      doAction: doAction,
      timeout: timeout,
    );

    // The result can't be null because we give a value getter which returns a non null value
    return result!;
  }

  /// The method waits for an expected status (thanks to the method [isExpectedStatus]).
  ///
  /// The method waits forever unless you give a [timeout].
  ///
  /// If you want to call a method while the status is listened, you can give a [doAction] method.
  /// If [doAction] returns false, it means that a problem occurred and we do no more need to wait
  /// for a status. In that case, the method returns the current value (got with [valueGetter]).
  ///
  /// The timeout (if given) is not operational while [doAction] is called.
  ///
  /// If [valueGetter] is null or if the value returned may be null, the method may return null.
  /// Otherwise, the method always returns a non null value.
  static Future<T?> nullableWaitForStatus<T>({
    required FutureOr<bool> Function(T status) isExpectedStatus,
    required Stream<T> statusEmitter,
    FutureOr<T?> Function()? valueGetter,
    FutureOr<bool> Function()? doAction,
    Duration? timeout,
  }) async {
    // Completer is useful to block a method until an expected data is received
    final completer = Completer<T>();

    // This method is the callback of the [statusEmitter] Stream, it deals with the received
    // [status] to complete the awaiting completer
    Future<void> callback(T status) async {
      if ((await isExpectedStatus(status)) && !completer.isCompleted) {
        completer.complete(status);
      }
    }

    // This wraps the [valueGetter] method to not be forced to test the [valueGetter] nullity each
    // time. In that case, it simply returns null
    Future<T?> safeValueGetter() async =>
        (valueGetter != null) ? valueGetter() : null;

    final statusSub = statusEmitter.listen(callback);

    if (doAction != null && !(await doAction())) {
      // A problem occurred when doing action
      // Useless to wait, we leave the method
      return safeValueGetter();
    }

    final tmpGetValue = await safeValueGetter();

    if (tmpGetValue != null) {
      await callback(tmpGetValue);
    }

    // We wait to receive a status equals to the expected one, if not we return the current status
    // known
    var futureStatus = completer.future;

    if (timeout != null) {
      futureStatus = futureStatus.timeout(timeout);
    }

    T? tmpStatus;
    try {
      tmpStatus = await futureStatus;
    } catch (error) {
      tmpStatus = await safeValueGetter();
    }

    await statusSub.cancel();

    return tmpStatus;
  }
}
