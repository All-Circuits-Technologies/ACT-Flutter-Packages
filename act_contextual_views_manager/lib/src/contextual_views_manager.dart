// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_contextual_views_manager/src/abstract_view_builder.dart';
import 'package:act_contextual_views_manager/src/models/abstract_view_context.dart';
import 'package:act_contextual_views_manager/src/models/view_display_result.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// Builder linked to the contextual views manager
class ContextualViewsBuilder extends ManagerBuilder<ContextualViewsManager> {
  /// Class constructor
  /// The method expects an [AbstractViewBuilder] to use with the manager
  ContextualViewsBuilder({
    required AbstractViewBuilder viewBuilder,
  }) : super(() => ContextualViewsManager(viewBuilder: viewBuilder));

  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// This manager is used to display contextual views in the application.
/// The application has to define by itself how it wants to display those views
class ContextualViewsManager extends AbstractManager {
  /// The view builder linked to the manager
  final AbstractViewBuilder _viewBuilder;

  /// Class constructor
  ContextualViewsManager({
    required AbstractViewBuilder viewBuilder,
  }) : _viewBuilder = viewBuilder;

  /// The init manager
  @override
  Future<void> initManager() async {
    await _viewBuilder.initBuilder();
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

  /// Dispose the manager
  @override
  Future<void> dispose() async {
    final futures = <Future>[
      super.dispose(),
      _viewBuilder.dispose(),
    ];

    await Future.wait(futures);
  }
}
