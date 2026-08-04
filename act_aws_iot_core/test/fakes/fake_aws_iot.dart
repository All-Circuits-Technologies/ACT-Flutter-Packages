// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:convert';

import 'package:act_amplify_cognito/act_amplify_cognito.dart';
import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The asset key of the configuration file the tests serve.
const configKey = "assets/config/default.yaml";

/// The configuration of an application which says where its AWS IoT server is.
const anAwsIotConf = "aws:\n  iot:\n    endpoint: an-endpoint.example.com\n    region: eu-west-1";

/// The name of the device the tests follow the shadows of.
const aThingName = "a-thing";

/// The shadows an application under test follows for each of its devices.
enum FakeShadow with MixinAwsIotShadowEnum {
  /// The first shadow of the application.
  main("main"),

  /// The second shadow of the application.
  spare("spare");

  /// The name the server knows this shadow under.
  @override
  final String shadowName;

  /// Enum constructor
  const FakeShadow(this.shadowName);
}

/// The configuration which says where the AWS IoT server of an application under test is.
class FakeAwsIotConfigManager extends AbstractConfigManager with MixinAwsIotConf {
  /// Class constructor
  FakeAwsIotConfigManager() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  static Future<FakeAwsIotConfigManager> withContent(String content) async {
    FakeAssets.serve({configKey: content});

    final manager = FakeAwsIotConfigManager();
    await manager.initLifeCycle();

    return manager;
  }
}

/// The internet of the device, answered by the test.
class FakeInternetManager extends InternetConnectivityManager {
  final StreamController<bool> _ctrl = StreamController<bool>.broadcast();

  /// Whether the device is connected.
  bool connected;

  /// Class constructor
  FakeInternetManager({this.connected = false}) : super(configGetter: _confIsNeverRead);

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

/// The authentication of an application under test.
class FakeAuthService with MixinAuthService {
  final StreamController<AuthStatus> _ctrl = StreamController<AuthStatus>.broadcast();

  /// The status the application is in.
  AuthStatus _status;

  /// Class constructor
  FakeAuthService({AuthStatus status = AuthStatus.signedOut}) : _status = status;

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus => _status;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _ctrl.stream;

  /// Tells the application that the user is now signed in, or is no longer.
  Future<void> tellStatus(AuthStatus status) async {
    _status = status;
    _ctrl.add(status);

    return Future.delayed(Duration.zero);
  }

  /// Stops telling the application about the user.
  Future<void> close() => _ctrl.close();

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) =>
      throw StateError("The tests say who is signed in, so nobody ever signs in");

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() =>
      throw StateError("The tests say who is signed in, so nobody ever signs out");

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() async => _status == AuthStatus.signedIn;
}

/// The manager of the authentication of an application under test.
class FakeAuthManager extends AbsAuthManager {
  /// The authentication the test answers.
  final FakeAuthService service = FakeAuthService();

  @override
  Future<MixinAuthService> getAuthService() async => service;

  @override
  Future<void> disposeLifeCycle() async {
    await service.close();

    return super.disposeLifeCycle();
  }
}

/// The manager of Amplify of an application under test.
///
/// Nothing of Amplify is reached by the tests: the manager is only there because the services name
/// its type.
class FakeAmplifyManager extends AbsAmplifyManager {
  @override
  Future<AmplifyManagerConfig> getAmplifyConfig() async =>
      throw StateError("The tests reach no server, so Amplify is never configured");
}

/// The MQTT server of an application under test.
///
/// It is a real service whose reaching of the server is answered by the test: the subscriptions, the
/// messages and the publications never leave the test, and the connection is the one the test says
/// it is.
class FakeMqttService extends AwsIotMqttService<FakeAuthManager, FakeAmplifyManager> {
  final StreamController<bool> _connection = StreamController<bool>.broadcast();

  final StreamController<({String topic, AwsIotMqttSubEvent evt})> _subEvents =
      StreamController<({String topic, AwsIotMqttSubEvent evt})>.broadcast();

  final StreamController<({String topic, String msg})> _messages =
      StreamController<({String topic, String msg})>.broadcast();

  /// The topics the server was asked to subscribe to, in the order they were asked for.
  final List<String> subscribed = [];

  /// The topics the server was asked to unsubscribe from, in the order they were asked for.
  final List<String> unsubscribed = [];

  /// The messages which were published, in the order they were.
  final List<({String topic, String payload})> published = [];

  /// Whether the server answers the subscriptions and the unsubscriptions by itself.
  ///
  /// When false, the test says when a subscription is answered with [tellSubEvent].
  bool answersSubscriptions;

