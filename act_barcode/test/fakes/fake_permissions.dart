// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

/// Answers the permission requests of a test in place of the platform.
///
/// The permissions are read and asked for through a platform channel, which answers nothing in a
/// test. This class answers on that channel with the statuses the test decides.
class FakePermissions {
  /// The channel the permissions are read and asked for through.
  static const channel = "flutter.baseflow.com/permissions/methods";

  /// The status the platform answers when the permission is read.
  PermissionStatus status;

  /// The status the platform answers when the permission is asked for.
  PermissionStatus statusAfterRequest;

  /// The permissions which have been asked for.
  final List<int> requested = [];

  /// Class constructor
  FakePermissions({
    this.status = PermissionStatus.denied,
    this.statusAfterRequest = PermissionStatus.granted,
  });

  /// Answers the requests of the test until [stop] is called.
  void serve() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(channel),
      (call) async => switch (call.method) {
        "checkPermissionStatus" => status.index,
        "requestPermissions" => _request(call.arguments as List<Object?>),
        _ => null,
      },
    );
  }

  /// Stops answering the requests of the test.
  static void stop() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(channel),
      null,
    );
  }

  /// Answers a request for [permissions] and remembers which ones were asked for.
  Map<int, int> _request(List<Object?> permissions) {
    final answered = <int, int>{};

    for (final permission in permissions.cast<int>()) {
      requested.add(permission);
      answered[permission] = statusAfterRequest.index;
    }

    return answered;
  }
}
