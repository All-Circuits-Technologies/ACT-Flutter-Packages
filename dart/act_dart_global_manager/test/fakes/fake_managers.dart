// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_life_cycle/act_dart_life_cycle.dart';

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

/// A manager of another type than [FakeManager], to register two managers in the same application.
class FakeDependentManager extends FakeManager;

/// A builder of the [FakeDependentManager] the tests register.
class FakeDependentManagerBuilder extends AbsLifeCycleFactory<FakeDependentManager> {
  /// The managers this one depends on.
  final List<Type> dependencies;

  /// Class constructor
  FakeDependentManagerBuilder(FakeDependentManager manager, {this.dependencies = const []})
    : super(() => manager);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => dependencies;
}
