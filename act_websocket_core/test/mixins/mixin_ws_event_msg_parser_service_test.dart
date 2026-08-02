// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

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

  group("MixinWsEventMsgParserService", () {
    test("reads the event and the data under the default keys", () {
      expect(service.eventJsonKey, "event");
      expect(service.dataJsonKey, "data");
    });
  });

  group("MixinWsEventMsgParserService.onRawMessageReceived", () {
    test("gives the data of the message to the callback of its event", () async {
      Object? received;
      service.listenTo(FakeEvent.measure, (data) => received = data);

      await service.onRawMessageReceived('{"event": "measure", "data": {"value": 42}}');

      expect(received, {"value": 42});
    });

    test("reads a message which is already a JSON object", () async {
      Object? received;
      service.listenTo(FakeEvent.measure, (data) => received = data);

      await service.onRawMessageReceived(<String, dynamic>{
        "event": "measure",
        "data": "a value",
      });

      expect(received, "a value");
    });

    test("reads the event from the name it carries on the wire", () async {
      var called = false;
      service.listenTo(FakeEvent.deviceState, (data) => called = true);

      await service.onRawMessageReceived('{"event": "device-state", "data": 1}');

      expect(called, isTrue);
    });

    test("reads the keys the service asks for instead of the default ones", () async {
      service = FakeWsService(
        logsHelper: logs.buildHelper(),
        eventJsonKey: "type",
        dataJsonKey: "payload",
      );
      Object? received;
      service.listenTo(FakeEvent.measure, (data) => received = data);

      await service.onRawMessageReceived('{"type": "measure", "payload": 42}');

      expect(received, 42);
    });

    test("gives a null data to the callback when the message carries one", () async {
      var called = false;
      Object? received = "not null";
      service.listenTo(FakeEvent.measure, (data) {
        called = true;
        received = data;
      });

      await service.onRawMessageReceived('{"event": "measure", "data": null}');

      expect(called, isTrue);
      expect(received, isNull);
    });

    test("calls nothing for an event no callback was registered for", () async {
      var called = false;
      service.listenTo(FakeEvent.deviceState, (data) => called = true);

      await service.onRawMessageReceived('{"event": "measure", "data": 42}');

      expect(called, isFalse);
    });

    test("warns about nothing for an event no callback was registered for", () async {
      await service.onRawMessageReceived('{"event": "measure", "data": 42}');

      expect(logs.records, isEmpty);
    });

    test("refuses a message which is neither a string nor a JSON object", () async {
      var called = false;
      service.listenTo(FakeEvent.measure, (data) => called = true);

      await service.onRawMessageReceived(42);

      expect(called, isFalse);
      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("refuses a string which is not JSON", () async {
      await service.onRawMessageReceived("not json");

      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("refuses a message which is a JSON value but not an object", () async {
      await service.onRawMessageReceived("[1, 2, 3]");

      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("refuses a message which carries no event", () async {
      await service.onRawMessageReceived('{"data": 42}');

      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("refuses a message whose event is not one of the service", () async {
      await service.onRawMessageReceived('{"event": "unknown", "data": 42}');

      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("refuses a message which carries no data for an event it listens to", () async {
      var called = false;
      service.listenTo(FakeEvent.measure, (data) => called = true);

      await service.onRawMessageReceived('{"event": "measure"}');

      expect(called, isFalse);
      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("hands the message over to the parser it is mixed on top of", () async {
      await service.onRawMessageReceived('{"event": "measure", "data": 42}');

      expect(service.rawMessages, ['{"event": "measure", "data": 42}']);
    });

    test("keeps the last callback registered for an event", () async {
      final called = <String>[];
      service
        ..listenTo(FakeEvent.measure, (data) => called.add("first"))
        ..listenTo(FakeEvent.measure, (data) => called.add("second"));

      await service.onRawMessageReceived('{"event": "measure", "data": 42}');

      expect(called, ["second"]);
    });

    test("waits for a callback which does not answer right away", () async {
      var done = false;
      service.listenTo(FakeEvent.measure, (data) async {
        await Future<void>.delayed(Duration.zero);
        done = true;
      });

      await service.onRawMessageReceived('{"event": "measure", "data": 42}');

      expect(done, isTrue);
    });
  });
}
