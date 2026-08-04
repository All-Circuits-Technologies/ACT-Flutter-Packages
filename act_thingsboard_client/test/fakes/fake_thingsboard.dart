// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:convert';

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// The asset key of the configuration file the tests serve.
const configKey = "assets/config/default.yaml";

/// The identifier of the device the tests watch the telemetry of.
const aDeviceId = "a-device";

/// The configuration of an application which reaches a server of its own.
const aServerConf = """
thingsboard:
  host: a.server
  port: 8080
""";

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

/// The configuration which names the server of an application under test.
class FakeTbConfigManager extends AbstractConfigManager with MixinThingsboardConf {
  /// Class constructor
  FakeTbConfigManager() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeTbConfigManager> withContent(String content) async {
    FakeAssets.serve({configKey: content});

    final manager = FakeTbConfigManager();
    await manager.initLifeCycle();

    return manager;
  }
}

/// The storage of the tokens of a user, kept in memory.
class FakeTbAuthStorageService with MixinAuthStorageService {
  /// Whether the storage says it can keep the identifiers of the user.
  final bool userIdsSupported;

  /// The tokens the storage keeps.
  AuthTokens? storedTokens;

  /// The identifiers of the user the storage keeps.
  ({String username, String password})? storedUserIds;

  /// The calls the storage received, in the order it received them.
  final List<String> calls = [];

  /// Class constructor
  FakeTbAuthStorageService({this.userIdsSupported = true, this.storedTokens, this.storedUserIds});

  /// {@macro act_shared_auth.MixinAuthStorageService.isUserIdsStorageSupported}
  @override
  Future<bool> isUserIdsStorageSupported() async => userIdsSupported;

  /// {@macro act_shared_auth.MixinAuthStorageService.storeTokens}
  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    calls.add("storeTokens()");
    storedTokens = tokens;

    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadTokens}
  @override
  Future<AuthTokens?> loadTokens() async {
    calls.add("loadTokens()");

    return storedTokens;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.clearTokens}
  @override
  Future<void> clearTokens() async {
    calls.add("clearTokens()");
    storedTokens = null;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.storeUserIds}
  @override
  Future<bool> storeUserIds({required String username, required String password}) async {
    calls.add("storeUserIds($username)");
    storedUserIds = (username: username, password: password);

    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadUserIds}
  @override
  Future<({String username, String password})?> loadUserIds() async {
    calls.add("loadUserIds()");

    return storedUserIds;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.clearUserIds}
  @override
  Future<void> clearUserIds() async {
    calls.add("clearUserIds()");
    storedUserIds = null;
  }
}

/// The websocket a device pushes its telemetry over, answered by the test.
///
/// It records the subscribers the package handed it, which is what a test reads to know which keys
/// were subscribed and which subscription was given up.
class FakeTelemetryService implements TelemetryService {
  /// The subscribers which were handed over, in the order they were.
  final List<TelemetrySubscriber> subscribed = [];

  /// The subscribers which were given up, in the order they were.
  final List<TelemetrySubscriber> unsubscribed = [];

  /// The subscribers which are still listening, in the order they were handed over.
  List<TelemetrySubscriber> get live =>
      subscribed.where((subscriber) => !unsubscribed.contains(subscriber)).toList();

  /// The subscriber which is currently listening, if there is one.
  TelemetrySubscriber? get current => live.lastOrNull;

  /// The keys of the subscription which is currently listening.
  ///
  /// The list is empty when nothing is listening.
  List<String> get currentKeys => keysOf(current);

  /// The subscriber which is currently listening the attributes of [scope], if there is one.
  TelemetrySubscriber? attributesOf(AttributeScope scope) => _lastListening(
    (command) => command is AttributesSubscriptionCmd && command.scope == scope,
  );

  /// The subscriber which is currently listening the time series, if there is one.
  TelemetrySubscriber? get timeSeries =>
      _lastListening((command) => command is TimeseriesSubscriptionCmd);

