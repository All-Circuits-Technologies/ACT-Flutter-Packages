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
mixin MixinAuthRedirectService<T extends MixinAuthRoute> on MixinRedirectService<T> {
  /// The authentication manager
  late final AbsAuthManager _authManager;

  /// The route of the sign in page
  late final T _signInRoute;

  /// This is the stream subscription to the authentication stream status
  late final StreamSubscription<AuthStatus> _authSub;

  /// This is the current auth status
  AuthStatus _authStatus = AuthStatus.signedOut;

  /// Get the authentication manager used on the project
  @protected
  AbsAuthManager getAuthenticationManagerFromGlobal();

  /// Get the route of the sign in page used in the application
  @protected
  T getSignInPage();

  /// This method has to be called to initialize the redirect service.
  /// When the class is no more used don't forget to call [closeRedirectService] method.
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

  /// Called when a new authentication status is detected.
  ///
  /// If no user is connected to the app and the current view needs an authentication, this
  /// redirects to the authentication page.
  Future<void> _onNewAuthStatus(AuthStatus status) async {
    if (status == _authStatus) {
      // Nothing to do
      return;
    }

    _authStatus = status;

    if (status.isSignedIn) {
      // Nothing to do
      return;
    }

    if (!(routerManager.getCurrentTopView()?.isAuthNeeded ?? false)) {
      // No need of authentication on this page
      return;
    }

    unawaited(routerManager.pushAndRemoveUntilFirstRoute(_signInRoute));
  }

  /// This method is called when we want to go to a specific view and ask if it's ok or if we want
  /// to redirect.
  /// If the function returns null, it means that there is nothing to do
  /// If the function returns a non null route:
  ///   - it means that we want to redirect to this page,
  ///   - be aware that the new view replaces the one wanted (therefore, the route tested won't be
  ///     built and displayed),
  ///   - this method will be recalled with the new view we ask (so be careful to not create
  ///     infinite redirection)
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
      // Nothing to do
      return null;
    }

    if (!route.isAuthNeeded || _authStatus.isSignedIn) {
      // Nothing to do
      return null;
    }

    return _signInRoute;
  }

  /// This method has to be called to close the redirect service. It will unregister the router
  /// redirection.
  @override
  Future<void> closeRedirectService() async {
    await super.closeRedirectService();

    await _authSub.cancel();
  }
}
