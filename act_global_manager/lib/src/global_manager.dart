// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The [globalGetIt] function is used to shortcut access to the managers
GetIt globalGetIt() => GlobalManager.instance!.managers;

/// The [appLogger] function is used to shortcut access to the default logger
LoggerManager appLogger() => GlobalManager.instance!.defaultLogger;

/// The [_GlobalManagerState] enum is used to manage the GlobalManager state
enum _GlobalManagerState {
  notCreated,
  created,
  allReady,
  initForWidget,
}

/// The [GlobalManager] is used to store the Application managers
///
/// In the top class, you have to instantiate and set the [GlobalManager]
///  [instance]
abstract class GlobalManager {
  /// The global manager instance
  static GlobalManager? _instance;

  /// Getter of the global manager instance
  static GlobalManager? get instance => _instance;

  /// Set the global manager instance, this has to be called by the derived class.
  @protected
  // The getter linked is [instance]
  // ignore: avoid_setters_without_getters
  static set setInstance(GlobalManager globalManager) => _instance = globalManager;

  /// This is the Get it instance used to get managers
  final managers = GetIt.instance;

  /// This returns true if the app is in release mode
  final isReleaseMode = kReleaseMode;

  /// This is the default logger to use in the app
  late final LoggerManager _defaultLogger;

  /// This is the current state of the global manager
  _GlobalManagerState _state = _GlobalManagerState.notCreated;

  /// The information contained in the pubspec.yaml of the mobile application
  late PackageInfo _packageInfo;

  /// Get the default logger value
  LoggerManager get defaultLogger => _defaultLogger;

  /// Get the app package info
  PackageInfo get packageInfo => _packageInfo;

  /// The create constructor is used to construct the singleton instance
  GlobalManager.create() : _state = _GlobalManagerState.created;

  /// This method is used to register asynchronously the app managers
  ///
  /// If the manager you want to register is the Logger Manager, this registers the
  /// [_defaultLogger].
  @protected
  void registerManagerAsync<T extends AbsWithLifeCycle>(AbsManagerBuilder<T> builder) {
    var asyncFactory = builder.asyncFactory;
    if (T == LoggerManager) {
      asyncFactory = () async {
        final loggerManager = await builder.asyncFactory();

        GlobalManager.instance!._defaultLogger = loggerManager as LoggerManager;

        return loggerManager;
      };
    }

    managers.registerSingletonAsync<T>(
      asyncFactory,
      dependsOn: builder.dependsOn(),
    );
  }

  /// The [init] function is called at class constructor to init the singletons
  @protected
  @mustCallSuper
  void init();

  /// The [allReadyBeforeView] method has to be called before creating the
  /// first widget
  @mustCallSuper
  Future<void> allReadyBeforeView() async {
    await managers.allReady();

    if (_state.index < _GlobalManagerState.allReady.index) {
      _state = _GlobalManagerState.allReady;
    }

    // Add here what's to be called after that all managers have been loaded
    // and before the views are loaded and displayed
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// The [initInFirstView] method is used to init what need to be init with
  /// managers and the MaterialApp context
  ///
  /// The method has to be called in the MaterialApp builder
  ///
  /// The method returns false if it has already been initialized or
  /// true if it's the first call
  @mustCallSuper
  bool initInFirstView(BuildContext context) {
    if (_state.index >= _GlobalManagerState.initForWidget.index) {
      // Already initialized
      return false;
    }

    // Initialize screen
    instance?.initScreen(context);

    instance!._state = _GlobalManagerState.initForWidget;
    return true;
  }

  /// The [initScreen] method is used to init the screen
  /// Possibly used with ScreenUtil plugin and add the instance to managers
  @mustCallSuper
  void initScreen(BuildContext context) {}
}
