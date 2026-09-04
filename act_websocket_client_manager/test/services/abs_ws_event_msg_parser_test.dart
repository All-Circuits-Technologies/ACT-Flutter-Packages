// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_websocket.dart';

void main() {
  setUp(FakeGlobalManager.install);

  /// The message an application sends for the event it listens for, carrying [data].
  String aMessage({String event = "aThing", Object? data = "a value"}) =>
      jsonEncode({"event": event, "data": data});

  group("AbsWsEventMsgParser", () {
    test("hands the data of the event to the one who listens for it", () async {
      final parser = FakeEventParser()..listenFor(FakeEvents.aThing);

      await parser.onRawMessageReceived(aMessage());

      expect(parser.data, ["a value"]);
    });

    test("reads a message which is already a json object", () async {
      final parser = FakeEventParser()..listenFor(FakeEvents.aThing);

      await parser.onRawMessageReceived(<String, dynamic>{"event": "aThing", "data": "a value"});

      expect(parser.data, ["a value"]);
    });

    test("says nothing of an event nobody listens for", () async {
      final parser = FakeEventParser();

      await parser.onRawMessageReceived(aMessage());

      expect(parser.data, isEmpty);
    });

    test("drops a message whose event it does not know", () async {
      final parser = FakeEventParser()..listenFor(FakeEvents.aThing);

      await parser.onRawMessageReceived(aMessage(event: "anotherThing"));

      expect(parser.data, isEmpty);
    });

    test("drops a message which carries no data", () async {
      final parser = FakeEventParser()..listenFor(FakeEvents.aThing);

      await parser.onRawMessageReceived(jsonEncode({"event": "aThing"}));

      expect(parser.data, isEmpty);
    });

    test("drops a message which is not json", () async {
      final parser = FakeEventParser()..listenFor(FakeEvents.aThing);

      await parser.onRawMessageReceived("not json");

      expect(parser.data, isEmpty);
    });

    test("drops a message which is neither a text nor a json object", () async {
      final parser = FakeEventParser()..listenFor(FakeEvents.aThing);

      await parser.onRawMessageReceived(42);

      expect(parser.data, isEmpty);
    });

    test("reads the event and the data under the keys it was given", () async {
      final parser = FakeEventParser(eventJsonKey: "kind", dataJsonKey: "payload")
        ..listenFor(FakeEvents.aThing);

      await parser.onRawMessageReceived(jsonEncode({"kind": "aThing", "payload": "a value"}));

      expect(parser.data, ["a value"]);
    });

    test("reads the event and the data under the usual keys by default", () async {
      final parser = FakeEventParser();

      expect(parser.eventJsonKey, "event");
      expect(parser.dataJsonKey, "data");
    });

    test("writes its logs under the ones of the parent it was given", () {
      final logs = FakeExternalLogger();

      final parser = FakeEventParser(parentLogger: logs.buildHelper(category: "aClient"));

      expect(parser.logsHelper.categories, ["aClient", "aParser"]);
    });

    test("writes its logs under its own category when it has no parent", () {
      expect(FakeEventParser().logsHelper.categories, ["aParser"]);
    });
  });
}
