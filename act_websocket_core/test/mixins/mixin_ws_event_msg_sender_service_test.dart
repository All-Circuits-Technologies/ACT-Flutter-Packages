// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_ws_service.dart';

void main() {
  late FakeExternalLogger logs;
  late FakeWsService service;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    service = FakeWsService(logsHelper: logs.buildHelper(category: "ws"));
  });

  group("MixinWsEventMsgSenderService.sendMessage", () {
    test("writes the event and the data as a JSON object", () async {
      await service.sendMessage(event: FakeEvent.measure, data: {"value": 42});

      expect(jsonDecode(service.sentMessages.single! as String), {
        "event": "measure",
        "data": {"value": 42},
      });
    });

    test("writes the name the event carries on the wire", () async {
      await service.sendMessage(event: FakeEvent.deviceState, data: 1);

      expect(
        (jsonDecode(service.sentMessages.single! as String) as Map)["event"],
        "device-state",
      );
    });

    test("writes under the keys the service asks for", () async {
      service = FakeWsService(
        logsHelper: logs.buildHelper(),
        eventJsonKey: "type",
        dataJsonKey: "payload",
      );

      await service.sendMessage(event: FakeEvent.measure, data: 42);

      expect(jsonDecode(service.sentMessages.single! as String), {
        "type": "measure",
        "payload": 42,
      });
    });

    test("writes a message which carries no data", () async {
      await service.sendMessage(event: FakeEvent.measure, data: null);

      expect(jsonDecode(service.sentMessages.single! as String), {
        "event": "measure",
        "data": null,
      });
    });

    test("returns true when the message has been written", () async {
      expect(await service.sendMessage(event: FakeEvent.measure, data: 42), isTrue);
    });

    test("returns false when the channel is not connected", () async {
      service.isConnected = false;

      expect(await service.sendMessage(event: FakeEvent.measure, data: 42), isFalse);
    });

    test("returns false when the data cannot be encoded as JSON", () async {
      expect(await service.sendMessage(event: FakeEvent.measure, data: Object()), isFalse);
    });

    test("writes nothing when the data cannot be encoded as JSON", () async {
      await service.sendMessage(event: FakeEvent.measure, data: Object());

      expect(service.sentMessages, isEmpty);
    });

    test("warns about the data it cannot encode", () async {
      await service.sendMessage(event: FakeEvent.measure, data: Object());

      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("writes what it sends back through the parser of the same service", () async {
      Object? received;
      service.listenTo(FakeEvent.measure, (data) => received = data);

      await service.sendMessage(event: FakeEvent.measure, data: {"value": 42});
      await service.onRawMessageReceived(service.sentMessages.single);

      expect(received, {"value": 42});
    });
  });
}
