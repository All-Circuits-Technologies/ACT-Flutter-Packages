// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_global_manager/act_dart_global_manager.dart';
import 'package:act_global_manager/src/services/ui_fatal_error_manager.dart';
import 'package:act_global_manager/src/types/global_manager_ui_state.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// This mixin is used to add methods to the global manager linked to the UI life cycle
///
/// Add this when you need to create an UI Application
mixin MixinUiGlobalManager on AbsGlobalManager {
  /// The information contained in the pubspec.yaml of the mobile application
  late final PackageInfo _packageInfo;

  /// The handlers which receive the errors reported by Flutter, once they are logged
  ///
  /// A mixin can't declare a constructor, this is why the registry is initialized here.
  final Set<FlutterExceptionHandler> _flutterExceptionHandlers = {};

  /// Get the app package info
  ///
  /// It is available once [initLifeCycle] has loaded it.
  PackageInfo get packageInfo => _packageInfo;

  /// {@macro act_global_manager.AbsGlobalManager.getGlobalManagerStates}
  @override
  List<Enum> getGlobalManagerStates() => GlobalManagerUiState.getAllColumns();

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    final hasReachedStartInit = isStateReached(GlobalManagerState.startInit);

    await super.initLifeCycle();

    if (hasReachedStartInit) {
      // The state was already reached before calling super.initLifeCycle(); therefore, we don't go
      // further
      return;
    }

    _packageInfo = await PackageInfo.fromPlatform();

    await callUiMethodFollowingOrder(
      method: (manager) async => manager.initAfterManagersAndBeforeViews(),
    );
  }

  /// {@template act_global_manager.MixinUiGlobalManager.initInFirstView}
  /// The [initInFirstView] method is used to init what need to be init with
  /// managers and the MaterialApp context
  ///
  /// The method has to be called in the MaterialApp builder and has to be called after
  /// [initLifeCycle] is finished.
  ///
  /// The method returns false if it has already been initialized or
  /// true if it's the first call
  /// {@endtemplate}
  @mustCallSuper
  bool initInFirstView(BuildContext context) {
    if (!tryAdvanceToState(GlobalManagerUiState.initForWidget)) {
      return false;
    }

    // We don't wait the initialization here to not block the display of the first view
    unawaited(
      callUiMethodFollowingOrder(method: (manager) async => manager.initAfterView(context)),
    );

    return true;
  }

  /// Add a handler which receives the errors reported by Flutter (through [FlutterError.onError])
  ///
  /// The error is logged first, then given to every handler added with this method. The hooks are
  /// installed by [runActApp].
  void addFlutterExceptionHandler(FlutterExceptionHandler handler) =>
      _flutterExceptionHandlers.add(handler);

  /// Remove a handler added with [addFlutterExceptionHandler]
  void removeFlutterExceptionHandler(FlutterExceptionHandler handler) =>
      _flutterExceptionHandlers.remove(handler);

  /// {@template act_global_manager.MixinUiGlobalManager.runActApp}
  /// The [runActApp] method is used to run the flutter app in the main method of the app
  ///
  /// It also installs the hooks which catch the uncaught errors: [FlutterError.onError] logs the
  /// errors reported by Flutter and gives them to the handlers added with
  /// [addFlutterExceptionHandler], and [PlatformDispatcher.onError] gives the errors of the
  /// platform to the `LoggerManager` when it is ready, or logs them otherwise.
  /// {@endtemplate}
  Future<void> runActApp(Widget app) async {
    // This method forces all initialization async functions to be finished before running the app.
    // This way, we can launch functions at init before the UI is started.
    // The UI starts after these functions are finished.
    WidgetsFlutterBinding.ensureInitialized();

    // The hooks are installed before the managers are initialized, to catch the errors which occur
    // during the start of the app
    FlutterError.onError = _onFlutterError;
    PlatformDispatcher.instance.onError = _onPlatformError;

    Object? startupError;
    StackTrace? startupStack;
    try {
      await initLifeCycle();
    } catch (error, stack) {
      appLogger().e(
        "An error occurred during the initialization of the managers before the view is "
        "displayed: $error",
      );
      startupError = error;
      startupStack = stack;
    }

    final uiFatalErrorManager = _getUiFatalErrorManager();
    if (startupError != null && uiFatalErrorManager == null) {
      // An error occurred and there is no manager to manage it
      Error.throwWithStackTrace(startupError, startupStack!);
    }

    if (uiFatalErrorManager != null) {
      uiFatalErrorManager.addFatalErrorWillShowHandler(_notifyFatalErrorPageWillShow);

      if (startupError != null) {
        uiFatalErrorManager.displayFatalErrorPage(startupError);
      }
    }

    runApp(uiFatalErrorManager?.wrapWithFatalErrorWidget(child: app) ?? app);
  }

  /// Calls [method] on every registered manager which takes part in the UI life cycle, level by
  /// level, the way [callMethodFollowingOrder] does for every manager.
  ///
  /// Only the managers which mix in [MixinUiLifeCycle] are reached, and [method] is given each of
  /// them already cast to that type. [isFollowingOrder] walks the dependency levels forward for
  /// initialization and backward for teardown.
  @protected
  Future<void> callUiMethodFollowingOrder({
    required Future<void> Function(MixinUiLifeCycle manager) method,
    bool isFollowingOrder = true,
  }) async => callMethodFollowingOrder(
    method: (manager) async => method(manager as MixinUiLifeCycle),
    condition: (manager) => manager is MixinUiLifeCycle,
    isFollowingOrder: isFollowingOrder,
  );

  /// Log the Flutter error given by [details], then give it to the handlers added with
  /// [addFlutterExceptionHandler]
  void _onFlutterError(FlutterErrorDetails details) {
    appLogger().e(details.exceptionAsString(), details.exception, details.stack);

    for (final handler in _flutterExceptionHandlers.toList()) {
      handler(details);
    }
  }

  /// Log the uncaught platform error, given by [exception] and [stackTrace]
  ///
  /// The error is given to the [LoggerManager] once it is initialized, which also calls its
  /// platform error callbacks; before that, it is logged with the default logger.
  ///
  /// The manager is looked up in [registeredManagers], which only holds the managers whose
  /// initialization is over: the lookup never throws, whatever the way the manager was registered.
  ///
  /// Always returns true, to tell the platform that the error has been handled.
  bool _onPlatformError(Object exception, StackTrace stackTrace) {
    final loggerManager = registeredManagers.whereType<LoggerManager>().firstOrNull;
    if (loggerManager != null) {
      return loggerManager.logUncaughtError(exception, stackTrace);
    }

    appLogger().e(exception.toString(), exception, stackTrace);
    return true;
  }

  /// Get the UI fatal error manager if it is registered, otherwise return null.
  UiFatalErrorManager? _getUiFatalErrorManager() =>
      registeredManagers.whereType<UiFatalErrorManager>().firstOrNull;

  /// {@template act_global_manager.MixinUiGlobalManager.notifyFatalErrorPageWillShow}
  /// Notifies the UI managers that a fatal error page is about to be displayed instead of the
  /// application.
  ///
  /// This is reached both when the initialization fails at startup and when the application asks
  /// for the page at runtime through `displayFatalErrorPage`. The normal startup path
  /// ([initInFirstView]) never runs on the first case, so managers that need to react to the error
  /// page being shown (for instance to release resources held back for the normal startup) can only
  /// be reached through this method.
  /// {@endtemplate}
  Future<void> _notifyFatalErrorPageWillShow(Object error) async => callUiMethodFollowingOrder(
    method: (manager) async => manager.onFatalErrorPageWillShow(error),
  );
}
