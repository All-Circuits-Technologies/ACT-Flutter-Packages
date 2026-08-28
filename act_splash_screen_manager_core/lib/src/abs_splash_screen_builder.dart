// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_splash_screen_manager_core/src/abs_splash_screen_manager.dart';

/// Base of the builders of the splash screen managers.
///
/// The builder depends on the logger manager, so that the messages of the initialization the
/// splash screen covers are already written where the application writes them.
abstract class AbsSplashScreenBuilder extends AbsLifeCycleFactory<AbsSplashScreenManager> {
  /// Class constructor
  const AbsSplashScreenBuilder(super.factory);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}
