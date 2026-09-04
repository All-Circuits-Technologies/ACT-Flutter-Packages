// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_ui/act_shared_auth_ui.dart';
import 'package:flutter/widgets.dart';

/// The pages of an application under test, and whether each of them needs a signed in user.
enum FakeAuthRoute with MixinRoute, MixinAuthRoute {
  /// The page the user signs in on.
  signIn(isAuthNeeded: false),

  /// A page anybody can read.
  about(isAuthNeeded: false),

  /// A page only a signed in user can read.
  profile(isAuthNeeded: true);

  /// {@macro act_shared_auth_ui.MixinAuthRoute.isAuthNeeded}
  @override
  final bool isAuthNeeded;

  /// Enum constructor
  const FakeAuthRoute({required this.isAuthNeeded});

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

/// The authentication service of an application under test.
///
/// Only the status of the user is read by this package, so that is what this service answers.
class FakeAuthService with MixinAuthService {
  /// The stream the service tells the application about its status through.
  final StreamController<AuthStatus> _statusCtrl = StreamController<AuthStatus>.broadcast();

  /// The status the service answers with.
  AuthStatus _authStatus;

  /// Class constructor
  FakeAuthService({AuthStatus authStatus = AuthStatus.signedIn}) : _authStatus = authStatus;

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus => _authStatus;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _statusCtrl.stream;

  /// Tells the application that the user is now [status].
  void updateStatus(AuthStatus status) {
    _authStatus = status;
    _statusCtrl.add(status);
  }

  /// Stops telling the application about the status of the user.
  Future<void> close() => _statusCtrl.close();

  /// {@macro act_shared_auth.MixinAuthService.setStorageService}
  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async {}

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  @override
  Future<AuthSignInResult> signInUser({
    required String username,
    required String password,
  }) async => const AuthSignInResult(status: AuthSignInStatus.done);

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() async => true;

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() async => _authStatus.isSignedIn;
}

/// The authentication manager of an application under test.
class FakeAuthManager extends AbsAuthManager {
  /// The service the manager reads the status of the user from.
  final FakeAuthService service;

  /// Class constructor
  FakeAuthManager({required this.service});

  /// {@macro act_shared_auth.AbsAuthManager.getAuthService}
  @override
  Future<MixinAuthService> getAuthService() async => service;
}

/// The router of an application under test, which records where it was asked to go.
///
/// A real router needs a view to push a page into; this one answers what a test asks of it and
/// records the pages, so that the redirection can be driven without a view.
class FakeRouterManager extends AbstractRouterManager<FakeAuthRoute> {
  /// The pages the router was asked to go to, forgetting everything else.
  final List<FakeAuthRoute> pushedFirst = [];

  /// The number of redirections which were registered.
  int registeredRedirects = 0;

  /// Whether the router accepts the redirection it is registered.
  bool acceptRedirect = true;

  /// The page which is on top.
  FakeAuthRoute? topView;

  /// Class constructor
  FakeRouterManager({this.topView});

  /// {@macro act_router_manager.AbstractRouterManager.registerRedirect}
  @override
  bool registerRedirect(RouterRedirect<FakeAuthRoute> routerRedirect) {
    registeredRedirects++;

    return acceptRedirect;
  }

  /// {@macro act_router_manager.AbstractRouterManager.getCurrentTopView}
  @override
  FakeAuthRoute? getCurrentTopView() => topView;

  /// {@macro act_router_manager.AbstractRouterManager.pushAndRemoveUntilFirstRoute}
  @override
  Future<Y?> pushAndRemoveUntilFirstRoute<Y extends Object?, P extends Object?>(
    FakeAuthRoute route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    P? popArgument,
  }) async {
    pushedFirst.add(route);
    topView = route;

    return null;
  }

  /// {@macro act_router_manager.AbstractRouterManager.createRoutesHelper}
  @override
  Future<AbstractRoutesHelper<FakeAuthRoute>> createRoutesHelper(LogsHelper logsHelper) =>
      throw UnimplementedError("The router of a test pushes no real page");
}

/// A redirection an application puts before the one of the authentication.
///
/// The mixins of a redirection are read in the order they are written, so this one stands for the
/// redirection of an application which answers before the authentication is even asked.
mixin FakeOwnRedirect on MixinRedirectService<FakeAuthRoute> {
  /// The page the redirection of the application asks for, when it asks for one.
  FakeAuthRoute? ownAnswer;

  /// {@macro act_router_manager.MixinRedirectService.onRedirect}
  @override
  Future<FakeAuthRoute?> onRedirect(
    BuildContext context,
    FakeAuthRoute route,
    GoRouterState state,
  ) async => ownAnswer ?? await super.onRedirect(context, route, state);
}

/// The redirection of an application which sends its users to the sign in page.
class FakeAuthRedirectService
    with
        MixinRedirectService<FakeAuthRoute>,
        FakeOwnRedirect,
        MixinAuthRedirectService<FakeAuthRoute> {
  /// The router of the application.
  final FakeRouterManager router;

  /// The authentication manager of the application.
  final FakeAuthManager authManager;

  /// What the initialization of the redirection answered.
  bool initAnswer = false;

  /// Class constructor
  FakeAuthRedirectService({required this.router, required this.authManager});

  /// {@macro act_router_manager.MixinRedirectService.getRouterManagerFromGlobal}
  @override
  AbstractRouterManager<FakeAuthRoute> getRouterManagerFromGlobal() => router;

  /// {@macro act_shared_auth.MixinAuthRedirectService.getAuthenticationManagerFromGlobal}
  @override
  AbsAuthManager getAuthenticationManagerFromGlobal() => authManager;

  /// {@macro act_shared_auth.MixinAuthRedirectService.getSignInPage}
  @override
  FakeAuthRoute getSignInPage() => FakeAuthRoute.signIn;

  /// Initializes the redirection the way the application does.
  Future<bool> init() => initRedirectService();

  /// Closes the redirection the way the application does.
  Future<void> close() => closeRedirectService();

  /// Asks the redirection where to go for [route], the way the router asks it.
  ///
  /// The context and the state of a redirection are what a page is built from, and this redirection
  /// reads neither, so a test hands it values which answer nothing.
  Future<FakeAuthRoute?> askFor(FakeAuthRoute route) =>
      onRedirect(_UnusedContext(), route, _UnusedState());
}

/// The context a redirection of a test is asked with, which answers nothing.
class _UnusedContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("The redirection reads nothing of the context");
}

/// The state a redirection of a test is asked with, which answers nothing.
// The state of the router is a value, and this one only stands in for it
// ignore: avoid_implementing_value_types
class _UnusedState implements GoRouterState {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("The redirection reads nothing of the state");
}
