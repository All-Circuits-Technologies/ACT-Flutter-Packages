// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_firebase_core/act_firebase_core.dart';
import "package:act_firebase_crash/src/data/firebase_constants.dart" as firebase_constants;
import 'package:act_firebase_crash/src/mixins/mixin_firebase_crash_conf.dart';
import 'package:act_firebase_crash/src/models/firebase_crash_debug_config.dart';
import 'package:act_firebase_crash/src/models/firebase_crash_debug_session_exception.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// This is the service used to manage Firebase Crashlytics on the app
class FirebaseCrashService extends AbsFirebaseService {
  /// Logs category for crashlytics service
  static const _logsCategory = "crashlytics";

  /// The service logs helper
  late final LogsHelper _logsHelper;

  /// This is env manager with the env variables needed by the firebase crash service
  final MixinFirebaseCrashConf _confManager;

  /// If given, this allows to create a session for debugging the application (to use with the
  /// user permission).
  FirebaseCrashDebugConfig? _crashDebugConfig;

  /// If true, the data collection is enabled and all the crash will be stored in the app.
  /// If false, no data collection will be stored if there are some elements left, there will be
  /// deleted.
  bool _enableDataCollection;

  /// If true, the collected logs will be sent automatically.
  /// If false, the collected logs have to be sent manually.
  bool _enableAutoDataCollection;

  /// Class constructor
  FirebaseCrashService({
    required MixinFirebaseCrashConf confManager,
    FirebaseCrashDebugConfig? crashDebugConfig,
  })  : _confManager = confManager,
        _enableDataCollection = firebase_constants.defaultEnableCrashLogs,
        _enableAutoDataCollection = firebase_constants.defaultEnableAutoCrashLogs,
        _crashDebugConfig = crashDebugConfig;

  /// Called at the service initialization
  @override
  Future<void> initService({
    required LogsHelper parentLogsHelper,
  }) async {
    _logsHelper = parentLogsHelper.createASubLogsHelper(_logsCategory);

    _enableDataCollection = _getConfValue(
      confVar: _confManager.firebaseCrashEnable,
      defaultValue: firebase_constants.defaultEnableCrashLogs,
      prodDefaultValue: firebase_constants.defaultProdEnableCrashLogs,
    );

    _enableAutoDataCollection = _getConfValue(
      confVar: _confManager.firebaseCrashAutoLogEnable,
      defaultValue: firebase_constants.defaultEnableAutoCrashLogs,
      prodDefaultValue: firebase_constants.defaultProdEnableAutoCrashLogs,
    );

    if (_enableDataCollection) {
      // We initialize the data collect
      await _updateEnableDataCollection();
    }

    if (_crashDebugConfig != null) {
      // We initialize the config of crash debug
      await _updateCrashDebugConfig();
    }

    await _updateEnableAutoDataCollection();
  }

  /// Enable/disable logs collection
  ///
  /// If true, the data collection is enabled and all the crash will be stored in the app.
  /// If false, no data collection will be stored if there are some elements left, there will be
  /// deleted.
  Future<void> setEnableDataCollection(bool value) async {
    if (value == _enableDataCollection) {
      // Nothing to do
      return;
    }

    _enableDataCollection = value;
    return _updateEnableDataCollection();
  }

  /// The method manages the init/deinit of the data collection depending of
  /// [_enableDataCollection].
  ///
  /// The method doesn't test if the updating has already be done (therefore it's better to do tests
  /// before calling it).
  Future<void> _updateEnableDataCollection() async {
    final loggerManager = globalGetIt().get<LoggerManager>();
    final crashlytics = FirebaseCrashlytics.instance;

    if (_enableDataCollection) {
      loggerManager.addFlutterExceptionHandler(crashlytics.recordFlutterFatalError);
      loggerManager.addPlatformErrorCallback(_recordErrorCrash);
    } else {
      loggerManager.removeFlutterExceptionHandler(crashlytics.recordFlutterFatalError);
      loggerManager.removePlatformErrorCallback(_recordErrorCrash);

      // We don't want to manage crash data collection any more; therefore we delete the unsent
      // reports
      await crashlytics.deleteUnsentReports();
    }
  }

  /// Enable/disable logs collection
  ///
  /// The information is stored in the app properties (therefore, it's kept between each app launch)
  ///
  /// If true, the collected logs will be sent automatically.
  /// If false, the collected logs have to be sent manually.
  Future<void> setEnableAutoDataCollection(bool value) async {
    if (value == _enableAutoDataCollection) {
      // Nothing to do
      return;
    }

    _enableAutoDataCollection = value;
    return _updateEnableAutoDataCollection();
  }

  /// The method manages the init/deinit of the auto data collection depending of
  /// [_enableAutoDataCollection].
  ///
  /// The method doesn't test if the updating has already be done (therefore it's better to do tests
  /// before calling it).
  Future<void> _updateEnableAutoDataCollection() async {
    final crashlytics = FirebaseCrashlytics.instance;

    final realState = crashlytics.isCrashlyticsCollectionEnabled;

    if (realState == _enableAutoDataCollection) {
      // Nothing to do
      return;
    }

    await crashlytics.setCrashlyticsCollectionEnabled(_enableAutoDataCollection);
    if (_enableAutoDataCollection) {
      // Send unsent reports if not already done
      await crashlytics.sendUnsentReports();
    }
  }

