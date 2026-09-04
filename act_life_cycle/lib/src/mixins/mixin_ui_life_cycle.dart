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
  /// Method called just before a fatal error page is displayed in place of the application.
  ///
  /// It is reached on two paths: when the initialization failed at startup (the managers may then
  /// be only partially initialized), and when the application asks for the page at runtime once
  /// everything is up. Because the first path can run in that degraded state, this method must only
  /// do what stays valid regardless (for instance, releasing a resource held back for the normal
  /// startup so the error page can actually be shown). It does not receive a [BuildContext], because
  /// on the startup path the normal first view never happens.
  ///
  /// On the startup path, the method is only called on the managers already registered, and thus
  /// successfully initialized, when the failure happens. A manager whose own initialization is what
  /// failed, or one registered after the manager that failed, does not receive it. A manager that
  /// relies on this method on that path therefore has to be registered early, before the managers
  /// whose failure it wants to react to.
  /// {@endtemplate}
  ///
  /// Call `super.onFatalErrorPageWillShow()` first in the derived class method (unless otherwise
  /// specified by a derived class)
  @mustCallSuper
  Future<void> onFatalErrorPageWillShow(Object error) async {}
}
