// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_websocket_core/act_websocket_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_ws_service.dart';

void main() {
  setUp(FakeGlobalManager.install);

  group("MixinWsMsgParserService", () {
    test("is mixed on a class which follows the life cycle of a manager", () {
      final logs = FakeExternalLogger();

      expect(FakeWsService(logsHelper: logs.buildHelper()), isA<AbsWithLifeCycle>());
    });
  });

  group("MixinWsMsgParserService.onRawMessageReceived", () {
    test("accepts a message of any kind", () async {
      final parser = _RecordingParser();

      await parser.onRawMessageReceived(<int>[1, 2, 3]);

      expect(parser.received, [
        [1, 2, 3],
      ]);
    });
  });
}

/// A service which only records the raw messages it is given.
class _RecordingParser extends AbsWithLifeCycle with MixinWsMsgParserService {
  /// The messages the service has been given.
  final List<Object?> received = [];

  /// {@macro act_websocket_core.MixinWsMsgParserService.onRawMessageReceived}
  @override
  // The message received can be a string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<void> onRawMessageReceived(dynamic message) async {
    received.add(message);

    await super.onRawMessageReceived(message);
  }
}
