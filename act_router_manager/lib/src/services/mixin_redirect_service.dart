// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:flutter/cupertino.dart';

/// This mixin can be used on derived classes of AbsWithLifeCycle or BLoC.
///
/// It allows to add a router redirection management on a manager or a global bloc.
/// Multiple classes may use this mixin in your project, but in that case you have to be sure that
/// they won't be active at the same time.
///
/// You may add Mixins to extends this. In that case, the order of your mixins is important:
/// consider that the order of the mixins if also the order of priority; which means: if super asked
/// for a redirection, you have to return this redirection and not impose another one.
mixin MixinRedirectService<T extends MixinRoute> {
  /// This is the router manager
  late final AbstractRouterManager<T> _routerManager;

  /// Router manage getter
  @protected
  AbstractRouterManager<T> get routerManager => _routerManager;

  /// {@template act_router_manager.MixinRedirectService.getRouterManagerFromGlobal}
  /// This method has to be overridden by the derived class to given the router manager of the
  /// project
  /// {@endtemplate}
  @protected
  AbstractRouterManager<T> getRouterManagerFromGlobal();

  /// {@template act_router_manager.MixinRedirectService.initRedirectService}
  /// This method has to be called to initialize the redirect service. It will register the router
  /// redirection.
  /// When the class is no more used don't forget to call [closeRedirectService] method.
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<bool> initRedirectService() async {
    _routerManager = getRouterManagerFromGlobal();

    if (!_routerManager.registerRedirect(onRedirect)) {
      return false;
    }

    return true;
  }

  /// {@template act_router_manager.MixinRedirectService.onRedirect}
  /// This method is called when we want to go to a specific view and ask if it's ok or if we want
  /// to redirect.
  /// If the function returns null, it means that there is nothing to do
  /// If the function returns a non null route:
  ///   - it means that we want to redirect to this page,
  ///   - be aware that the new view replaces the one wanted (therefore, the route tested won't be
  ///     built and displayed),
  ///   - this method will be recalled with the new view we ask (so be careful to not create
  ///     infinite redirection)
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<T?> onRedirect(BuildContext context, T route, GoRouterState state) async => null;

  /// {@template act_router_manager.MixinRedirectService.closeRedirectService}
  /// This method has to be called to close the redirect service. It will unregister the router
  /// redirection.
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> closeRedirectService() async => _routerManager.unregisterRedirect(onRedirect);
}
