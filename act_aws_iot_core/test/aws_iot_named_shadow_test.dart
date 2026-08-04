// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:convert';

import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_aws_iot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  /// The shadow of a device of the application, which asked the server for its state.
  Future<AwsIotNamedShadow> aShadow() async {
    final shadow = AwsIotNamedShadow(
      mqttService: mqtt,
      logsHelper: aLogsHelper(),
      thingName: aThingName,
      shadowName: FakeShadow.main.shadowName,
    );
    addTearDown(shadow.dispose);
    await shadow.init();
    await pumpAwsIot();

    return shadow;
  }

  /// Answers the request the shadow is waiting for on [topic] with [message].
  Future<void> theServerAnswers(ShadowTopicsEnum topic, String message) =>
      mqtt.tellMessage(aTopicName(topic), message);

  /// The shadow of a device whose state the server already answered.
  ///
  /// What was published on the way there is forgotten, so that a test only reads what it asked for
  /// itself.
  Future<AwsIotNamedShadow> aSyncedShadow({
    int version = 1,
    Map<String, dynamic>? desired,
    Map<String, dynamic>? reported,
  }) async {
    final shadow = await aShadow();
    await theServerAnswers(
      ShadowTopicsEnum.getAccepted,
      aShadowDoc(version: version, desired: desired, reported: reported),
    );
    mqtt.published.clear();

    return shadow;
  }

  /// The token the shadow asked for its last update with.
  String tokenOfLastUpdate() {
    final payload = mqtt.lastPublishedOn(aTopicName(ShadowTopicsEnum.update))!;

    return (jsonDecode(payload) as Map<String, dynamic>)["clientToken"] as String;
  }

  group("AwsIotNamedShadow.init", () {
    test("follows what the server answers about the shadow as soon as it is built", () async {
      await aShadow();

      expect(mqtt.subscribed, contains(aTopicName(ShadowTopicsEnum.updateAccepted)));
      expect(mqtt.subscribed, contains(aTopicName(ShadowTopicsEnum.getAccepted)));
      await theServerAnswers(ShadowTopicsEnum.getRejected, aRejectionDoc());
    });

    test("asks the server for the state of the shadow as soon as it is built", () async {
      await aShadow();

      expect(mqtt.lastPublishedOn(aTopicName(ShadowTopicsEnum.get)), "");
      await theServerAnswers(ShadowTopicsEnum.getRejected, aRejectionDoc());
    });

    test("knows nothing of the shadow before the server answers", () async {
      final shadow = await aShadow();

      expect(shadow.version, 0);
      expect(shadow.reportedState, isEmpty);
      expect(shadow.desiredState, isEmpty);
      await theServerAnswers(ShadowTopicsEnum.getRejected, aRejectionDoc());
    });
  });

  group("AwsIotNamedShadow.requestGet", () {
    test("reads the state the server answered", () async {
      final shadow = await aSyncedShadow(
        version: 4,
        desired: {"led": true},
        reported: {"led": false},
      );

      expect(shadow.version, 4);
      expect(shadow.desiredState, {"led": true});
      expect(shadow.reportedState, {"led": false});
    });

    test("answers that the request went through when the server accepted it", () async {
      final shadow = await aSyncedShadow();

      final request = shadow.requestGet();
      await pumpAwsIot();
      await theServerAnswers(ShadowTopicsEnum.getAccepted, aShadowDoc(version: 2));

      expect(await request, isTrue);
    });

    test("answers that the request failed when the server turned it down", () async {
      final shadow = await aSyncedShadow();

      final request = shadow.requestGet();
      await pumpAwsIot();
      await theServerAnswers(ShadowTopicsEnum.getRejected, aRejectionDoc());

      expect(await request, isFalse);
    });

    test("answers that the request failed when it cannot be published", () async {
      final shadow = await aSyncedShadow();
      mqtt.canPublish = false;

      expect(await shadow.requestGet(), isFalse);
    });

    test("keeps what it knows of a shadow whose answer it cannot read", () async {
      final shadow = await aSyncedShadow(version: 3, reported: {"led": true});

      await theServerAnswers(ShadowTopicsEnum.getAccepted, "not a document");

      expect(shadow.version, 3);
      expect(shadow.reportedState, {"led": true});
    });

    test("tells the application when the state the device reports changes", () async {
      final shadow = await aSyncedShadow();
      final reported = <Map<String, dynamic>>[];
      shadow.reportedStateStream.listen(reported.add);

      await theServerAnswers(
        ShadowTopicsEnum.getAccepted,
        aShadowDoc(version: 2, reported: {"led": true}),
      );

      expect(reported, [
        {"led": true},
      ]);
    });

    test("tells the application when the state which is asked of the device changes", () async {
      final shadow = await aSyncedShadow();
      final desired = <Map<String, dynamic>>[];
      shadow.desiredStateStream.listen(desired.add);

      await theServerAnswers(
        ShadowTopicsEnum.getAccepted,
        aShadowDoc(version: 2, desired: {"led": true}),
      );

      expect(desired, [
        {"led": true},
      ]);
    });

    test("says nothing to the application of a state which did not change", () async {
      final shadow = await aSyncedShadow(version: 2, reported: {"led": true});
      final reported = <Map<String, dynamic>>[];
      shadow.reportedStateStream.listen(reported.add);

      await theServerAnswers(
        ShadowTopicsEnum.getAccepted,
        aShadowDoc(version: 2, reported: {"led": true}),
      );

      expect(reported, isEmpty);
    });
  });

  group("AwsIotNamedShadow.requestUpdate", () {
    test("asks the server for the state the application wants, at the version it knows", () async {
      final shadow = await aSyncedShadow(version: 7);

      final request = shadow.requestUpdate({"led": true});
      await pumpAwsIot();
      final payload = mqtt.lastPublishedOn(aTopicName(ShadowTopicsEnum.update))!;
      await theServerAnswers(
        ShadowTopicsEnum.updateAccepted,
        aShadowDoc(version: 8, clientToken: tokenOfLastUpdate()),
      );
      await request;

      final asked = jsonDecode(payload) as Map<String, dynamic>;

      expect(asked["state"], {
        "desired": {"led": true},
      });
      expect(asked["version"], 7);
    });

    test("answers that the update went through when the server accepted it", () async {
      final shadow = await aSyncedShadow();

      final request = shadow.requestUpdate({"led": true});
      await pumpAwsIot();
      await theServerAnswers(
        ShadowTopicsEnum.updateAccepted,
        aShadowDoc(version: 2, clientToken: tokenOfLastUpdate()),
      );

      expect(await request, isTrue);
    });

    test("waits for the answer which carries the token of its own request", () async {
      final shadow = await aSyncedShadow();
      var answered = false;

      final request = shadow.requestUpdate({"led": true});
      unawaited(request.then((_) => answered = true));
      await pumpAwsIot();
      await theServerAnswers(
        ShadowTopicsEnum.updateAccepted,
        aShadowDoc(version: 2, clientToken: "the-token-of-another-application"),
      );

      expect(answered, isFalse);

      await theServerAnswers(
        ShadowTopicsEnum.updateAccepted,
        aShadowDoc(version: 3, clientToken: tokenOfLastUpdate()),
      );

      expect(await request, isTrue);
    });

    test("answers that the update failed when the server turned it down", () async {
      final shadow = await aSyncedShadow();

      final request = shadow.requestUpdate({"led": true});
      await pumpAwsIot();
      await theServerAnswers(ShadowTopicsEnum.updateRejected, aRejectionDoc(code: 409));

      expect(await request, isFalse);
    });

    test("asks the server for nothing when the state it is asked for is the one it asked "
        "for", () async {
      final shadow = await aSyncedShadow(version: 2, desired: {"led": true});

      expect(await shadow.requestUpdate({"led": true}), isFalse);
      expect(mqtt.published, isEmpty);
    });

    test("answers that the update failed when it cannot be published", () async {
      final shadow = await aSyncedShadow();
      mqtt.canPublish = false;

      expect(await shadow.requestUpdate({"led": true}), isFalse);
    });

    test("reads the state the server answers to an update", () async {
      final shadow = await aSyncedShadow();

      final request = shadow.requestUpdate({"led": true});
      await pumpAwsIot();
      await theServerAnswers(
        ShadowTopicsEnum.updateAccepted,
        aShadowDoc(version: 5, desired: {"led": true}, reported: {"led": true}),
      );
      await theServerAnswers(
        ShadowTopicsEnum.updateAccepted,
        aShadowDoc(version: 5, clientToken: tokenOfLastUpdate()),
      );
      await request;

      expect(shadow.version, 5);
      expect(shadow.reportedState, {"led": true});
    });
  });

  group("AwsIotNamedShadow.dispose", () {
    test("stops telling the application about the shadow", () async {
      final shadow = await aSyncedShadow();
      var closed = 0;
      shadow.reportedStateStream.listen(null, onDone: () => closed++);
      shadow.desiredStateStream.listen(null, onDone: () => closed++);

      await shadow.dispose();
      await pumpAwsIot();

      expect(closed, 2);
    });

    test("gives the topics of the shadow up", () async {
      final shadow = await aSyncedShadow();

      await shadow.dispose();
      await pumpAwsIot();

      expect(mqtt.unsubscribed, contains(aTopicName(ShadowTopicsEnum.updateAccepted)));
      expect(mqtt.unsubscribed, contains(aTopicName(ShadowTopicsEnum.getAccepted)));
    });
  });
}
