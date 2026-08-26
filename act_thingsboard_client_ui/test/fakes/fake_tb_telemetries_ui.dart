// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// The identifier of the device the tests watch the telemetry of.
const aDeviceId = "a-device";

/// The telemetry keys an application under test asks for.
enum FakeTelemetryKeys with MixinTelemetriesKeys {
  /// The first key of the application.
  temperature("temp"),

  /// The second key of the application.
  humidity("hum");

  /// The key the server knows this telemetry element under.
  @override
  final String tbKey;

  /// Enum constructor
  const FakeTelemetryKeys(this.tbKey);
}

/// The internet of the device, answered by the test.
class FakeInternetManager extends InternetConnectivityManager {
  /// The stream the internet of the device is told over.
  final StreamController<bool> _ctrl = StreamController<bool>.broadcast();

  /// Whether the device is connected.
  bool connected;

  /// Class constructor
  FakeInternetManager({this.connected = true}) : super(configGetter: _confIsNeverRead);

  /// {@macro act_internet_connectivity_manager.InternetConnectivityManager.hasConnection}
  @override
  bool get hasConnection => connected;

  /// {@macro act_internet_connectivity_manager.InternetConnectivityManager.hasInternetStream}
  @override
  Stream<bool> get hasInternetStream => _ctrl.stream;

  /// Tells the application that the device is now connected, or no longer is.
  Future<void> tellConnection({required bool isConnected}) async {
    connected = isConnected;
    _ctrl.add(isConnected);

    return Future.delayed(Duration.zero);
  }

  /// Stops telling the application about the internet of the device.
  Future<void> close() => _ctrl.close();

  /// The configuration a manager which is never initialized never reads.
  static MixinInternetTestConfig _confIsNeverRead() =>
      throw StateError("The internet of the test is answered, so no server is ever tested");
}

/// The websocket a device pushes its telemetry over, answered by the test.
class FakeTelemetryService implements TelemetryService {
  /// The subscribers which were handed over, in the order they were.
  final List<TelemetrySubscriber> subscribed = [];

  /// The subscribers which were given up, in the order they were.
  final List<TelemetrySubscriber> unsubscribed = [];

  /// The subscriber which is currently listening the attributes of [scope], if there is one.
  TelemetrySubscriber? attributesOf(AttributeScope scope) => _lastListening(
    (command) => command is AttributesSubscriptionCmd && command.scope == scope,
  );

  /// The subscriber which is currently listening the time series, if there is one.
  TelemetrySubscriber? get timeSeries =>
      _lastListening((command) => command is TimeseriesSubscriptionCmd);

  /// The last subscriber which is still listening and whose command answers [test].
  TelemetrySubscriber? _lastListening(bool Function(WebsocketCmd command) test) {
    for (final subscriber in subscribed.reversed) {
      if (!unsubscribed.contains(subscriber) && test(subscriber.subscriptionCommands.single)) {
        return subscriber;
      }
    }

    return null;
  }

  @override
  void subscribe(TelemetrySubscriber subscriber) => subscribed.add(subscriber);

  @override
  void update(TelemetrySubscriber subscriber) {}

  @override
  void unsubscribe(TelemetrySubscriber subscriber) => unsubscribed.add(subscriber);

  @override
  void reset(bool close) {}
}

/// The client of the server, which answers what the test decided.
class FakeTbClient extends Mock implements ThingsboardClient {
  /// The websocket the telemetry of the devices is pushed over.
  final FakeTelemetryService telemetryService = FakeTelemetryService();

  /// Class constructor
  FakeTbClient() {
    when(getTelemetryService).thenReturn(telemetryService);
  }
}

/// The manager which reaches the server without a user, standing in for the real one.
class FakeNoAuthReqManager extends TbNoAuthServerReqManager {
  /// The client the requests are handed.
  final FakeTbClient client;

  /// Class constructor
  FakeNoAuthReqManager(this.client)
    : super(storageServiceGetter: null, confGetter: _confIsNeverRead);

  /// The client every request of the package is handed.
  @override
  ThingsboardClient get tbClient => client;

  @override
  Future<TbRequestResponse<T>> request<T>(TbRequestToCall<T> requestToCall) async =>
      TbRequestResponse<T>(
        status: RequestStatus.success,
        requestResponse: await requestToCall(client),
      );

  /// The configuration a manager which is never initialized never reads.
  static MixinThingsboardConf _confIsNeverRead() =>
      throw StateError("The client of the test is handed over, so no server is ever named");
}

/// The manager of the requests to the server of an application under test.
///
/// It is a real manager over the client of the test: the service of the devices and the handlers of
/// the telemetry it hands out are the real ones.
class FakeTbReqManager extends AbsTbServerReqManager {
  /// The statuses the manager answers, one per request, in the order they are answered.
  ///
  /// Once the list is empty, every request is let through.
  final List<RequestStatus> answers = [];

  /// Class constructor
  FakeTbReqManager() : super(logCategory: "fake");

  /// {@macro act_thingsboard_client.AbsTbServerReqManager.request}
  @override
  Future<TbRequestResponse<T>> request<T>(TbRequestToCall<T> requestToCall) async {
    final answer = answers.isEmpty ? RequestStatus.success : answers.removeAt(0);
    if (!answer.isOk) {
      return TbRequestResponse<T>(status: answer);
    }

    return TbRequestResponse<T>(status: answer, requestResponse: await requestToCall(tbClient));
  }
}

/// An update of the telemetry of a device, as the websocket of the server sends it.
SubscriptionUpdate anUpdate(Map<String, (int, String?)> values) =>
    SubscriptionUpdate.fromJson({
      "subscriptionId": 1,
      "errorCode": 0,
      "data": values.map((key, value) => MapEntry(key, [
        [value.$1, value.$2],
      ])),
    });

/// A device of a customer, as the server answers it.
DeviceInfo aDeviceInfo({String id = aDeviceId, String name = "a device"}) =>
    DeviceInfo.fromJson({
      "id": {"entityType": "DEVICE", "id": id},
      "createdTime": 0,
      "tenantId": {"entityType": "TENANT", "id": "a-tenant"},
      "name": name,
      "type": "a-type",
      "deviceProfileId": {"entityType": "DEVICE_PROFILE", "id": "a-profile"},
      "deviceData": {
        "configuration": {"type": "DEFAULT"},
        "transportConfiguration": {"type": "DEFAULT"},
      },
    });

/// A device of a customer whose identifier the server did not answer.
DeviceInfo aDeviceWithoutId() => DeviceInfo.fromJson({
  "createdTime": 0,
  "tenantId": {"entityType": "TENANT", "id": "a-tenant"},
  "name": "a device",
  "type": "a-type",
  "deviceProfileId": {"entityType": "DEVICE_PROFILE", "id": "a-profile"},
  "deviceData": {
    "configuration": {"type": "DEFAULT"},
    "transportConfiguration": {"type": "DEFAULT"},
  },
});
