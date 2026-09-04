// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter/widgets.dart';

/// A manager which records the steps of its life cycle it has been through.
class FakeManager extends AbsWithLifeCycle {
  /// The number of times the manager has been initialized.
  int initCount = 0;

  /// The number of times the manager has been disposed.
  int disposeCount = 0;

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    initCount++;
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    disposeCount++;
    await super.disposeLifeCycle();
  }
}

/// A builder of the manager the tests register.
class FakeManagerBuilder extends AbsLifeCycleFactory<FakeManager> {
  /// The managers the other managers of the application depend on.
  final List<Type> dependencies;

  /// Class constructor
  FakeManagerBuilder(FakeManager manager, {this.dependencies = const []}) : super(() => manager);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => dependencies;
}

/// A manager which depends on the UI and records the steps of its life cycle.
class FakeUiManager extends AbsWithLifeCycleAndUi {
  /// The number of times the manager has been initialized.
  int initCount = 0;

  /// The number of times the manager has been initialized before the first view.
  int initBeforeViewsCount = 0;

  /// The contexts the manager has been initialized after a view with.
  final List<BuildContext> initAfterViewContexts = [];

  /// The errors the manager has been told a fatal error page is about to be shown with.
  final List<Object> fatalErrorPageErrors = [];

  /// The number of times the manager has been disposed.
  int disposeCount = 0;

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    initCount++;
  }

  /// {@macro act_life_cycle.MixinUiLifeCycle.initAfterManagersAndBeforeViews}
  @override
  Future<void> initAfterManagersAndBeforeViews() async {
    await super.initAfterManagersAndBeforeViews();
    initBeforeViewsCount++;
  }

  /// {@macro act_life_cycle.MixinUiLifeCycle.initAfterView}
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);
    initAfterViewContexts.add(context);
  }

  /// {@macro act_life_cycle.MixinUiLifeCycle.onFatalErrorPageWillShow}
  @override
  Future<void> onFatalErrorPageWillShow(Object error) async {
    await super.onFatalErrorPageWillShow(error);
    fatalErrorPageErrors.add(error);
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    disposeCount++;
    await super.disposeLifeCycle();
  }
}

/// A builder of the manager with a UI life cycle the tests register.
class FakeUiManagerBuilder extends AbsLifeCycleFactory<FakeUiManager> {
  /// The managers this one depends on.
  final List<Type> dependencies;

  /// Class constructor
  FakeUiManagerBuilder(FakeUiManager manager, {this.dependencies = const []})
    : super(() => manager);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => dependencies;
}
