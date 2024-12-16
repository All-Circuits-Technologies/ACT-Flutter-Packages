// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
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

  /// The default display callback, it is used when we try to display an unknown view
  /// If not given, an error is returned when trying to call an unknown view
  ViewDisplayCallback? _defaultDisplayCallback;

  /// Set the default display callback
  @protected
  set defaultDisplayCallback(ViewDisplayCallback? defaultCallback) {
    _defaultDisplayCallback = defaultCallback;
  }

  /// Class constructors
  AbstractViewBuilder() : _registeredBuilders = {};

  /// Init the builder, this method is called when the initManager method of the
  /// [ContextualViewsManager] class is called
  @mustCallSuper
  Future<void> initBuilder();

  /// Register a specific view context
  /// This method has to be used if you want to have a particular derived class as parameter of the
  /// callback.
  /// If you don't care about it, you can use [registerAbsViewDisplay]
  void registerViewDisplay<T extends AbstractViewContext>({
    required T context,
    required ViewDisplayCallback<T, dynamic> callback,
  }) {
    assert(!_registeredBuilders.containsKey(context.uniqueKey),
        "The view builder has already registered this context: $context");

    if (_registeredBuilders.containsKey(context.uniqueKey)) {
      appLogger().e("The view builder has already registered this context: $context, we don't "
          "override it");
      return;
    }

    _registeredBuilders[context.uniqueKey] = (context, result) async => callback(
          context as T,
          result,
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
      appLogger().e("The view builder has already registered this context: $context, we don't "
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
    var builder = _registeredBuilders[context.uniqueKey];

    if (builder == null) {
      if (_defaultDisplayCallback == null) {
        appLogger()
            .e("No view builder has been attached to this view context: $context and there is "
                "no default one, we can't proceed");
        return const ViewDisplayResult.error();
      }

      appLogger().w("No view builder has been attached to this view context: $context, we use "
          "the default one");
      builder = _defaultDisplayCallback!;
    }

    return (await builder(context, doAction)).toCast<C>();
  }

  /// Call to dispose the builder
  @mustCallSuper
  Future<void> dispose();
}
