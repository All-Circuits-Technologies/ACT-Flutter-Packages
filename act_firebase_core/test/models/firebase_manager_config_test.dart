// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_firebase_core/act_firebase_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// The options of the project of an application.
const _options = FirebaseOptions(
  apiKey: "aKey",
  appId: "anApp",
  messagingSenderId: "aSender",
  projectId: "aProject",
);

void main() {
  group("FirebaseManagerConfig", () {
    test("names no application and carries no options unless it is given some", () {
      const config = FirebaseManagerConfig(loggerEnabled: true);

      expect(config.firebaseAppName, isNull);
      expect(config.options, isNull);
      expect(config.parentLogsHelper, isNull);
    });

    test("carries no service unless the application declares one", () {
      expect(const FirebaseManagerConfig(loggerEnabled: true).firebaseServices, isEmpty);
    });

    test("equals another configuration which carries the same values", () {
      expect(
        const FirebaseManagerConfig(
          loggerEnabled: true,
          firebaseAppName: "anApp",
          options: _options,
        ),
        const FirebaseManagerConfig(
          loggerEnabled: true,
          firebaseAppName: "anApp",
          options: _options,
        ),
      );
    });

    test("differs from a configuration whose logs are off", () {
      expect(
        const FirebaseManagerConfig(loggerEnabled: true),
        isNot(const FirebaseManagerConfig(loggerEnabled: false)),
      );
    });

    test("differs from a configuration of another application", () {
      expect(
        const FirebaseManagerConfig(loggerEnabled: true, firebaseAppName: "anApp"),
        isNot(const FirebaseManagerConfig(loggerEnabled: true, firebaseAppName: "anotherApp")),
      );
    });
  });
}
