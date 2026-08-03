// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_consent.dart';

/// What the user agreed to, in the version [version].
ConsentDataModel<FakeOptions> _agreed({
  String? version = "v2",
  ConsentStateEnum mandatory = ConsentStateEnum.accepted,
  ConsentStateEnum optional = ConsentStateEnum.accepted,
}) => ConsentDataModel<FakeOptions>(
  version: version,
  options: ConsentOptionsModel<FakeOptions>(
    options: {FakeOptions.mandatory: mandatory, FakeOptions.optional: optional},
  ),
);

/// The options a page hands over when the user agrees.
ConsentOptionsModel<FakeOptions> _options({
  ConsentStateEnum mandatory = ConsentStateEnum.accepted,
  ConsentStateEnum optional = ConsentStateEnum.accepted,
}) => ConsentOptionsModel<FakeOptions>(
  options: {FakeOptions.mandatory: mandatory, FakeOptions.optional: optional},
);

void main() {
  late FakeExternalLogger logs;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
  });

  /// The service of a consent, which the test drives without a view.
  FakeConsentService aService({
    ConsentLoadStatus versionStatus = ConsentLoadStatus.success,
    String version = "v2",
    ConsentLoadStatus textStatus = ConsentLoadStatus.success,
    ConsentDataModel<FakeOptions>? userData,
    ConsentLoadStatus userDataStatus = ConsentLoadStatus.success,
    List<StreamObserver> observers = const [],
  }) {
    final service = FakeConsentService(
      logsHelper: logs.buildHelper(category: "consent"),
      versionStatus: versionStatus,
      version: version,
      textStatus: textStatus,
      userData: userData,
      userDataStatus: userDataStatus,
      observers: observers,
    );
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  group("AbstractConsentService.loadAllConsentInfo", () {
    test("does not know where the consent stands before it loaded anything", () {
      final service = aService();

      expect(service.consentState, ConsentStateEnum.unknown);
    });

    test("says that the consent is accepted when the user agreed to the version", () async {
      final service = aService(userData: _agreed());

      await service.loadAllConsentInfo();

      expect(service.consentState, ConsentStateEnum.accepted);
    });

    test("says that the consent is not accepted when the user agreed to an older one", () async {
      final service = aService(userData: _agreed(version: "v1"));

      await service.loadAllConsentInfo();

      expect(service.consentState, ConsentStateEnum.notAccepted);
    });

    test("says that the consent is not accepted when the user refused what he has to", () async {
      final service = aService(userData: _agreed(mandatory: ConsentStateEnum.notAccepted));

      await service.loadAllConsentInfo();

      expect(service.consentState, ConsentStateEnum.notAccepted);
    });

    test("says that the consent is accepted when the user only refused what is optional", () async {
      final service = aService(userData: _agreed(optional: ConsentStateEnum.notAccepted));

      await service.loadAllConsentInfo();

      expect(service.consentState, ConsentStateEnum.accepted);
    });

    test("tells the application where the consent stands", () async {
      final service = aService(userData: _agreed());

      final pushed = expectLater(service.stateStream, emits(ConsentStateEnum.accepted));
      await service.loadAllConsentInfo();

      await pushed;
    });

    test("starts a user who never agreed to anything from what is refused", () async {
      final service = aService();

      await service.loadAllConsentInfo();

      final options = await service.getConsentOptions();
      expect(options.getOptionState(FakeOptions.mandatory), ConsentStateEnum.notAccepted);
      expect(service.consentState, ConsentStateEnum.notAccepted);
    });

    test("loads the text of a consent the user has not agreed to", () async {
      final service = aService(userData: _agreed(version: "v1"));

      await service.loadAllConsentInfo();

      expect(service.askedTexts, ["v2"]);
      expect(service.textWidget, isNotNull);
    });

    test("loads nothing of a consent the user has already agreed to", () async {
      final service = aService(userData: _agreed());

      await service.loadAllConsentInfo();

      expect(service.askedTexts, isEmpty);
      expect(service.textWidget, isNull);
    });

    test("loads nothing more once it knows everything", () async {
      final service = aService(userData: _agreed());
      await service.loadAllConsentInfo();

      await service.loadAllConsentInfo();

      expect(service.latestVersionCalls, 1);
      expect(service.userDataCalls, 1);
    });

    test("gives up on a version the server will not answer", () async {
      final service = aService(versionStatus: ConsentLoadStatus.failed);

      await service.loadAllConsentInfo();

      expect(service.consentState, ConsentStateEnum.unknown);
    });

    test("gives up on what the user agreed to when it cannot be read at all", () async {
      final service = aService(userDataStatus: ConsentLoadStatus.failed);

      await service.loadAllConsentInfo();

      expect(service.consentState, ConsentStateEnum.unknown);
      expect(service.latestVersionCalls, 0);
    });

    test("waits before trying again when the version can be answered later", () async {
      final service = aService(versionStatus: ConsentLoadStatus.retryLater);

      await service.loadAllConsentInfo();

      expect(service.consentState, ConsentStateEnum.unknown);
      expect(service.userDataCalls, 1);
    });

    test("waits for the observers of the application to be ready", () async {
      final controller = StreamController<bool>.broadcast();
      addTearDown(controller.close);
      var isReady = false;
      final observer = FakeObserver(stream: controller.stream, get: () => isReady);
      final service = aService(userData: _agreed(), observers: [observer]);

      await service.loadAllConsentInfo();

      expect(service.userDataCalls, 0);

      isReady = true;
      controller.add(true);
      await pumpEventQueue();

      expect(service.userDataCalls, 1);
      expect(service.consentState, ConsentStateEnum.accepted);
    });

    test("loads what it needs when the observers are already ready", () async {
      final controller = StreamController<bool>.broadcast();
      addTearDown(controller.close);
      final observer = FakeObserver(stream: controller.stream, get: () => true);
      final service = aService(userData: _agreed(), observers: [observer]);

      await service.loadAllConsentInfo();

      expect(service.userDataCalls, 1);
    });
  });

  group("AbstractConsentService.getConsentTextWidget", () {
    test("builds the text of the consent from what the server answered", () async {
      final service = aService(userData: _agreed());
      await service.loadAllConsentInfo();

      final widget = await service.getConsentTextWidget();

      expect((widget! as Text).data, "the terms");
    });

    test("builds the text once and gives the same one back", () async {
      final service = aService(userData: _agreed());
      await service.loadAllConsentInfo();
      final widget = await service.getConsentTextWidget();

      expect(await service.getConsentTextWidget(), same(widget));
      expect(service.askedTexts, ["v2"]);
    });

    test("builds nothing before the version of the consent is known", () async {
      final service = aService();

      expect(await service.getConsentTextWidget(), isNull);
    });

    test("builds nothing when the text cannot be loaded", () async {
      final service = aService(
        userData: _agreed(),
        textStatus: ConsentLoadStatus.failed,
      );
      await service.loadAllConsentInfo();

      expect(await service.getConsentTextWidget(), isNull);
    });
  });

  group("AbstractConsentService.consent", () {
    test("keeps what the user agreed to, in the version of the server", () async {
      final service = aService(userData: _agreed(version: "v1"));
      await service.loadAllConsentInfo();

      expect(await service.consent(_options()), isTrue);
      expect(service.saved.single.version, "v2");
      expect(
        service.saved.single.options.getOptionState(FakeOptions.optional),
        ConsentStateEnum.accepted,
      );
      expect(service.consentState, ConsentStateEnum.accepted);
    });

    test("keeps the options the page said nothing about", () async {
      final service = aService(
        userData: _agreed(version: "v1", optional: ConsentStateEnum.notAccepted),
      );
      await service.loadAllConsentInfo();

      await service.consent(
        const ConsentOptionsModel<FakeOptions>(
          options: {FakeOptions.mandatory: ConsentStateEnum.accepted},
        ),
      );

      expect(
        service.saved.single.options.getOptionState(FakeOptions.optional),
        ConsentStateEnum.notAccepted,
      );
    });

    test("saves nothing when the user agreed to what he had already agreed to", () async {
      final service = aService(userData: _agreed());
      await service.loadAllConsentInfo();

      expect(await service.consent(_agreed().options), isTrue);
      expect(service.saved, isEmpty);
    });

    test("refuses to keep anything before it knows where the consent stands", () async {
      final service = aService();

      expect(await service.consent(_options()), isFalse);
      expect(service.saved, isEmpty);
    });

    test("says that it failed when what the user agreed to cannot be saved", () async {
      final service = aService(userData: _agreed(version: "v1"));
      await service.loadAllConsentInfo();
      service.saveAnswer = false;

      expect(await service.consent(_options()), isFalse);
      expect(service.consentState, ConsentStateEnum.notAccepted);
    });
  });

  group("AbstractConsentService.resetLocalConsentInfo", () {
    test("reads the version and the text of the consent again", () async {
      final service = aService(userData: _agreed(version: "v1"));
      await service.loadAllConsentInfo();

      await service.resetLocalConsentInfo();

      expect(service.latestVersionCalls, 2);
      expect(service.askedTexts, ["v2", "v2"]);
    });

    test("keeps what the user agreed to", () async {
      final service = aService(userData: _agreed());
      await service.loadAllConsentInfo();

      await service.resetLocalConsentInfo();

      expect(service.userDataCalls, 1);
      expect(service.consentState, ConsentStateEnum.accepted);
    });
  });
}
