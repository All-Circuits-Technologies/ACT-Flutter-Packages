// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_global_manager/src/types/global_manager_state.dart';
import 'package:act_global_manager/src/types/global_manager_ui_state.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter/widgets.dart';

/// This mixin is used to add methods to the global manager linked to the UI life cycle
///
/// Add this when you need to create an UI Application
mixin MixinUiGlobalManager on AbsGlobalManager {
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

  /// {@template act_global_manager.MixinUiGlobalManager.runActApp}
  /// The [runActApp] method is used to run the flutter app in the main method of the app
  /// {@endtemplate}
  Future<void> runActApp(Widget app) async {
    // This method forces all initialization async functions to be finished before running the app.
    // This way, we can launch functions at init before the UI is started.
    // The UI starts after these functions are finished.
    WidgetsFlutterBinding.ensureInitialized();

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