  /// Call [FirebaseCrashlytics.sendUnsentReports] method
  ///
  /// This method is only relevant if [_enableAutoDataCollection] is equals to false
  Future<void> sendUnsentReports() async => FirebaseCrashlytics.instance.sendUnsentReports();

  /// Call [FirebaseCrashlytics.deleteUnsentReports] method
  ///
  /// This method is only relevant if [_enableAutoDataCollection] is equals to false
  Future<void> deleteUnsentReports() async => FirebaseCrashlytics.instance.deleteUnsentReports();

  /// Call [FirebaseCrashlytics.checkForUnsentReports] method
  ///
  /// This method is only relevant if [_enableAutoDataCollection] is equals to false
  Future<bool> checkForUnsentReports() async =>
      FirebaseCrashlytics.instance.checkForUnsentReports();

  /// Call [FirebaseCrashlytics.didCrashOnPreviousExecution] method
  ///
  /// Checks whether the app crashed on its previous run.
  Future<bool> didCrashOnPreviousExecution() async =>
      FirebaseCrashlytics.instance.didCrashOnPreviousExecution();

  /// Enable/disable the debugging of the app through Crashlytics
  ///
  /// This allows to send the application logs to Firebase Crashlytics with an identifier to
  /// identify the user. The identifier may be random and not linked to the user (in the view you
  /// can display the id to user to return it to you)
  ///
  /// The information is stored in the app properties (therefore, it's kept between each app
  /// launch).
  ///
  /// If [value] is null, the debugging is disabled.
  Future<void> setCrashDebugConfig(FirebaseCrashDebugConfig? value) async {
    if (_crashDebugConfig == null && value == null) {
      // Nothing to do
      return;
    }

    final onlyUpdateId = (_crashDebugConfig != null && value != null);
    _crashDebugConfig = value;
    await _updateCrashDebugConfig(onlyUpdateId: onlyUpdateId);
  }

  /// This method generates a specific error to send all the crash debug logs kept since the last
  /// crash.
  ///
  /// The logs are only sent at the app restart. Therefore, if you are debugging live you have to
  /// ask the distant user to restart its app.
  ///
  /// Return false, if you haven't set the crash debug config
  Future<bool> sendCrashDebugReport({bool forceCrash = false}) async {
    if (_crashDebugConfig == null) {
      // There is no crash debug config set; therefore nothing has to be sent
      _logsHelper.w("We can't send a crash debug report, if you haven't set the crash debug "
          "config");
      return false;
    }

    await FirebaseCrashlytics.instance.recordError(
      FirebaseCrashDebugSessionException(_crashDebugConfig!.identifier),
      null,
    );

    return true;
  }

  /// The method manages the init/deinit of the crash debugging depending of [_crashDebugConfig].
  ///
  /// The method doesn't test if the updating has already be done (therefore it's better to do tests
  /// before calling it).
  Future<void> _updateCrashDebugConfig({bool onlyUpdateId = false}) async {
    final crashlytics = FirebaseCrashlytics.instance;
    final loggerManager = globalGetIt().get<LoggerManager>();

    if (_crashDebugConfig == null) {
      // We set an empty identifier to remove the existing one
      loggerManager.removeLogListener(_debugLogs);
      await crashlytics.setUserIdentifier("");
    } else if (_crashDebugConfig != null) {
      await crashlytics.setUserIdentifier(_crashDebugConfig!.identifier);

      if (!onlyUpdateId) {
        loggerManager.addLogListener(_debugLogs);
      }
    }
  }

  /// Called when new logs are available if [_enableDataCollection] is equals to true and
  /// [_crashDebugConfig] is not null.
  ///
  /// The log level is compared with the level set in [_crashDebugConfig]
  Future<void> _debugLogs(LogEvent event) async {
    if (!_enableDataCollection || _crashDebugConfig == null) {
      // Nothing to do
      return;
    }

    if (event.level.index < _crashDebugConfig!.level.index) {
      // Nothing to log
      return;
    }

    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.log(AppLogPrinter.defaultFormatLogEvent(event));
  }

  /// Called when an error crash is recorded
  Future<void> _recordErrorCrash(Object exception, StackTrace stackTrace) async =>
      FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        fatal: true,
      );

  /// Get the env value depending of the default value and the prod default value
  T _getConfValue<T>({
    required ConfigVar<T> confVar,
    required T defaultValue,
    T? prodDefaultValue,
  }) {
    final tmpValue = confVar.load();

    if (tmpValue != null) {
      return tmpValue;
    }

    if (prodDefaultValue != null && _confManager.env == Environment.production) {
      return prodDefaultValue;
    }

    return defaultValue;
  }
}
