// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/act_thingsboard_client_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

import '../../fakes/fake_tb_telemetries_ui.dart';

void main() {
  late FakeGlobalManager globalManager;
  late FakeInternetManager internet;
  late FakeTbClient client;
  late FakeTbReqManager requestManager;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    internet = FakeInternetManager();
    client = FakeTbClient();
    requestManager = FakeTbReqManager();

    globalGetIt()
      ..registerSingleton<InternetConnectivityManager>(internet)
      ..registerSingleton<TbNoAuthServerReqManager>(FakeNoAuthReqManager(client))
      ..registerSingleton<FakeTbReqManager>(requestManager);

    await requestManager.initLifeCycle();
  });

  tearDown(() async {
    await internet.close();
    await requestManager.disposeLifeCycle();
    await globalManager.reset();
  });

  /// The bloc of a page which watches the telemetry of a device.
  ///
  /// The server answers [device] when the page asks which device it watches, and it says that it
  /// failed when [serverFails] says so.
  Future<TbTelemetriesUiBloc<FakeTbReqManager>> aBloc({
    DeviceInfo? device,
    bool serverFails = false,
    List<MixinTelemetriesKeys> tsKeys = const [FakeTelemetryKeys.temperature],
    List<MixinTelemetriesKeys> sharedKeys = const [],
  }) async {
    final bloc = TbTelemetriesUiBloc<FakeTbReqManager>(
      getDeviceInfo: () async =>
          (success: !serverFails, deviceInfo: serverFails ? null : device ?? aDeviceInfo()),
      timeSeriesKeys: tsKeys,
      sharedAttributesKeys: sharedKeys,
    );
    addTearDown(bloc.close);
    await pumpEventQueue();

    return bloc;
  }

  /// Pushes the time series [values] the way the websocket of the server does.
  Future<void> pushTimeSeries(Map<String, (int, String?)> values) async {
    client.telemetryService.timeSeries!.onData(anUpdate(values));
    await pumpEventQueue();
  }

  /// Pushes the shared attributes [values] the way the websocket of the server does.
  Future<void> pushAttributes(Map<String, (int, String?)> values) async {
    client.telemetryService.attributesOf(AttributeScope.SHARED_SCOPE)!.onData(anUpdate(values));
    await pumpEventQueue();
  }

  group("TbTelemetriesUiBloc", () {
    test("watches the telemetry of the device the page names", () async {
      await aBloc();

      expect(client.telemetryService.timeSeries, isNotNull);
    });

    test("tells the page which device it watches", () async {
      final bloc = await aBloc(device: aDeviceInfo(name: "a named device"));

      expect(bloc.state.device?.name, "a named device");
    });

    test("watches the attributes of the scope the page names", () async {
      await aBloc(tsKeys: const [], sharedKeys: const [FakeTelemetryKeys.temperature]);

      expect(client.telemetryService.attributesOf(AttributeScope.SHARED_SCOPE), isNotNull);
      expect(client.telemetryService.timeSeries, isNull);
    });

    test("shows the page as loading until a value arrives", () async {
      final bloc = await aBloc();

      expect(bloc.state.telemetryLoading, isTrue);
      expect(bloc.state.genericError, TbTelemetriesUiError.noError);
    });

    test("stops the loading once a value arrives", () async {
      final bloc = await aBloc();

      await pushTimeSeries({"temp": (42, "20.5")});

      expect(bloc.state.telemetryLoading, isFalse);
      expect(bloc.state.getTsValue<double>(FakeTelemetryKeys.temperature), 20.5);
    });

    test("keeps the values it already holds when a new one arrives", () async {
      final bloc = await aBloc(
        tsKeys: const [FakeTelemetryKeys.temperature, FakeTelemetryKeys.humidity],
      );

      await pushTimeSeries({"temp": (42, "20.5")});
      await pushTimeSeries({"hum": (43, "60")});

      expect(bloc.state.getTsValue<double>(FakeTelemetryKeys.temperature), 20.5);
      expect(bloc.state.getTsValue<int>(FakeTelemetryKeys.humidity), 60);
    });

    test("tells the page about the attributes which arrive", () async {
      final bloc = await aBloc(
        tsKeys: const [],
        sharedKeys: const [FakeTelemetryKeys.temperature],
      );

      await pushAttributes({"temp": (42, "20.5")});

      expect(bloc.state.getAttributeValue<double>(FakeTelemetryKeys.temperature), 20.5);
      expect(bloc.state.telemetryLoading, isFalse);
    });

    test("says that there is no internet at start", () async {
      internet.connected = false;

      final bloc = await aBloc();

      expect(bloc.state.genericError, TbTelemetriesUiError.noInternetAtStart);
      expect(bloc.state.telemetryLoading, isFalse);
      expect(client.telemetryService.subscribed, isEmpty);
    });

    test("watches the telemetry once the internet comes back", () async {
      internet.connected = false;
      final bloc = await aBloc();

      await internet.tellConnection(isConnected: true);
      await pumpEventQueue();

      expect(bloc.state.genericError, TbTelemetriesUiError.noError);
      expect(client.telemetryService.timeSeries, isNotNull);
    });

    test("says that the device is unknown when the server answers none", () async {
      final bloc = TbTelemetriesUiBloc<FakeTbReqManager>(
        getDeviceInfo: () async => const (success: true, deviceInfo: null),
      );
      addTearDown(bloc.close);
      await pumpEventQueue();

      expect(bloc.state.genericError, TbTelemetriesUiError.unknownDevice);
      expect(bloc.state.canRetryRequest, isFalse);
    });

    test("says that the server failed when it could not be asked", () async {
      final bloc = await aBloc(serverFails: true);

      expect(bloc.state.genericError, TbTelemetriesUiError.serverError);
      expect(bloc.state.canRetryRequest, isTrue);
    });

    test("says that the server failed when the device carries no identifier", () async {
      final bloc = await aBloc(device: aDeviceWithoutId());

      expect(bloc.state.genericError, TbTelemetriesUiError.serverError);
    });

    test("says that the server failed when it refuses the subscription", () async {
      requestManager.answers.add(RequestStatus.globalError);

      final bloc = await aBloc();

      expect(bloc.state.genericError, TbTelemetriesUiError.serverError);
      expect(bloc.state.telemetryLoading, isFalse);
    });

    test("stops listening to the device when the page is closed", () async {
      final bloc = await aBloc();
      await pushTimeSeries({"temp": (42, "20.5")});

      await bloc.close();
      await pushTimeSeries({"temp": (43, "21.0")});

      expect(bloc.state.getTsValue<double>(FakeTelemetryKeys.temperature), 20.5);
    });
  });

  group("MixinTbTelemetriesUiBloc.getCallbackFromDeviceName", () {
    test("asks the server for the device which carries the name", () async {
      final callback = MixinTbTelemetriesUiBloc.getCallbackFromDeviceName<FakeTbReqManager>(
        deviceName: "a device",
      );

      requestManager.answers.add(RequestStatus.globalError);

      expect((await callback()).success, isFalse);
    });
  });
}
