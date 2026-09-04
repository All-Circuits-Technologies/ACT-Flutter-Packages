// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_firebase_crash/act_firebase_crash.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_crashlytics_platform_interface/firebase_crashlytics_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The channel Crashlytics reads the constants of the application from.
const _crashlyticsChannel = "plugins.flutter.io/firebase_crashlytics";

/// The asset key of the configuration file the tests serve.
const _configKey = "assets/config/default.yaml";

/// The options of the application under test.
final _options = CoreFirebaseOptions(
  apiKey: "aKey",
  appId: "anApp",
  messagingSenderId: "aSender",
  projectId: "aProject",
);

/// The Firebase of a test, which starts an application Crashlytics can hang under.
///
/// The Firebase which the tests of the other packages use says nothing of Crashlytics, and
/// Crashlytics refuses to start under an application which does not tell whether it collects.
class _FakeFirebaseCore implements TestFirebaseCoreHostApi {
  /// The application Firebase answers with.
  CoreInitializeResponse _anApp(String name) => CoreInitializeResponse(
    name: name,
    options: _options,
    pluginConstants: {
      _crashlyticsChannel: {"isCrashlyticsCollectionEnabled": false},
    },
  );

  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async => _anApp(appName);

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [_anApp(defaultFirebaseAppName)];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async => _options;
}

/// The Crashlytics of a device, answered by the test.
///
/// It records what it was told, which is what a test reads instead of looking at a console nothing
/// writes to.
class FakeCrashlytics extends FirebaseCrashlyticsPlatform with MockPlatformInterfaceMixin {
  /// The messages which were logged, in the order they were logged.
  final List<String> logs = [];

  /// The errors which were recorded, in the order they were recorded.
  final List<({String exception, bool fatal})> errors = [];

  /// The identifiers of the user which were set, in the order they were set.
  final List<String> identifiers = [];

  /// The number of times the reports which were not sent were asked for.
  int sendUnsentReportsCount = 0;

  /// The number of times the reports which were not sent were dropped.
  int deleteUnsentReportsCount = 0;

  /// Whether the device holds reports which were not sent.
  bool unsentReports = false;

  /// Whether the application crashed the last time it ran.
  bool crashedOnPreviousExecution = false;

  /// Whether the device collects the crashes.
  bool collectionEnabled = false;

  /// Class constructor
  FakeCrashlytics({required super.appInstance});

  /// Starts the Firebase of the test and answers for the Crashlytics of its device.
  ///
  /// Crashlytics only works under the default application, and both that application and the
  /// Crashlytics which serves it are kept for the whole test file: the plugin caches them the first
  /// time it is asked for one, and never looks them up again. So this is called once for the file,
  /// and a test which needs a device in a given state sets it on the Crashlytics it returns rather
  /// than by installing another one.
  static Future<FakeCrashlytics> install() async {
    TestFirebaseCoreHostApi.setUp(_FakeFirebaseCore());
    final app = await Firebase.initializeApp();

    final crashlytics = FakeCrashlytics(appInstance: app);
    FirebaseCrashlyticsPlatform.instance = crashlytics;

    return crashlytics;
  }

  /// Puts the device back in the state it is in when a test starts.
  void reset() {
    logs.clear();
    errors.clear();
    identifiers.clear();
    sendUnsentReportsCount = 0;
    deleteUnsentReportsCount = 0;
    unsentReports = false;
    crashedOnPreviousExecution = false;
    collectionEnabled = false;
  }

  @override
  bool get isCrashlyticsCollectionEnabled => collectionEnabled;

  @override
  FirebaseCrashlyticsPlatform setInitialValues({required bool isCrashlyticsCollectionEnabled}) {
    collectionEnabled = isCrashlyticsCollectionEnabled;

    return this;
  }

  @override
  Future<bool> checkForUnsentReports() async => unsentReports;

  @override
  Future<void> deleteUnsentReports() async {
    deleteUnsentReportsCount++;
    unsentReports = false;
  }

  @override
  Future<bool> didCrashOnPreviousExecution() async => crashedOnPreviousExecution;

  @override
  Future<void> recordError({
    required String exception,
    required String information,
    required String? reason,
    bool fatal = false,
    String? buildId,
    List<String> loadingUnits = const [],
    List<Map<String, String>>? stackTraceElements,
  }) async => errors.add((exception: exception, fatal: fatal));

  @override
  Future<void> log(String message) async => logs.add(message);

  @override
  Future<void> sendUnsentReports() async {
    sendUnsentReportsCount++;
    unsentReports = false;
  }

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async => collectionEnabled = enabled;

  @override
  Future<void> setUserIdentifier(String identifier) async => identifiers.add(identifier);

  @override
  Future<void> setCustomKey(String key, String value) async {}
}

/// The configuration of an application which reports its crashes.
///
/// A real configuration reads its environment from the value the application was built with, and a
/// test cannot build itself twice. This one takes the environment as an argument and drops the one
/// the build gives it.
class FakeCrashConfig extends AbstractConfigManager with MixinFirebaseCrashConf, MixinLoggerConfig {
  /// The environment the test wants the application to run in.
  final Environment _env;

  @override
  Environment get env => _env;

  @override
  set env(Environment value) {
    // The environment of the build is dropped: the test decides which one the application runs in.
  }

  /// Class constructor
  FakeCrashConfig({Environment env = Environment.development})
    : _env = env,
      super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of an application which runs in [env], and returns
  /// the manager which reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeCrashConfig> withContent(
    String content, {
    Environment env = Environment.development,
  }) async {
    FakeAssets.serve({_configKey: content});

    final manager = FakeCrashConfig(env: env);
    await manager.initLifeCycle();

    return manager;
  }
}

/// The logger manager of an application which reports its crashes.
class FakeLoggerManager extends LoggerManager {
  /// Class constructor
  FakeLoggerManager({required FakeCrashConfig config}) : super(loggerConfigGetter: (() => config));
}
