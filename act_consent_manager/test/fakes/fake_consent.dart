// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/widgets.dart';

/// The consents an application under test asks its users for.
enum FakeConsentType {
  /// The terms the user has to agree to.
  terms,

  /// The consent the user may agree to.
  analytics,
}

/// What a user agrees to in the consent of an application under test.
enum FakeOptions with MixinConsentOptions {
  /// What the user has to agree to.
  mandatory(isOptional: false),

  /// What the user may agree to or not.
  optional(isOptional: true);

  /// {@macro act_consent_manager.MixinConsentOptions.isOptional}
  @override
  final bool isOptional;

  /// Enum constructor
  const FakeOptions({required this.isOptional});
}

/// Something the service waits for before it loads anything.
///
/// A real observer watches the user being signed in, or the device being online. This one is turned
/// on and off by the test.
class FakeObserver extends StreamObserver<bool> {
  /// Class constructor
  FakeObserver({required super.stream, required super.get});

  /// {@macro StreamObserver.isNewValueValid}
  @override
  bool isNewValueValid(bool value) => value;
}

/// The service of one consent of an application under test.
///
/// It answers what the test lined up, and records the calls it received, which is what a test reads
/// to know what the service went and loaded.
class FakeConsentService extends AbstractConsentService<FakeOptions> {
  /// The version the server answers, and the status of that answer.
  ResultWithRequiredValue<ConsentLoadStatus, String> latestVersionAnswer;

  /// The text the server answers, and the status of that answer.
  ResultWithRequiredValue<ConsentLoadStatus, String> textAnswer;

  /// What the user already agreed to, and the status of that answer.
  ResultWithStatus<ConsentLoadStatus, ConsentDataModel<FakeOptions>> userDataAnswer;

  /// Whether what the user agrees to can be saved.
  bool saveAnswer = true;

  /// The versions the text of the consent was asked for, in the order they were asked.
  final List<String> askedTexts = [];

  /// What the service was asked to save, in the order it was asked.
  final List<ConsentDataModel<FakeOptions>> saved = [];

  /// The number of times the version the server holds was asked for.
  int latestVersionCalls = 0;

  /// The number of times what the user agreed to was read.
  int userDataCalls = 0;

  /// Class constructor
  FakeConsentService({
    required super.logsHelper,
    super.optionsList = FakeOptions.values,
    super.observers = const [],
    ConsentLoadStatus versionStatus = ConsentLoadStatus.success,
    String version = "v2",
    ConsentLoadStatus textStatus = ConsentLoadStatus.success,
    String text = "the terms",
    ConsentDataModel<FakeOptions>? userData,
    ConsentLoadStatus userDataStatus = ConsentLoadStatus.success,
  }) : latestVersionAnswer = ResultWithRequiredValue(status: versionStatus, value: version),
       textAnswer = ResultWithRequiredValue(status: textStatus, value: text),
       userDataAnswer = ResultWithStatus(status: userDataStatus, value: userData);

  /// {@macro act_consent_manager.AbstractConsentService.loadLatestVersion}
  @override
  Future<ResultWithRequiredValue<ConsentLoadStatus, String>> loadLatestVersion() async {
    latestVersionCalls++;

    return latestVersionAnswer;
  }

  /// {@macro act_consent_manager.AbstractConsentService.loadConsentText}
  @override
  Future<ResultWithRequiredValue<ConsentLoadStatus, String>> loadConsentText(
    String version,
  ) async {
    askedTexts.add(version);

    return textAnswer;
  }

  /// {@macro act_consent_manager.AbstractConsentService.loadUserConsentData}
  @override
  Future<ResultWithStatus<ConsentLoadStatus, ConsentDataModel<FakeOptions>>>
  loadUserConsentData() async {
    userDataCalls++;

    return userDataAnswer;
  }

  /// {@macro act_consent_manager.AbstractConsentService.saveConsentData}
  @override
  Future<bool> saveConsentData(ConsentDataModel<FakeOptions> consentData) async {
    if (!saveAnswer) {
      return false;
    }

    saved.add(consentData);

    return true;
  }

  /// {@macro act_consent_manager.AbstractConsentService.widgetFromConsentText}
  ///
  /// The widget of a text is built without a markdown library, so that the tests of the service run
  /// without a view.
  @override
  Future<Widget> widgetFromConsentText(String text) async => Text(text);
}

/// The configuration of the application under test, which carries the locales it reads.
class FakeLocaleConfig extends AbstractConfigManager with MixinLocaleConfig {
  /// Class constructor
  FakeLocaleConfig() : super(logger: const SilentLogger());
}

/// The properties of the application under test, which keep the locale the user chose.
class FakeLocaleProperties extends AbstractPropertiesManager with MixinLocaleProperties {}

/// The locales of the application under test.
///
/// The consent manager follows the locale of the application through its locales manager, so a test
/// which drives the consent manager needs a real one, over a configuration and a storage of its
/// own.
class FakeLocalesApp {
  /// The manager the application reads its locale from.
  final LocalesManager manager;

  /// The configuration the locales are read from.
  final FakeLocaleConfig config;

  /// Class constructor
  const FakeLocalesApp({required this.manager, required this.config});

  /// Builds the locales manager of an application and registers it in [globalManager].
  static Future<FakeLocalesApp> install(FakeGlobalManager globalManager) async {
    FakeAssets.serve({"assets/config/default.yaml": "locale:\n  dev:\n    forceWanted: false"});

    final config = FakeLocaleConfig();
    await config.initLifeCycle();

    final properties = FakeLocaleProperties();
    await properties.initLifeCycle();
    await properties.deleteAll();

    final manager = LocalesManager(
      getSupportedLocales: () => const [Locale("fr", "FR"), Locale("en", "GB")],
      propertiesGetter: () => properties,
      configGetter: () => config,
    );
    await manager.initLifeCycle();
    globalManager.managers.registerSingleton<LocalesManager>(manager);

    return FakeLocalesApp(manager: manager, config: config);
  }

  /// The locale the application is shown in, which a page which lets the user choose it sets.
  Locale get shownIn => manager.currentLocale;

  set shownIn(Locale locale) => manager.wantedLocale = locale;

  /// Forgets the locales of the application.
  ///
  /// The configuration of an application is a singleton, so a test which built one has to forget it
  /// before the next test builds its own.
  Future<void> dispose() async {
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
  }
}

/// The consent manager of an application under test.
class FakeConsentManager extends AbstractConsentManager<FakeConsentType> {
  /// The services the application holds, one per consent.
  final Map<FakeConsentType, AbstractConsentService> services;

  /// Class constructor
  FakeConsentManager({required this.services});

  /// {@macro act_consent_manager.AbstractConsentManager.getConsentServices}
  @override
  Future<Map<FakeConsentType, AbstractConsentService>> getConsentServices(
    LogsHelper logsHelper,
  ) async => services;

  /// Registers [observer] the way a derived manager registers one.
  void register(StreamObserver observer) => onRegisterObserver(observer);
}

/// The builder of the consent manager of an application under test.
class FakeConsentBuilder extends AbstractConsentBuilder<FakeConsentManager> {
  /// Class constructor
  FakeConsentBuilder(super.factory);
}
