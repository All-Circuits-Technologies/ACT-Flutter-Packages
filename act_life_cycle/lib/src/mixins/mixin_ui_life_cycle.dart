// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/src/services/abs_with_life_cycle.dart';
import 'package:flutter/widgets.dart';

/// This mixin is used to add methods to services and managers linked to the UI life cycle
mixin MixinUiLifeCycle on AbsWithLifeCycle {
  /// {@template act_life_cycle.MixinUiLifeCycle.initAfterManagersAndBeforeViews}
  /// This method is called after all the managers are initialized but before the first view is
  /// built.
  ///
  /// This method can be called in the same time as the other managers
  /// [initAfterManagersAndBeforeViews] method, so it should not be used to call methods from other
  /// managers, but it can be used to initialize some variables or do some operations that need
  /// to be done before the first view is built.
  /// {@endtemplate}
  ///
  /// Call `super.initAfterManagersAndBeforeViews()` first in the derived class method (unless
  /// otherwise specified by a derived class)
  @mustCallSuper
  Future<void> initAfterManagersAndBeforeViews() async {}

  /// {@template act_life_cycle.MixinUiLifeCycle.initAfterView}
  /// Method called asynchronously after the view is initialized
  ///
  /// This [BuildContext] is above the Navigator (therefore it can't be used to access it)
  /// {@endtemplate}
  ///
  /// Call `super.initAfterView()` first in the derived class method (unless otherwise specified by
  /// a derived class)
  @mustCallSuper
  Future<void> initAfterView(BuildContext context) async {}

  /// {@template act_life_cycle.MixinUiLifeCycle.onFatalErrorPageWillShow}
  /// Method called when the initialization failed and a fatal error page is about to be displayed
  /// instead of the application.
  ///
  /// It is called just before the error page is run, and only when one is provided. On this path
  /// the managers have not been fully initialized, so this method must only do what stays valid in
  /// that degraded state (for instance, releasing resources held back for the normal startup so the
  /// error page can actually be shown). It does not receive a [BuildContext] for that reason.
  ///
  /// The method is only called on the managers that have already been registered, and thus
  /// successfully initialized, when the failure happens. A manager whose own initialization is what
  /// failed, or one registered after the manager that failed, never receives it. A manager that
  /// relies on this method to run even on failure therefore has to be registered early, before the
  /// managers whose failure it wants to react to.
  /// {@endtemplate}
  ///
  /// Call `super.onFatalErrorPageWillShow()` first in the derived class method (unless otherwise
  /// specified by a derived class)
  @mustCallSuper
  Future<void> onFatalErrorPageWillShow(Object error) async {}
}
