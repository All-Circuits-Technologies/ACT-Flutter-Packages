// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';

/// The pages of an application under test.
enum FakeRoute with MixinRoute {
  /// The page the application starts on.
  home,

  /// The page a contextual view is displayed in.
  terms;

  /// {@macro act_router_manager.MixinRoute.parent}
  @override
  MixinRoute? get parent => null;

  /// {@macro act_router_manager.MixinRoute.transition}
  @override
  RouteTransition? get transition => null;

  /// {@macro act_router_manager.MixinRoute.screenOrientation}
  @override
  ScreenOrientationOption? get screenOrientation => null;
}

/// The reasons an application under test displays a contextual view for.
class FakeViewContext extends AbstractViewContext {
  /// Class constructor
  const FakeViewContext({required super.uniqueKey});
}

/// A reason a view is displayed for, which the user has to answer.
class FakeCompulsoryContext extends AbstractViewContext with MixinCompulsoryAcceptViewContext {
  /// {@macro act_contextual_views_manager.MixinCompulsoryAcceptViewContext.isAcceptanceCompulsory}
  @override
  final bool isAcceptanceCompulsory;

  /// Class constructor
  const FakeCompulsoryContext({required super.uniqueKey, this.isAcceptanceCompulsory = true});

  /// {@macro act_contextual_views_manager.AbstractViewContext.props}
  @override
  List<Object?> get props => [...super.props, isAcceptanceCompulsory];
}

/// The router of an application under test, which records where it was asked to go.
///
/// A real router needs a view to push a page into; this one answers what a test asks of it and
/// records the pages, so that the view builder can be driven without a view.
class FakeRouterManager extends AbstractRouterManager<FakeRoute> {
  /// The pages the router was asked to push, with the extra each one was given.
  final List<({FakeRoute route, Object? extra})> pushed = [];

  /// The number of times the router was asked to pop the page on top.
  int popCount = 0;

  /// The page which is on top, which is the last one which was pushed unless the test says
  /// otherwise.
  FakeRoute? topView;

  /// Class constructor
  FakeRouterManager();

  /// {@macro act_router_manager.AbstractRouterManager.push}
  @override
  Future<Y?> push<Y extends Object?>(
    FakeRoute route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    pushed.add((route: route, extra: extra));
    topView = route;

    return null;
  }

  /// {@macro act_router_manager.AbstractRouterManager.pop}
  @override
  void pop<Y extends Object?>([Y? result]) {
    popCount++;
    topView = FakeRoute.home;
  }

  /// {@macro act_router_manager.AbstractRouterManager.getCurrentTopView}
  @override
  FakeRoute? getCurrentTopView() => topView;

  /// {@macro act_router_manager.AbstractRouterManager.createRoutesHelper}
  @override
  Future<AbstractRoutesHelper<FakeRoute>> createRoutesHelper(LogsHelper logsHelper) =>
      throw UnimplementedError("The router of a test pushes no real page");

  /// The extra the router was given for the page it pushed, when it pushed one only.
  ExtraContextualViewConfig<T> extraOf<T extends AbstractViewContext>() =>
      pushed.single.extra! as ExtraContextualViewConfig<T>;
}

/// The view builder of an application under test.
///
/// The registering of the views of an application happens when the builder is initialized, which is
/// what [register] stands for here.
class FakeViewBuilder extends AbstractViewBuilder {
  /// What the builder registers when it is initialized.
  final void Function(FakeViewBuilder builder)? register;

  /// The number of times the builder was disposed.
  int disposeCount = 0;

  /// The router the builder was handed when it was initialized.
  AbstractRouterManager get routerManagerOfTheApplication => routerManager;

  /// Class constructor
  FakeViewBuilder({this.register});

  /// {@macro act_contextual_views_manager.AbstractViewBuilder.initProcess}
  @override
  Future<void> initProcess() async => register?.call(this);

  /// {@macro act_contextual_views_manager.AbstractViewBuilder.dispose}
  @override
  Future<void> dispose() async => disposeCount++;
}
