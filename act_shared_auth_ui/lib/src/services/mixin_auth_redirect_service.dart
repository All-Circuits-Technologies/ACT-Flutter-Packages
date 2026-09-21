// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_ui/src/types/mixin_auth_route.dart';
import 'package:flutter/widgets.dart';

/// This mixin "overrides" [MixinRedirectService] to redirect the views to the sign in page if no
/// user is log in the app and the view requires it.
///
/// When the application names a start route with [getStartRoute], a signed in user is never left
/// on the sign in page: it is sent to that route instead.
mixin MixinAuthRedirectService<T extends MixinAuthRoute> on MixinRedirectService<T> {
  /// The authentication manager
  late final AbsAuthManager _authManager;

  /// The route of the sign in page
  late final T _signInRoute;

  /// This is the stream subscription to the authentication stream status
  ///
  /// This is null as long as the service hasn't been initialized, which may never happen: the
  /// initialization stops before if a redirection is already registered.
  StreamSubscription<AuthStatus>? _authSub;

  /// This is the current auth status
  AuthStatus _authStatus = AuthStatus.signedOut;

  /// {@template act_shared_auth.MixinAuthRedirectService.getAuthenticationManagerFromGlobal}
  /// Get the authentication manager used on the project
  /// {@endtemplate}
  @protected
  AbsAuthManager getAuthenticationManagerFromGlobal();

  /// {@template act_shared_auth.MixinAuthRedirectService.getSignInPage}
  /// Get the route of the sign in page used in the application
  /// {@endtemplate}
  @protected
  T getSignInPage();

  /// {@template act_shared_auth.MixinAuthRedirectService.getStartRoute}
  /// Get the route a signed in user is sent to instead of the sign in page
  ///
  /// Null, the default, leaves a signed in user on the sign in page.
  /// {@endtemplate}
  @protected
  T? getStartRoute() => null;

  /// {@macro act_router_manager.MixinRedirectService.initRedirectService}
  @override
  Future<bool> initRedirectService() async {
    // First call super method, if not null, we don't go further
    if (!(await super.initRedirectService())) {
      return false;
    }

    _authManager = getAuthenticationManagerFromGlobal();
    _signInRoute = getSignInPage();

    _authSub = _authManager.authService.authStatusStream.listen(_onNewAuthStatus);
    _authStatus = _authManager.authService.authStatus;

    return true;
  }

  /// Called when a new authentication status is detected, to apply the rules to the view which is
  /// open: a signed out user doesn't stay on a view which needs an authentication, and a signed in
  /// user doesn't stay on the sign in page when the application names a start route.
  Future<void> _onNewAuthStatus(AuthStatus status) async {
    if (status == _authStatus) {
      // Nothing to do
      return;
    }

    _authStatus = status;

    if (status.isSignedIn) {
      final startRoute = getStartRoute();

      if (startRoute != null && routerManager.getCurrentTopView() == _signInRoute) {
        // A signed in user has nothing to do on the sign in page once the app says where to send it
        unawaited(routerManager.replace(startRoute));
      }

      return;
    }

    if (!(routerManager.getCurrentTopView()?.isAuthNeeded ?? false)) {
      // No need of authentication on this page
      return;
    }

    unawaited(routerManager.pushAndRemoveUntilFirstRoute(_signInRoute));
  }

  /// {@macro act_router_manager.MixinRedirectService.onRedirect}
  ///
  /// If the super class has already required a view, this service don't go further. We consider
  /// that the order of the mixins is also the order of priority
  @override
  Future<T?> onRedirect(BuildContext context, T route, GoRouterState state) async {
    final redirect = await super.onRedirect(context, route, state);

    if (redirect != null) {
      return redirect;
    }

    if (route == _signInRoute) {
      // A signed in user has nothing to do on the sign in page, when the app says where to send it
      return _authStatus.isSignedIn ? getStartRoute() : null;
    }

    if (!route.isAuthNeeded || _authStatus.isSignedIn) {
      // Nothing to do
      return null;
    }

    return _signInRoute;
  }

  /// {@macro act_router_manager.MixinRedirectService.closeRedirectService}
  @override
  Future<void> closeRedirectService() async {
    await super.closeRedirectService();

    await _authSub?.cancel();
  }
}
