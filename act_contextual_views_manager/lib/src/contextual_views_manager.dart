// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_contextual_views_manager/src/abstract_view_builder.dart';
import 'package:act_contextual_views_manager/src/models/abstract_view_context.dart';
import 'package:act_contextual_views_manager/src/models/view_display_result.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';

/// This getter is used to get the router manager
typedef _RouterManagerGetter = AbstractRouterManager Function();

/// Builder linked to the contextual views manager
class ContextualViewsBuilder<R extends AbstractRouterManager>
    extends AbsManagerBuilder<ContextualViewsManager> {
  /// Class constructor
  /// The method expects an [AbstractViewBuilder] to use with the manager
  ContextualViewsBuilder({
    required AbstractViewBuilder viewBuilder,
  }) : super(() => ContextualViewsManager._(
              viewBuilder: viewBuilder,
              routerManagerGetter: globalGetIt().get<R>,
            ));

  @override
  Iterable<Type> dependsOn() => [R, LoggerManager];
}

/// This manager is used to display contextual views in the application.
/// The application has to define by itself how it wants to display those views
class ContextualViewsManager extends AbsWithLifeCycle {
  static const _logsCategory = "contextView";

  /// The view builder linked to the manager
  final AbstractViewBuilder _viewBuilder;

  /// This getter is used to get the router manager at the right time
  final _RouterManagerGetter _routerManagerGetter;

  /// This is the logs helper linked to the contextual views manager
  late final LogsHelper _logsHelper;

  /// Class constructor
  ContextualViewsManager._({
    required AbstractViewBuilder viewBuilder,
    required _RouterManagerGetter routerManagerGetter,
  })  : _viewBuilder = viewBuilder,
        _routerManagerGetter = routerManagerGetter;

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _logsCategory,
    );

    await _viewBuilder.initBuilder(
      routerManager: _routerManagerGetter(),
      logsHelper: _logsHelper,
    );
  }

  /// Ask to display a view thanks to the [AbstractViewContext] parameter given
  ///
  /// The meaning and usage of the [doAction] method depends of the [context]. The method returns
  /// two elements.
  /// The first item is a boolean and it's used by the delegated view to know if everything is
  /// alright.
  /// The second item has to be returned in the [ViewDisplayResult]
  Future<ViewDisplayResult<C>> display<C>({
    required AbstractViewContext context,
    DoActionDisplayCallback<C>? doAction,
  }) async =>
      _viewBuilder.display<C>(
        context: context,
        doAction: doAction,
      );

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    final futures = <Future>[
      _viewBuilder.dispose(),
    ];

    await Future.wait(futures);

    await super.disposeLifeCycle();
  }
}
