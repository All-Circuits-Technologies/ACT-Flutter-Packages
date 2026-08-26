// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_thingsboard.dart';

void main() {
  late FakeTbRequestManager requestManager;
  late TbDeviceValues deviceValues;

  setUp(() {
    requestManager = FakeTbRequestManager();
    deviceValues = TbDeviceValues(
      requestManager: requestManager,
      deviceId: aDeviceId,
      logsHelper: FakeExternalLogger().buildHelper(category: "test"),
    );
  });

  tearDown(() => deviceValues.dispose());

  /// The websocket the device pushes its telemetry over.
  FakeTelemetryService websocket() => requestManager.client.telemetryService;

  /// Pushes the attributes [values] of [scope] the way the websocket of the server does.
  Future<void> pushAttributes(
    AttributeScope scope,
    Map<String, (int, String?)> values,
  ) async {
    websocket().attributesOf(scope)!.onData(anUpdate(values));
    await pumpEventQueue();
  }

  /// Pushes the time series [values] the way the websocket of the server does.
  Future<void> pushTimeSeries(Map<String, (int, String?)> values) async {
    websocket().timeSeries!.onData(anUpdate(values));
    await pumpEventQueue();
  }

  group("TbTelemetryHandler.areWeListeningTelemetries", () {
    test("says that a handler which was asked for nothing listens to nothing", () {
      expect(deviceValues.createTelemetryHandler().areWeListeningTelemetries, isFalse);
    });

    test("says that a handler which was asked for a key listens to something", () async {
      final handler = deviceValues.createTelemetryHandler();

      await handler.add(tsKeys: ["temp"]);

      expect(handler.areWeListeningTelemetries, isTrue);
    });
  });

  group("TbTelemetryHandler.add", () {
    test("asks the server for the attributes of the scope they belong to", () async {
      final handler = deviceValues.createTelemetryHandler();

      await handler.add(clientKeys: ["temp"], sharedKeys: ["hum"], serverKeys: ["level"]);

      expect(websocket().keysOf(websocket().attributesOf(AttributeScope.CLIENT_SCOPE)), ["temp"]);
      expect(websocket().keysOf(websocket().attributesOf(AttributeScope.SHARED_SCOPE)), ["hum"]);
      expect(websocket().keysOf(websocket().attributesOf(AttributeScope.SERVER_SCOPE)), ["level"]);
      expect(handler.clientAttrKeys, ["temp"]);
      expect(handler.sharedAttrKeys, ["hum"]);
      expect(handler.serverAttrKeys, ["level"]);
    });

    test("asks the server for the time series it is given", () async {
      final handler = deviceValues.createTelemetryHandler();

      await handler.add(tsKeys: ["temp"]);

      expect(websocket().keysOf(websocket().timeSeries), ["temp"]);
      expect(handler.timeSeriesKeys, ["temp"]);
    });

    test("keeps one key when the same one is asked for twice", () async {
      final handler = deviceValues.createTelemetryHandler();

      await handler.add(tsKeys: ["temp"]);
      await handler.add(tsKeys: ["temp"]);

      expect(handler.timeSeriesKeys, ["temp"]);
    });

    test("takes note of nothing when the server refuses the subscription", () async {
      final handler = deviceValues.createTelemetryHandler();
      requestManager.answers.add(RequestStatus.globalError);

      final result = await handler.add(tsKeys: ["temp"]);

      expect(result, isFalse);
      expect(handler.timeSeriesKeys, isEmpty);
    });

    test("stops at the first scope the server refuses", () async {
      final handler = deviceValues.createTelemetryHandler();
      requestManager.answers.add(RequestStatus.globalError);

      await handler.add(clientKeys: ["temp"], tsKeys: ["hum"]);

      expect(handler.clientAttrKeys, isEmpty);
      expect(handler.timeSeriesKeys, isEmpty);
    });
  });

  group("TbTelemetryHandler.addKeys", () {
    test("asks the server for the keys it knows the elements under", () async {
      final handler = deviceValues.createTelemetryHandler();

      await handler.addKeys(tsKeys: FakeTelemetryKeys.values);

      expect(handler.timeSeriesKeys, ["temp", "hum"]);
    });
  });

  group("TbTelemetryHandler.remove", () {
    test("forgets the keys it is given", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(tsKeys: ["temp", "hum"]);

      await handler.remove(tsKeys: ["temp"]);

      expect(handler.timeSeriesKeys, ["hum"]);
    });

    test("does nothing of a key it does not listen to", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(tsKeys: ["temp"]);

      final result = await handler.remove(tsKeys: ["hum"]);

      expect(result, isTrue);
      expect(handler.timeSeriesKeys, ["temp"]);
    });
  });

  group("TbTelemetryHandler.removeKeys", () {
    test("forgets the elements it knows the keys of", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.addKeys(tsKeys: FakeTelemetryKeys.values);

      await handler.removeKeys(tsKeys: [FakeTelemetryKeys.temperature]);

      expect(handler.timeSeriesKeys, ["hum"]);
    });
  });

  group("TbTelemetryHandler.removeAll", () {
    test("forgets every key of every scope", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(
        clientKeys: ["temp"],
        sharedKeys: ["hum"],
        serverKeys: ["level"],
        tsKeys: ["speed"],
      );

      await handler.removeAll();

      expect(handler.areWeListeningTelemetries, isFalse);
    });

    test("answers that there was nothing to forget", () async {
      expect(await deviceValues.createTelemetryHandler().removeAll(), isTrue);
    });
  });

  group("TbTelemetryHandler.getTsValues", () {
    test("answers the time series it listens to and which were received", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(tsKeys: ["temp", "hum"]);

      await pushTimeSeries({"temp": (42, "20.5")});

      expect(handler.getTsValues(), {"temp": const TbTsValue(ts: 42, value: "20.5")});
    });

    test("answers nothing before the server sent anything", () async {
      final handler = deviceValues.createTelemetryHandler();

      await handler.add(tsKeys: ["temp"]);

      expect(handler.getTsValues(), isEmpty);
    });
  });

  group("TbTelemetryHandler.getAttributeValuesByScope", () {
    test("answers the attributes of the scope which were received", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(sharedKeys: ["temp"]);

      await pushAttributes(AttributeScope.SHARED_SCOPE, {"temp": (42, "20.5")});

      final values = handler.getAttributeValuesByScope(scope: AttributeScope.SHARED_SCOPE);

      expect(values.keys, ["temp"]);
      expect(values["temp"]?.data.value, "20.5");
      expect(values["temp"]?.scope, AttributeScope.SHARED_SCOPE);
    });

    test("answers nothing of a scope it listens to nothing in", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(sharedKeys: ["temp"]);
      await pushAttributes(AttributeScope.SHARED_SCOPE, {"temp": (42, "20.5")});

      final values = handler.getAttributeValuesByScope(scope: AttributeScope.CLIENT_SCOPE);

      expect(values, isEmpty);
    });
  });

  group("TbTelemetryHandler.getAttributeValues", () {
    test("answers the attributes of every scope", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(clientKeys: ["temp"], sharedKeys: ["hum"], serverKeys: ["level"]);

      await pushAttributes(AttributeScope.CLIENT_SCOPE, {"temp": (42, "20.5")});
      await pushAttributes(AttributeScope.SHARED_SCOPE, {"hum": (42, "60")});
      await pushAttributes(AttributeScope.SERVER_SCOPE, {"level": (42, "3")});

      expect(handler.getAttributeValues().keys, ["temp", "hum", "level"]);
    });
  });

  group("TbTelemetryHandler.attributesStream", () {
    test("tells which attributes were updated, and in which scope", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(sharedKeys: ["temp"]);
      final updates = <Map<String, TbExtAttributeData>>[];
      handler.attributesStream.listen(updates.add);

      await pushAttributes(AttributeScope.SHARED_SCOPE, {"temp": (42, "20.5")});

      expect(updates.single.keys, ["temp"]);
      expect(updates.single["temp"]?.scope, AttributeScope.SHARED_SCOPE);
    });

    test("says nothing of an attribute another handler listens to", () async {
      final handler = deviceValues.createTelemetryHandler();
      final other = deviceValues.createTelemetryHandler();
      await handler.add(sharedKeys: ["temp"]);
      await other.add(sharedKeys: ["hum"]);
      final updates = <Map<String, TbExtAttributeData>>[];
      handler.attributesStream.listen(updates.add);

      await pushAttributes(AttributeScope.SHARED_SCOPE, {"hum": (42, "60")});

      expect(updates, isEmpty);
    });
  });

  group("TbTelemetryHandler.timeSeriesStream", () {
    test("tells which time series were updated", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(tsKeys: ["temp"]);
      final updates = <Map<String, TbTsValue>>[];
      handler.timeSeriesStream.listen(updates.add);

      await pushTimeSeries({"temp": (42, "20.5")});

      expect(updates.single, {"temp": const TbTsValue(ts: 42, value: "20.5")});
    });

    test("says nothing of a time series another handler listens to", () async {
      final handler = deviceValues.createTelemetryHandler();
      final other = deviceValues.createTelemetryHandler();
      await handler.add(tsKeys: ["temp"]);
      await other.add(tsKeys: ["hum"]);
      final updates = <Map<String, TbTsValue>>[];
      handler.timeSeriesStream.listen(updates.add);

      await pushTimeSeries({"hum": (42, "60")});

      expect(updates, isEmpty);
    });
  });

  group("TbTelemetryHandler.close", () {
    test("forgets every key it listens to", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(tsKeys: ["temp"]);

      await handler.close();

      expect(handler.areWeListeningTelemetries, isFalse);
    });

    test("stops telling which values were updated", () async {
      final handler = deviceValues.createTelemetryHandler();
      await handler.add(tsKeys: ["temp"]);
      var closed = false;
      handler.timeSeriesStream.listen(null, onDone: () => closed = true);

      await handler.close();
      await pumpEventQueue();

      expect(closed, isTrue);
    });

    test("leaves the other handlers of the device listening", () async {
      final handler = deviceValues.createTelemetryHandler();
      final other = deviceValues.createTelemetryHandler();
      await handler.add(tsKeys: ["temp"]);
      await other.add(tsKeys: ["hum"]);

      await handler.close();

      expect(other.timeSeriesKeys, ["hum"]);
      expect(websocket().keysOf(websocket().timeSeries), contains("hum"));
    });
  });
}