  /// Whether the server takes a subscription at all.
  bool canSubscribe;

  /// Whether the server takes an unsubscription at all.
  bool canUnsubscribe;

  /// Whether the server takes a publication at all.
  bool canPublish;

  /// Class constructor
  FakeMqttService({
    required super.iotManagerLogsHelper,
    required super.config,
    this.answersSubscriptions = true,
    this.canSubscribe = true,
    this.canUnsubscribe = true,
    this.canPublish = true,
    super.extraStreamObservers,
    super.autoReconnect,
  });

  /// Whether the server is reached, as the test says it.
  @override
  Stream<bool> get connectionStatusStream => _connection.stream;

  /// What became of the subscriptions, as the test says it.
  @override
  Stream<({String topic, AwsIotMqttSubEvent evt})> get onSubEventStream => _subEvents.stream;

  /// The messages the server sends, as the test says them.
  @override
  Stream<({String topic, String msg})> get onMessageReceivedStream => _messages.stream;

  @override
  bool subscribe(String topic) {
    if (!canSubscribe) {
      return false;
    }

    subscribed.add(topic);
    if (answersSubscriptions) {
      _subEvents.add((topic: topic, evt: AwsIotMqttSubEvent.subscribed));
    }

    return true;
  }

  @override
  bool unsubscribe(String topic) {
    if (!canUnsubscribe) {
      return false;
    }

    unsubscribed.add(topic);
    if (answersSubscriptions) {
      _subEvents.add((topic: topic, evt: AwsIotMqttSubEvent.unsubscribed));
    }

    return true;
  }

  @override
  Future<bool> publish(String topic, String payload) async {
    if (!canPublish) {
      return false;
    }

    published.add((topic: topic, payload: payload));

    return true;
  }

  /// Tells the application that the server is now reached, or is no longer.
  Future<void> tellConnection({required bool isConnected}) async {
    _connection.add(isConnected);

    return pumpAwsIot();
  }

  /// Tells the application what became of the subscription to [topic].
  Future<void> tellSubEvent(String topic, AwsIotMqttSubEvent event) async {
    _subEvents.add((topic: topic, evt: event));

    return pumpAwsIot();
  }

  /// Tells the application that [message] was received on [topic].
  Future<void> tellMessage(String topic, String message) async {
    _messages.add((topic: topic, msg: message));

    return pumpAwsIot();
  }

  /// The payload which was last published on [topic], or null when nothing was.
  String? lastPublishedOn(String topic) {
    for (final message in published.reversed) {
      if (message.topic == topic) {
        return message.payload;
      }
    }

    return null;
  }

  @override
  Future<void> disposeLifeCycle() async {
    await super.disposeLifeCycle();

    await Future.wait([
      _connection.close(),
      _subEvents.close(),
      _messages.close(),
    ]);
  }
}

/// Lets the streams of the package carry what was just told on them.
Future<void> pumpAwsIot() => Future.delayed(Duration.zero);

/// The configuration of the MQTT server the tests reach.
///
/// The service of Cognito is never reached: signing a URL and asking for a session both only happen
/// on the way to a real server.
AwsIotMqttConfigModel aMqttConfig({
  Duration? signerValidityDuration,
  int? mqttPort,
}) =>
    AwsIotMqttConfigModel.get<FakeAwsIotConfigManager>(
      cognitoService: AmplifyCognitoService(),
      signerValidityDuration: signerValidityDuration,
      mqttPort: mqttPort,
    )!;

/// The name of the topic [topic] of the shadow [shadow] of the device [thingName].
String aTopicName(
  ShadowTopicsEnum topic, {
  FakeShadow shadow = FakeShadow.main,
  String thingName = aThingName,
}) =>
    topic.buildTopicName(thingName, shadow.shadowName);

/// A shadow document, as the server answers it to an accepted get or update.
String aShadowDoc({
  int version = 1,
  Map<String, dynamic>? desired,
  Map<String, dynamic>? reported,
  String? clientToken,
}) =>
    jsonEncode({
      "state": {
        "desired": desired ?? <String, dynamic>{},
        "reported": reported ?? <String, dynamic>{},
      },
      "version": version,
      "timestamp": 1,
      "clientToken": ?clientToken,
    });

/// The document the server answers to a request it turned down.
String aRejectionDoc({int code = 404, String message = "the shadow does not exist"}) =>
    jsonEncode({
      "code": code,
      "message": message,
      "timestamp": 1,
    });

/// The logs helper the services of the tests write to.
LogsHelper aLogsHelper() => LogsHelper(category: "test");
