// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_aws_iot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The topics the readers of the tests follow.
  const aTopic = "a/topic";
  const anotherTopic = "another/topic";

  late FakeGlobalManager globalManager;
  late FakeInternetManager internet;
  late FakeAuthManager auth;
  late FakeAwsIotConfigManager config;
  late FakeMqttService mqtt;
  late AwsIotMqttSubcriptionService service;

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
    service = AwsIotMqttSubcriptionService(
      mqttService: mqtt,
      iotManagerLogsHelper: aLogsHelper(),
    );
    await service.initLifeCycle();
  });

  tearDown(() async {
    await service.disposeLifeCycle();
    await mqtt.disposeLifeCycle();
    FakeAssets.stop();
    await config.disposeLifeCycle();
    await auth.disposeLifeCycle();
    await internet.close();
    await globalManager.reset();
  });

  /// Has the topic [topic] read by the application, and tells the messages it hears to [messages].
  Future<AwsIotMqttSubHandler> aReaderOf(String topic, {List<String>? messages}) async {
    final handler = service.getWatcher(topic).getHandler(
      onMsgCb: (message) => messages?.add(message),
    );
    await pumpAwsIot();

    return handler;
  }

  group("AwsIotMqttSubcriptionService.getWatcher", () {
    test("hands the same watcher over for a topic it already follows", () {
      expect(service.getWatcher(aTopic), same(service.getWatcher(aTopic)));
    });

    test("hands a watcher of its own over for each topic", () {
      expect(service.getWatcher(aTopic), isNot(same(service.getWatcher(anotherTopic))));
    });
  });

  group("AwsIotMqttSubcriptionService", () {
    test("tells the readers of a topic about a message which is received on it", () async {
      final messages = <String>[];
      await aReaderOf(aTopic, messages: messages);

      await mqtt.tellMessage(aTopic, "a message");

      expect(messages, ["a message"]);
    });

    test("tells nothing of a message which is received on another topic", () async {
      final messages = <String>[];
      await aReaderOf(aTopic, messages: messages);
      await aReaderOf(anotherTopic);

      await mqtt.tellMessage(anotherTopic, "a message");

      expect(messages, isEmpty);
    });

    test("says nothing of a message which is received on a topic nothing reads", () async {
      await mqtt.tellMessage("a/topic/nothing/reads", "a message");

      expect(mqtt.subscribed, isEmpty);
    });

    test("tells the watcher of a topic what became of its subscription", () async {
      mqtt.answersSubscriptions = false;
      final watcher = service.getWatcher(aTopic);
      await aReaderOf(aTopic);

      await mqtt.tellSubEvent(aTopic, AwsIotMqttSubEvent.subscribed);

      expect(await watcher.isSubscribed(), isTrue);
    });

    test("says nothing to the watcher of another topic", () async {
      mqtt.answersSubscriptions = false;
      final watcher = service.getWatcher(aTopic);
      await aReaderOf(aTopic);

      await mqtt.tellSubEvent(anotherTopic, AwsIotMqttSubEvent.subscribed);

      expect(await watcher.isSubscribed(defaultValue: false), isFalse);
    });

    test("subscribes again to the topics which are read once the server is reached", () async {
      await aReaderOf(aTopic);
      await aReaderOf(anotherTopic);
      await mqtt.tellConnection(isConnected: false);

      await mqtt.tellConnection(isConnected: true);

      expect(mqtt.subscribed, [aTopic, anotherTopic, aTopic, anotherTopic]);
    });

    test("subscribes to nothing of a topic no reader needs any more", () async {
      final handler = await aReaderOf(aTopic);
      await handler.close();
      await mqtt.tellConnection(isConnected: false);

      await mqtt.tellConnection(isConnected: true);

      expect(mqtt.subscribed, [aTopic]);
    });

    test("says that the topics are no longer subscribed once the server is lost", () async {
      final watcher = service.getWatcher(aTopic);
      await aReaderOf(aTopic);

      await mqtt.tellConnection(isConnected: false);

      expect(await watcher.isSubscribed(defaultValue: false), isFalse);
    });

    test("says that every topic which is read is subscribed", () async {
      await aReaderOf(aTopic);
      await aReaderOf(anotherTopic);

      expect(await service.isAllSubscribed(), isTrue);
    });

    test("says that a topic the server did not answer for is not subscribed", () async {
      await aReaderOf(aTopic);
      mqtt.answersSubscriptions = false;
      await aReaderOf(anotherTopic);

      expect(await service.isAllSubscribed(), isFalse);
    });

    test("says that everything is subscribed while it follows no topic", () async {
      expect(await service.isAllSubscribed(), isTrue);
    });

    test("stops telling the application about the topics it followed", () async {
      final watcher = service.getWatcher(aTopic);
      var closed = false;
      watcher.onMsgStream.listen(null, onDone: () => closed = true);

      await service.disposeLifeCycle();
      await pumpAwsIot();

      expect(closed, isTrue);
    });
  });
}
