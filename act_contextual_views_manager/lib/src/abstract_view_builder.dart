// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:flutter/cupertino.dart';

/// This method represents an action the contextual view has to call
///
/// The action and the expected result depends of the context.
///
/// The first item in the tuple represents the success or not of the method.
/// The second item in the tuple represents the real value returned by the method. The first item
/// is used to not have to interpret the second item in the view builder.
typedef DoActionDisplayCallback<C> = FutureOr<(bool, C?)> Function();

/// This method represents a callback to display a contextual view
typedef ViewDisplayCallback<T extends AbstractViewContext, C> = FutureOr<ViewDisplayResult<C>>
    Function(
  T viewContext,
  DoActionDisplayCallback<C>? callback,
);

/// This is the abstract view builder which is used to manage the building of contextual views in
/// your app
abstract class AbstractViewBuilder {
  /// The registered builders
  final Map<String, ViewDisplayCallback> _registeredBuilders;

  /// This is the router manager used in the application
  late final AbstractRouterManager _routerManager;

  /// Getter of the router manager used in the application
  @protected
  AbstractRouterManager get routerManager => _routerManager;

  /// The logs helper linked to the contextual manager
  late final LogsHelper _logsHelper;

  /// Getter of the logs helper
  @protected
  LogsHelper get logsHelper => _logsHelper;

  /// Class constructors
  AbstractViewBuilder() : _registeredBuilders = {};

  /// Init the process of the builder, this method is called when the initManager method of the
  /// [ContextualViewsManager] class is called
  Future<void> initBuilder({
    required AbstractRouterManager routerManager,
    required LogsHelper logsHelper,
  }) async {
    _routerManager = routerManager;
    _logsHelper = logsHelper;

    return initProcess();
  }

  /// This method has to be overridden by the derived class and it's called when the linked
  /// [ContextualViewsManager] is initializing.
  /// The [_routerManager] and [_logsHelper] are created when calling this method
  @mustCallSuper
  @protected
  Future<void> initProcess();

  /// Register a specific view context
  /// This method has to be used if you want to have a particular derived class as parameter of the
  /// callback.
  /// If you don't care about it, you can use [registerAbsViewDisplay]
  void registerViewDisplay<T extends AbstractViewContext>({
    required T context,
    required ViewDisplayCallback<T, dynamic> callback,
  }) =>
      registerAbsViewDisplay(
        context: context,
        callback: (context, result) async => callback(
          context as T,
          result,
        ),
      );

  /// Register a page to display when the given context is asked
  void onContextualPage<T extends AbstractViewContext>({
    required T context,
    required MixinRoute route,
  }) =>
      registerAbsViewDisplay(
        context: context,
        callback: (context, doAction) async => _onContextualPageDisplay(
          context: context as T,
          doAction: doAction,
          route: route,
        ),
      );

  /// This method is called when a page has to be displayed
  ///
  /// The method adds a particular extra object to the page
  Future<ViewDisplayResult<C>> _onContextualPageDisplay<C, T extends AbstractViewContext>({
    required T context,
    required DoActionDisplayCallback<C>? doAction,
    required MixinRoute route,
  }) async {
    final completer = Completer<ViewDisplayStatus>();
    C? tmpOtherValue;

    unawaited(_routerManager.push(
      route,
      extra: ExtraContextualViewConfig<T>(
        context: context,
        requestExtraAction: (doAction != null)
            ? () async {
                final (ok, value) = await doAction();

                tmpOtherValue = value;

                return ok;
              }
            : null,
        callWhenEnded: (status) async => completer.complete(status),
      ),
    ));

    final result = await completer.future;

    if (_routerManager.getCurrentTopView() == route) {
      // We pop the view to return to the previous page
      _routerManager.pop();
    }

    return ViewDisplayResult(
      status: result,
      customResult: tmpOtherValue,
    );
  }

  /// Register a specific view context
  /// This method has to be used if you want to register a generic view context and you have no
  /// problem to get the abstract view context
  /// If you want to get a derived class, you can use [registerViewDisplay]
  void registerAbsViewDisplay({
    required AbstractViewContext context,
    required ViewDisplayCallback callback,
  }) {
    assert(!_registeredBuilders.containsKey(context.uniqueKey),
        "The view builder has already registered this context: $context");

    if (_registeredBuilders.containsKey(context.uniqueKey)) {
      _logsHelper.e("The view builder has already registered this context: $context, we don't "
          "override it");
      return;
    }

    _registeredBuilders[context.uniqueKey] = callback;
  }

  /// Ask to display a view thanks to the registered builders
  ///
  /// The meaning and usage of the [doAction] method depends of the [context]. The method returns
  /// two elements.
  /// The first item is a boolean and it's used by the delegated view to know if everything is
  /// alright.
  /// The second item has to be returned in the [ViewDisplayResult]
  Future<ViewDisplayResult<C>> display<C>({
    required AbstractViewContext context,
    DoActionDisplayCallback<C>? doAction,
  }) async {
    final builder = _registeredBuilders[context.uniqueKey];

    if (builder == null) {
      _logsHelper.e("No view builder has been attached to this view context: $context and there is "
          "no default one, we can't proceed");
      return const ViewDisplayResult.error();
    }

    return (await builder(context, doAction)).toCast<C>();
  }

  /// Call to dispose the builder
  @mustCallSuper
  Future<void> dispose();
}
