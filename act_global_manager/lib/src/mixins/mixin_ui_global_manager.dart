// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
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

  /// This is the list of managers registered in the app with UI
  @protected
  List<AbsWithLifeCycleAndUi> get registeredManagersWithUi =>
      registeredManagers.whereType<AbsWithLifeCycleAndUi>().toList(growable: false);

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    await Future.wait(
        registeredManagersWithUi.map((manager) => manager.initAfterManagersAndBeforeViews()));
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
        Future.wait(registeredManagersWithUi.map((manager) => manager.initAfterView(context))));

    return true;
  }

  /// {@template act_global_manager.MixinUiGlobalManager.buildFatalErrorPage}
  /// The [buildFatalErrorPage] method is used to build a page to display when a fatal error occurs
  /// during the initialization of the managers before the view is displayed.
  ///
  /// If null, the throw is rethrown and the app crash with the error message in the console.
  /// {@endtemplate}
  Widget? buildFatalErrorPage(Object error) => null;

  /// {@template act_global_manager.MixinUiGlobalManager.runActApp}
  /// The [runActApp] method is used to run the flutter app in the main method of the app
  /// {@endtemplate}
  Future<void> runActApp(Widget app) async {
    // This method forces all initialization async functions to be finished before running the app.
    // This way, we can launch functions at init before the UI is started.
    // The UI starts after these functions are finished.
    WidgetsFlutterBinding.ensureInitialized();

    Widget? fatalErrorWidget;
    try {
      await initLifeCycle();
    } catch (error) {
      appLogger()
          .e("An error occurred during the initialization of the managers before the view is "
              "displayed: $error");
      fatalErrorWidget = buildFatalErrorPage(error);
      if (fatalErrorWidget == null) {
        rethrow;
      }
    }

    runApp(fatalErrorWidget ?? app);
  }
}
