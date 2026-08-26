// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves the assets a test needs, in place of the ones of the application bundle.
///
/// The asset bundle reads its files through a platform channel; this class answers on that channel
/// with the contents the test gives, and lets every other key fail the way a missing asset does.
///
/// A test which serves assets has to stop serving them once it is over, so that the next test
/// starts from an empty bundle:
///
/// ```dart
/// void main() {
///   TestWidgetsFlutterBinding.ensureInitialized();
///
///   tearDown(FakeAssets.stop);
///
///   test("reads its configuration", () async {
///     FakeAssets.serve({"assets/config/default.yaml": "logs:\n  level: warning"});
///
///     ...
///   });
/// }
/// ```
sealed class FakeAssets {
  /// The channel the asset bundle reads its files through.
  static const channel = "flutter/assets";

  /// Serves [contents], where a key is an asset key and a value the content of that asset.
  ///
  /// Only these contents are served: a previous call is replaced rather than added to, and a key
  /// which is not in [contents] is reported as missing.
  static void serve(Map<String, String> contents) {
    final served = Map<String, String>.from(contents);

    // The bundle keeps the files it has already read, which are the ones of the previous test.
    rootBundle.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      channel,
      (message) async {
        if (message == null) {
          return null;
        }

        final content = served[utf8.decode(message.buffer.asUint8List())];
        if (content == null) {
          return null;
        }

        return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
      },
    );
  }

  /// Stops serving the assets of the test and forgets the ones which have been read.
  static void stop() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      channel,
      null,
    );
    rootBundle.clear();
  }
}
