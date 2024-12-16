// Copyright (c) 2020. BMS Circuits

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:package_info/package_info.dart';

/// The [GlobalGetIt] function is used to shortcut access to the managers
GetIt GlobalGetIt() => GlobalManager.instance.managers;

/// The [EssLogger] function is used to shortcut access to the default logger
Logger AppLogger() => GlobalManager.instance.defaultLogger;

/// The [_GlobalManagerState] enum is used to manage the GlobalManager state
enum _GlobalManagerState {
  NotCreated,
  Created,
  AllReady,
  InitForWidget,
}

/// The [GlobalManager] is used to store the Application managers
///
/// In the top class, you have to instantiate and set the [GlobalManager]
///  [instance]
abstract class GlobalManager {
  static GlobalManager _instance;

  static GlobalManager get instance => _instance;

  @protected
  static set instance(GlobalManager globalManager) => _instance = globalManager;

  final managers = GetIt.instance;

  final isReleaseMode = kReleaseMode;

  Logger _defaultLogger;

  _GlobalManagerState _state = _GlobalManagerState.NotCreated;

  /// The information contained in the pubspec.yaml of the mobile application
  PackageInfo _packageInfo;

  Logger get defaultLogger => _defaultLogger;

  PackageInfo get packageInfo => _packageInfo;

  /// The [_create] constructor is used to construct the singleton instance
  GlobalManager.create() : _state = _GlobalManagerState.Created;

  @protected
  void registerSingletonAsync<T extends AbstractManager>(
      ManagerBuilder<T> builder) {
    managers.registerSingletonAsync<T>(
      builder.asyncFactory,
      dependsOn: builder.dependsOn(),
    );
  }

  /// The [_init] function is called at class constructor to init the singletons
  @protected
  @mustCallSuper
  void init() {
    var loggerBuilder = LoggerBuilder();

    var loggerFactory = () async {
      LoggerManager loggerManager = await loggerBuilder.asyncFactory();

      GlobalManager.instance._defaultLogger = loggerManager.logger;

      return loggerManager;
    };

    managers.registerSingletonAsync<LoggerManager>(
      loggerFactory,
      dependsOn: loggerBuilder.dependsOn(),
    );
  }

  /// The [allReadyBeforeView] method has to be called before creating the
  /// first widget
  @mustCallSuper
  Future<void> allReadyBeforeView() async {
    await managers.allReady();

    if (_state.index < _GlobalManagerState.AllReady.index) {
      _state = _GlobalManagerState.AllReady;
    }

    // Add here what's to be called after that all managers have been loaded
    // and before the views are loaded and displayed
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// The [initInFirstView] method is used to init what need to be init with
  /// managers and the MaterialApp context
  ///
  /// The method has to be called in the MaterialApp builder
  @mustCallSuper
  void initInFirstView(BuildContext context) {
    if (_state.index >= _GlobalManagerState.InitForWidget.index) {
      // Already initialized
      return;
    }

    instance._state = _GlobalManagerState.InitForWidget;
  }
}
