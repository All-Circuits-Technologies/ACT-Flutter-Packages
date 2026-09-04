// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_aws_iot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The topic the watchers of the tests follow.
  const aTopic = "a/topic";

  late FakeGlobalManager globalManager;
  late FakeInternetManager internet;
  late FakeAuthManager auth;
  late FakeAwsIotConfigManager config;
  late FakeMqttService mqtt;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    internet = FakeInternetManager();
    auth = FakeAuthManager();
    await auth.initLifeCycle();

    config = await FakeAwsIotConfigManager.withContent(anAwsIotConf);
    globalGetIt()
      ..registerSingleton<InternetConnectivityManager>(internet)
      ..registerSingleton<FakeAuthManager>(auth)
      ..registerSingleton<FakeAwsIotConfigManager>(config);

    mqtt = FakeMqttService(iotManagerLogsHelper: aLogsHelper(), config: aMqttConfig());
  });

  tearDown(() async {
    await mqtt.disposeLifeCycle();
    FakeAssets.stop();
    await config.disposeLifeCycle();
    await auth.disposeLifeCycle();
    await internet.close();
    await globalManager.reset();
  });

  /// The watcher of the topic [topic], as the service of the subscriptions hands it out.
  ///
  /// It is asked of the service rather than built, so that what the server answers reaches it the
  /// way it does in an application.
  AwsIotMqttSubWatcher aWatcher({String topic = aTopic}) => mqtt.getSubscriptionWatcher(topic);

  /// Has [watcher] followed by one more reader of its topic.
  ///
  /// The messages and the events the reader is told about are added to [messages] and [events].
  Future<AwsIotMqttSubHandler> aReaderOf(
    AwsIotMqttSubWatcher watcher, {
    List<String>? messages,
    List<AwsIotMqttSubEvent>? events,
  }) async {
    final handler = watcher.getHandler(
      onMsgCb: (message) => messages?.add(message),
      onEventCb: events?.add,
    );
    await pumpAwsIot();

    return handler;
  }

  group("AwsIotMqttSubWatcher", () {
    test("subscribes to its topic as soon as a reader needs it", () async {
      final watcher = aWatcher();

      await aReaderOf(watcher);

      expect(mqtt.subscribed, [aTopic]);
      expect(await watcher.isSubscribed(), isTrue);
    });

    test("subscribes once however many readers need its topic", () async {
      final watcher = aWatcher();
      await aReaderOf(watcher);

      await aReaderOf(watcher);

      expect(mqtt.subscribed, [aTopic]);
    });

    test("says that it is not subscribed when the server takes no subscription", () async {
      mqtt.canSubscribe = false;
      final watcher = aWatcher();

      await aReaderOf(watcher);

      expect(mqtt.subscribed, isEmpty);
      expect(await watcher.isSubscribed(defaultValue: false), isFalse);
    });

    test("says that it is not subscribed while the server has not answered", () async {
      mqtt.answersSubscriptions = false;
      final watcher = aWatcher();

      await aReaderOf(watcher);

      expect(await watcher.isSubscribed(defaultValue: false), isFalse);
    });

    test("says that it is not subscribed when the server turned the subscription down", () async {
      mqtt.answersSubscriptions = false;
      final watcher = aWatcher();
      await aReaderOf(watcher);

      watcher.onSubEvent(AwsIotMqttSubEvent.subscriptionFailed);

      expect(await watcher.isSubscribed(), isFalse);
    });

    test("tells its readers the messages which are received on its topic", () async {
      final messages = <String>[];
      final watcher = aWatcher();
      await aReaderOf(watcher, messages: messages);

      watcher.onMsgCb("a message");
      await pumpAwsIot();

      expect(messages, ["a message"]);
    });

    test("tells every reader of its topic about the same message", () async {
      final first = <String>[];
      final second = <String>[];
      final watcher = aWatcher();
      await aReaderOf(watcher, messages: first);
      await aReaderOf(watcher, messages: second);

      watcher.onMsgCb("a message");
      await pumpAwsIot();

      expect(first, ["a message"]);
      expect(second, ["a message"]);
    });

    test("tells the readers which asked for it what became of the subscription", () async {
      final events = <AwsIotMqttSubEvent>[];
      final watcher = aWatcher();
      mqtt.answersSubscriptions = false;
      await aReaderOf(watcher, events: events);

      watcher.onSubEvent(AwsIotMqttSubEvent.subscribed);
      await pumpAwsIot();

      expect(events, [AwsIotMqttSubEvent.subscribed]);
    });

    test("unsubscribes from its topic once its last reader is gone", () async {
      final watcher = aWatcher();
      final handler = await aReaderOf(watcher);

      await handler.close();
      await pumpAwsIot();

      expect(mqtt.unsubscribed, [aTopic]);
      expect(await watcher.isUnsubscribed(), isTrue);
    });

    test("keeps its subscription while one of its readers is still there", () async {
      final watcher = aWatcher();
      final handler = await aReaderOf(watcher);
      await aReaderOf(watcher);

      await handler.close();
      await pumpAwsIot();

      expect(mqtt.unsubscribed, isEmpty);
    });

    test("tells nothing to a reader which is gone", () async {
      final messages = <String>[];
      final watcher = aWatcher();
      final handler = await aReaderOf(watcher, messages: messages);
      await aReaderOf(watcher);
      await handler.close();

      watcher.onMsgCb("a message");
      await pumpAwsIot();

      expect(messages, isEmpty);
    });

    test("subscribes again once the server is reached again", () async {
      final watcher = aWatcher();
      await aReaderOf(watcher);
      watcher.onDisconnected();

      await watcher.onConnected();

      expect(mqtt.subscribed, [aTopic, aTopic]);
    });

    test("subscribes to nothing when the server is reached and no reader needs it", () async {
      aWatcher();
      final watcher = aWatcher(topic: "another/topic");

      await watcher.onConnected();

      expect(mqtt.subscribed, isEmpty);
    });

    test("says that it is no longer subscribed once the server is lost", () async {
      final watcher = aWatcher();
      await aReaderOf(watcher);

      watcher.onDisconnected();

      expect(await watcher.isSubscribed(defaultValue: false), isFalse);
    });

    test("asks for a subscription the server turned down only once", () async {
      mqtt.answersSubscriptions = false;
      final watcher = aWatcher();
      await aReaderOf(watcher);
      watcher.onSubEvent(AwsIotMqttSubEvent.subscriptionFailed);

      await watcher.onConnected();

      expect(mqtt.subscribed, [aTopic]);
    });

    test("says that it is subscribed again once the server took a new subscription", () async {
      mqtt.answersSubscriptions = false;
      final watcher = aWatcher();
      await aReaderOf(watcher);
      watcher.onSubEvent(AwsIotMqttSubEvent.subscribed);
      watcher.onSubEvent(AwsIotMqttSubEvent.unsubscribed);

      expect(await watcher.isSubscribed(defaultValue: false), isFalse);

      watcher.onSubEvent(AwsIotMqttSubEvent.subscribed);

      expect(await watcher.isSubscribed(), isTrue);
    });

    test("stops telling the application about its topic once it is closed", () async {
      final watcher = AwsIotMqttSubWatcher(topic: aTopic, awsIotMqttService: mqtt);
      var closed = 0;
      watcher.onMsgStream.listen(null, onDone: () => closed++);
      watcher.onEventStream.listen(null, onDone: () => closed++);

      await watcher.close();
      await pumpAwsIot();

      expect(closed, 2);
    });
  });

  group("AwsIotMqttSubHandler", () {
    test("hears nothing of the events when it asked for nothing", () async {
      final watcher = aWatcher();
      mqtt.answersSubscriptions = false;
      final messages = <String>[];
      await aReaderOf(watcher, messages: messages);

      watcher.onSubEvent(AwsIotMqttSubEvent.subscribed);
      watcher.onMsgCb("a message");
      await pumpAwsIot();

      expect(messages, ["a message"]);
    });
  });
}
