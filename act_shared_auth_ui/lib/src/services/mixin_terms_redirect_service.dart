// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_ui/src/types/mixin_terms_route.dart';
import 'package:act_shared_auth_ui/src/utils/terms_acceptance.dart';
import 'package:flutter/widgets.dart';

/// This mixin "overrides" [MixinRedirectService] to impose the terms page on top of the application
/// when the terms in force have not been accepted by the signed in account.
///
/// The acceptance lives on the identity provider, not on the phone: the date it happened travels in
/// the access token as a claim, and the date of the text in force is what the application answers
/// through [getTermsPublishedAt]. Nothing is imposed to a user who is not signed in: the
/// authentication guard runs before this one and owns that case.
///
/// The state is not cached: reading it back from the token in hand costs nothing, and caching it
/// would mean inventing a way to refresh the cache after the user has accepted.
mixin MixinTermsRedirectService<T extends MixinTermsRoute> on MixinRedirectService<T> {
  /// The authentication manager, holding the service which owns the session of the identity
  /// provider.
  late final AbsAuthManager _authManager;

  /// The route of the page the terms are accepted on.
  late final T _termsRoute;

  /// This is the stream subscription to the authentication stream status
  ///
  /// This is null as long as the service hasn't been initialized, which may never happen: the
  /// initialization stops before if a redirection is already registered.
  StreamSubscription<AuthStatus>? _authSub;

  /// {@macro act_shared_auth.MixinAuthRedirectService.getAuthenticationManagerFromGlobal}
  @protected
  AbsAuthManager getAuthenticationManagerFromGlobal();

  /// {@template act_shared_auth_ui.MixinTermsRedirectService.getTermsRoute}
  /// Get the route of the page the terms are accepted on
  ///
  /// That page has to answer false to [MixinTermsRoute.needsAcceptedTerms], otherwise the guard
  /// would impose it over and over.
  /// {@endtemplate}
  @protected
  T getTermsRoute();

  /// {@template act_shared_auth_ui.MixinTermsRedirectService.getTermsPublishedAt}
  /// Get the publication date of the terms in force, or null when the application doesn't know it
  ///
  /// Where it comes from is left to the application: `MixinLegalConf` reads it from the
  /// configuration, and nothing stops an application from reading it from its backend instead.
  /// {@endtemplate}
  @protected
  DateTime? getTermsPublishedAt();

  /// {@macro act_router_manager.MixinRedirectService.initRedirectService}
  @override
  Future<bool> initRedirectService() async {
    // First call super method, if not null, we don't go further
    if (!(await super.initRedirectService())) {
      return false;
    }

    _authManager = getAuthenticationManagerFromGlobal();
    _termsRoute = getTermsRoute();

    if (_authManager.authService is! MixinRawIdpTokenProvider) {
      // Said once here, and not at each navigation, because this is a wiring matter and it never
      // changes while the application runs
      appLogger().d(
        "The authentication service doesn't provide the raw token of an identity provider, the "
        "terms guard lets every navigation through",
      );
    }

    _authSub = _authManager.authService.authStatusStream.listen(_onNewAuthStatus);

    return true;
  }

  /// Tell whether the signed in account still has to accept the terms in force.
  ///
  /// Answers false as soon as anything is missing — no signed in user, an authentication which
  /// hands out no raw token, no token, no date — because locking the user out of the application is
  /// a worse answer than asking them again at their next sign in.
  Future<bool> _mustAcceptTerms() async {
    final service = _authManager.authService;

    if (service is! MixinRawIdpTokenProvider || !service.authStatus.isSignedIn) {
      return false;
    }

    final rawToken = await service.getIdpAccessToken();

    if (rawToken == null) {
      return false;
    }

    return areTermsStale(
      acceptedAt: readTermsAcceptedAt(rawToken),
      publishedAt: getTermsPublishedAt(),
    );
  }

  /// Called when a new authentication status is detected.
  ///
  /// This is the reactive counterpart of [onRedirect]: a user who has just signed in has to be sent
  /// to the terms page without waiting for their next navigation.
  Future<void> _onNewAuthStatus(AuthStatus status) async {
    if (!status.isSignedIn) {
      // Nothing to do
      return;
    }

    final currentView = routerManager.getCurrentTopView();

    if (!(currentView?.needsAcceptedTerms ?? false)) {
      // No need of accepted terms on this page
      return;
    }

    if (await _mustAcceptTerms()) {
      unawaited(routerManager.replace(_termsRoute));
    }
  }

  /// {@macro act_router_manager.MixinRedirectService.onRedirect}
  ///
  /// If the super class has already required a view, this service don't go further. We consider
  /// that the order of the mixins is also the order of priority: signing in comes before accepting
  /// the terms, since the acceptance is read from the session.
  @override
  Future<T?> onRedirect(BuildContext context, T route, GoRouterState state) async {
    final redirect = await super.onRedirect(context, route, state);

    if (redirect != null) {
      return redirect;
    }

    if (!route.needsAcceptedTerms) {
      // Nothing to do, and no token to read
      return null;
    }

    return resolveTermsRedirect(
      mustAcceptTerms: await _mustAcceptTerms(),
      route: route,
      termsRoute: _termsRoute,
    );
  }

  /// {@macro act_router_manager.MixinRedirectService.closeRedirectService}
  @override
  Future<void> closeRedirectService() async {
    await super.closeRedirectService();

    await _authSub?.cancel();
  }
}