  /// The keys [subscriber] asked the server for.
  ///
  /// The list is empty when there is no such subscriber.
  List<String> keysOf(TelemetrySubscriber? subscriber) {
    final command = subscriber?.subscriptionCommands.single;

    return switch (command) {
      final TelemetryPluginCmd command => command.keys?.split(",") ?? [],
      _ => [],
    };
  }

  /// The last subscriber which is still listening and whose command answers [test].
  TelemetrySubscriber? _lastListening(bool Function(WebsocketCmd command) test) {
    for (final subscriber in live.reversed) {
      if (test(subscriber.subscriptionCommands.single)) {
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
///
/// Only the methods a test lines up an answer for are answered; any other one raises, which is what
/// tells a test that the package reached the server in a way it did not expect.
class FakeTbClient extends Mock implements ThingsboardClient {
  /// The websocket the telemetry of the devices is pushed over.
  final FakeTelemetryService telemetryService = FakeTelemetryService();

  /// Class constructor
  FakeTbClient() {
    when(getTelemetryService).thenReturn(telemetryService);
  }
}

/// The service of the devices of the server, which answers what the test decided.
class FakeDeviceService extends Mock implements DeviceService {}

/// A manager of the requests to the server which answers what the test decided.
///
/// A real manager builds its client from the configuration of the application and reaches the
/// server through it. This one hands the client of the test over to every request, and answers the
/// statuses the test lined up in [answers] without reaching anything: a status which is not
/// [RequestStatus.success] means the request never happened, which is what the server answering
/// with an error looks like from the inside of the package.
class FakeTbRequestManager extends AbsTbServerReqManager {
  /// The client the requests are handed.
  final FakeTbClient client;

  /// The statuses the manager answers, one per request, in the order they are answered.
  ///
  /// Once the list is empty, every request is let through.
  final List<RequestStatus> answers = [];

  /// The number of requests the manager received.
  int requestCount = 0;

  /// Class constructor
  FakeTbRequestManager({FakeTbClient? client})
    : client = client ?? FakeTbClient(),
      super(logCategory: "fake");

  /// The client every request of the package is handed.
  @override
  ThingsboardClient get tbClient => client;

  /// {@macro act_thingsboard_client.AbsTbServerReqManager.request}
  @override
  Future<TbRequestResponse<T>> request<T>(TbRequestToCall<T> requestToCall) async {
    requestCount++;

    final answer = answers.isEmpty ? RequestStatus.success : answers.removeAt(0);
    if (!answer.isOk) {
      return TbRequestResponse<T>(status: answer);
    }

    return TbRequestResponse<T>(status: answer, requestResponse: await requestToCall(client));
  }
}

/// An authentication which answers the tokens the test decided.
class FakeTokensAuthService with MixinAuthService {
  /// The stream the service tells the application about its status through.
  final StreamController<AuthStatus> _statusCtrl = StreamController<AuthStatus>.broadcast();

  /// The tokens the service answers, if it has any.
  AuthTokens? tokens;

  /// The number of times the tokens were asked for.
  int tokensCalls = 0;

  /// Class constructor
  FakeTokensAuthService({this.tokens});

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus => tokens == null ? AuthStatus.signedOut : AuthStatus.signedIn;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _statusCtrl.stream;

  /// {@macro act_shared_auth.MixinAuthService.getTokens}
  @override
  Future<AuthTokens?> getTokens() async {
    tokensCalls++;

    return tokens;
  }

  /// {@macro act_shared_auth.MixinAuthService.setStorageService}
  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async {}

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) async =>
      const AuthSignInResult(status: AuthSignInStatus.done);

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() async => true;

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() async => tokens != null;

  /// Stops telling the application about the status of the user.
  Future<void> close() => _statusCtrl.close();
}

/// The authentication of an application under test.
class FakeTbAuthManager extends AbsAuthManager {
  /// The authentication the manager hands over.
  final FakeTokensAuthService service;

  /// Class constructor
  FakeTbAuthManager({FakeTokensAuthService? service})
    : service = service ?? FakeTokensAuthService();

  /// {@macro act_shared_auth.AbsAuthManager.getAuthService}
  @override
  Future<MixinAuthService> getAuthService() async => service;
}

/// The manager which reaches the server without a user, standing in for the real one.
///
/// A real manager builds its client from the configuration of the application; this one hands the
/// client of the test over to every request, and answers the statuses the test lined up in
/// [answers] the same way [FakeTbRequestManager] does.
class FakeNoAuthReqManager extends TbNoAuthServerReqManager {
  /// The client the requests are handed.
  final FakeTbClient client;

  /// The statuses the manager answers, one per request, in the order they are answered.
  ///
  /// Once the list is empty, every request is let through.
  final List<RequestStatus> answers = [];

  /// The number of requests the manager received.
  int requestCount = 0;

  /// Class constructor
  FakeNoAuthReqManager({FakeTbClient? client})
    : client = client ?? FakeTbClient(),
      super(storageServiceGetter: null, confGetter: _confIsNeverRead);

  /// The client every request of the package is handed.
  @override
  ThingsboardClient get tbClient => client;

  @override
  Future<TbRequestResponse<T>> request<T>(TbRequestToCall<T> requestToCall) async {
    requestCount++;

    final answer = answers.isEmpty ? RequestStatus.success : answers.removeAt(0);
    if (!answer.isOk) {
      return TbRequestResponse<T>(status: answer);
    }

    return TbRequestResponse<T>(status: answer, requestResponse: await requestToCall(client));
  }

  /// The configuration a manager which is never initialized never reads.
  static MixinThingsboardConf _confIsNeverRead() =>
      throw StateError("The client of the test is handed over, so no server is ever named");
}

/// An update of the telemetry of a device, as the websocket of the server sends it.
///
/// Every entry of [values] is a key of the telemetry and the timestamp and value which were
/// received for it.
SubscriptionUpdate anUpdate(Map<String, (int, String?)> values, {int errorCode = 0}) =>
    SubscriptionUpdate.fromJson({
      "subscriptionId": 1,
      "errorCode": errorCode,
      "data": values.map((key, value) => MapEntry(key, [
        [value.$1, value.$2],
      ])),
    });

/// An attribute of a device, as the server answers it.
AttributeData anAttribute({required String key, required int ts, String? value}) =>
    AttributeData(key: key, lastUpdateTs: ts, value: value);

/// The user the server says is signed in, linked to the customer [customerId].
AuthUser aCustomerUser({String? customerId = "a-customer"}) => AuthUser.fromJson({
  "sub": "a-user",
  "scopes": ["CUSTOMER_USER"],
  "userId": "a-user-id",
  "tenantId": "a-tenant",
  "customerId": customerId,
});

/// A device of a customer, as the server answers it.
DeviceInfo aDeviceInfo(String name) => DeviceInfo.fromJson({
  "id": {"entityType": "DEVICE", "id": name},
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

/// A page of devices the server answers, which is the last one unless [hasNext] says otherwise.
PageData<T> aPage<T>(List<T> devices, {bool hasNext = false}) =>
    PageData<T>(devices, 1, devices.length, hasNext);

/// A JWT which expires [validFor] from now, and which no server signed.
///
/// The package only ever reads the claims of a token, so a token which is not signed is enough for
/// a test; a token which expires in the past is what an expired token looks like.
String aJwtToken({Duration validFor = const Duration(hours: 1), String subject = "a-user"}) {
  final expiration = DateTime.now().toUtc().add(validFor).millisecondsSinceEpoch ~/ 1000;

  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll("=", "");

  final header = encode({"alg": "HS256", "typ": "JWT"});
  final payload = encode({
    "sub": subject,
    "exp": expiration,
    "scopes": ["CUSTOMER_USER"],
    "userId": "a-user-id",
    "tenantId": "a-tenant",
    "customerId": "a-customer",
  });

  return "$header.$payload.a-signature";
}
