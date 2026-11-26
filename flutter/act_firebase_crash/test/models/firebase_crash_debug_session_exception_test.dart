// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_firebase_crash/src/models/firebase_crash_debug_session_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FirebaseCrashDebugSessionException", () {
    test("names the session the logs belong to, which is what the console shows", () {
      final exception = FirebaseCrashDebugSessionException("anId");

      expect(exception.toString(), "Firebase - crashlytics: logs linked to identifier: anId");
    });
  });
}
