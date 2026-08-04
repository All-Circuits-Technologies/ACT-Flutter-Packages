// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_device_attributes.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_device_time_series.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

import '../../../fakes/fake_thingsboard.dart';

void main() {
  late FakeTbRequestManager requestManager;
  late FakeExternalLogger logger;

  setUp(() {
    requestManager = FakeTbRequestManager();
    logger = FakeExternalLogger();
  });

  /// The time series of the device the tests watch.
  TbDeviceTimeSeries aTimeSeries() => TbDeviceTimeSeries(
    requestManager: requestManager,
    logsHelper: logger.buildHelper(category: "test"),
    deviceId: aDeviceId,
  );

  /// The attributes of the device the tests watch, read in [scope].
  TbDeviceAttributes anAttributeSet({AttributeScope scope = AttributeScope.SHARED_SCOPE}) =>
      TbDeviceAttributes(
        requestManager: requestManager,
        logsHelper: logger.buildHelper(category: "test"),
        deviceId: aDeviceId,
        scope: scope,
      );

  /// The websocket the device pushes its telemetry over.
  FakeTelemetryService websocket() => requestManager.client.telemetryService;

  /// Pushes [update] the way the websocket of the server does, and lets the package read it.
  Future<void> push(SubscriptionUpdate update) async {
    websocket().current!.onData(update);
    await pumpEventQueue();
  }

  group("ATbTelemetry.subscribeElements", () {
    test("asks the server for the keys it is given", () async {
      final timeSeries = aTimeSeries();

      final result = await timeSeries.subscribeElements(keys: ["temp", "hum"]);

      expect(result, isTrue);
      expect(websocket().currentKeys, ["hum", "temp"]);
    });

    test("asks for the keys in the same order whatever the order they are given in", () async {
      await aTimeSeries().subscribeElements(keys: ["temp", "hum"]);
      final first = websocket().currentKeys;

      requestManager = FakeTbRequestManager();
      await aTimeSeries().subscribeElements(keys: ["hum", "temp"]);

      expect(websocket().currentKeys, first);
    });

    test("asks the server once for the keys it is asked for twice", () async {
      final timeSeries = aTimeSeries();

      await timeSeries.subscribeElements(keys: ["temp"]);
      await timeSeries.subscribeElements(keys: ["temp"]);

      expect(websocket().subscribed.length, 1);
    });

    test("gives up the subscription it holds before it asks for a new one", () async {
      final timeSeries = aTimeSeries();

      await timeSeries.subscribeElements(keys: ["temp"]);
      await timeSeries.subscribeElements(keys: ["hum"]);

      expect(websocket().unsubscribed.length, 1);
      expect(websocket().subscribed.length, 2);
      expect(websocket().currentKeys, ["hum", "temp"]);
    });

    test("watches nothing when the server refuses the subscription", () async {
      final timeSeries = aTimeSeries();
      requestManager.answers.add(RequestStatus.globalError);

      final result = await timeSeries.subscribeElements(keys: ["temp"]);

      expect(result, isFalse);
      expect(websocket().subscribed, isEmpty);
    });

    test("keeps the subscription it holds when the server refuses to give it up", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);
      requestManager.answers.add(RequestStatus.globalError);

      final result = await timeSeries.subscribeElements(keys: ["hum"]);

      expect(result, isFalse);
      expect(websocket().currentKeys, ["temp"]);
    });
  });

  group("ATbTelemetry.unSubscribeElements", () {
    test("keeps watching a key it is asked to forget, in case it is asked for again", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);

      final result = await timeSeries.unSubscribeElements(keys: ["temp"]);

      expect(result, isTrue);
      expect(websocket().currentKeys, ["temp"]);
    });

    test("does nothing of a key it does not watch", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);

      final result = await timeSeries.unSubscribeElements(keys: ["hum"]);

      expect(result, isTrue);
      expect(websocket().currentKeys, ["temp"]);
    });

    test("keeps watching a key which is still asked for by someone else", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);
      await timeSeries.subscribeElements(keys: ["temp"]);

      await timeSeries.unSubscribeElements(keys: ["temp"]);

      expect(websocket().currentKeys, ["temp"]);
    });
  });

  group("ATbTelemetry.getTelemetryValue", () {
    test("knows nothing of a key before the server sent a value for it", () async {
      final timeSeries = aTimeSeries();

      await timeSeries.subscribeElements(keys: ["temp"]);

      expect(timeSeries.getTelemetryValue("temp"), isNull);
    });

    test("answers the value the server sent", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);

      await push(anUpdate({"temp": (42, "20.5")}));

      expect(timeSeries.getTelemetryValue("temp"), const TbTsValue(ts: 42, value: "20.5"));
    });

    test("knows nothing of a key it never asked for", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);

      await push(anUpdate({"hum": (42, "60")}));

      expect(timeSeries.getTelemetryValue("hum"), isNull);
    });

    test("answers the value which was sent last", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);

      await push(anUpdate({"temp": (42, "20.5")}));
      await push(anUpdate({"temp": (43, "21.0")}));

      expect(timeSeries.getTelemetryValue("temp"), const TbTsValue(ts: 43, value: "21.0"));
    });

    test("keeps the value it holds when the server sends an older one", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);

      await push(anUpdate({"temp": (43, "21.0")}));
      await push(anUpdate({"temp": (42, "20.5")}));

      expect(timeSeries.getTelemetryValue("temp"), const TbTsValue(ts: 43, value: "21.0"));
    });
  });

  group("ATbTelemetry.telemetryStream", () {
    test("tells which values were updated", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);
      final updates = <Map<String, TbTsValue>>[];
      timeSeries.telemetryStream.listen(updates.add);

      await push(anUpdate({"temp": (42, "20.5")}));

      expect(updates.single, {"temp": const TbTsValue(ts: 42, value: "20.5")});
    });

    test("tells that nothing was updated when the value which was sent is older", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);
      await push(anUpdate({"temp": (43, "21.0")}));
      final updates = <Map<String, TbTsValue>>[];
      timeSeries.telemetryStream.listen(updates.add);

      await push(anUpdate({"temp": (42, "20.5")}));

      expect(updates.single, isEmpty);
    });

    test("says nothing of an update which carries an error", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);
      final updates = <Map<String, TbTsValue>>[];
      timeSeries.telemetryStream.listen(updates.add);

      await push(anUpdate({"temp": (42, "20.5")}, errorCode: 1));

      expect(updates, isEmpty);
      expect(timeSeries.getTelemetryValue("temp"), isNull);
    });
  });

  group("ATbTelemetry.dispose", () {
    test("gives up the subscription it holds", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);

      await timeSeries.dispose();

      expect(websocket().current, isNull);
    });

    test("forgets the values it holds", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);
      await push(anUpdate({"temp": (42, "20.5")}));

      await timeSeries.dispose();

      expect(timeSeries.getTelemetryValue("temp"), isNull);
    });

    test("stops telling which values were updated", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);
      var closed = false;
      timeSeries.telemetryStream.listen(null, onDone: () => closed = true);

      await timeSeries.dispose();
      await pumpEventQueue();

      expect(closed, isTrue);
    });
  });

  group("TbDeviceTimeSeries", () {
    test("asks the server for the time series of the device", () async {
      await aTimeSeries().subscribeElements(keys: ["temp"]);

      final command = websocket().current!.subscriptionCommands.single;

      expect(command, isA<TimeseriesSubscriptionCmd>());
      expect((command as TimeseriesSubscriptionCmd).entityId, aDeviceId);
      expect(command.entityType, EntityType.DEVICE);
    });

    test("orders the values it receives on the moment they were received", () async {
      final timeSeries = aTimeSeries();
      await timeSeries.subscribeElements(keys: ["temp"]);

      await push(anUpdate({"temp": (42, "20.5")}));

      expect(timeSeries.getTelemetryValue("temp")?.ts, 42);
    });
  });

  group("TbDeviceAttributes", () {
    test("asks the server for the attributes of the device in the scope it reads", () async {
      await anAttributeSet(scope: AttributeScope.CLIENT_SCOPE).subscribeElements(keys: ["temp"]);

      final command = websocket().current!.subscriptionCommands.single;

      expect(command, isA<AttributesSubscriptionCmd>());
      expect((command as AttributesSubscriptionCmd).scope, AttributeScope.CLIENT_SCOPE);
      expect(command.entityId, aDeviceId);
    });

    test("answers the attribute the server sent", () async {
      final attributes = anAttributeSet();
      await attributes.subscribeElements(keys: ["temp"]);

      await push(anUpdate({"temp": (42, "20.5")}));

      expect(attributes.getTelemetryValue("temp")?.value, "20.5");
      expect(attributes.getTelemetryValue("temp")?.lastUpdateTs, 42);
    });

    test("orders the attributes it receives on the moment they were updated", () async {
      final attributes = anAttributeSet();
      await attributes.subscribeElements(keys: ["temp"]);

      await push(anUpdate({"temp": (43, "21.0")}));
      await push(anUpdate({"temp": (42, "20.5")}));

      expect(attributes.getTelemetryValue("temp")?.value, "21.0");
    });
  });
}
