// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth_ui/src/types/mixin_terms_route.dart';
import 'package:flutter/widgets.dart';

/// A route guard which imposes the terms page while the user has to accept the terms.
///
/// It doesn't know where the acceptance is kept, nor how the version in force is known: the
/// application answers [mustAcceptTerms], from a consent manager, a token claim, a local store.
/// [getTermsChanges] lets the guard re-evaluate the current page when that answer may have
/// changed, at a sign in or at the end of a load for instance.
///
/// Stack it after the authentication guard: the mixin order is the redirection priority.
mixin MixinTermsRedirectService<T extends MixinTermsRoute> on MixinRedirectService<T> {
  /// The route of the page the terms are accepted on.
  late final T _termsRoute;

  /// This is the subscription to the events the application tells the guard to ask again with
  ///
  /// This is null as long as the service hasn't been initialized, which may never happen: the
  /// initialization stops before if a redirection is already registered. It is null too when the
  /// application hands no stream over.
  StreamSubscription<Object?>? _changesSub;

  /// Whether a change is being handled, during which the next ones are dropped
  bool _isHandlingChange = false;

  /// {@template act_shared_auth_ui.MixinTermsRedirectService.getTermsRoute}
  /// The page the user is sent to while the terms have to be accepted.
  ///
  /// That page has to answer false to [MixinTermsRoute.needsAcceptedTerms], otherwise the guard
  /// would impose it over and over.
  /// {@endtemplate}
  @protected
  T getTermsRoute();

  /// {@template act_shared_auth_ui.MixinTermsRedirectService.mustAcceptTerms}
  /// Whether the user has to accept the terms right now.
  ///
  /// The guard awaits it at every navigation towards a route which needs accepted terms, so it
  /// may load what it needs; the application decides what an unknown answer means.
  /// {@endtemplate}
  @protected
  Future<bool> mustAcceptTerms();

  /// {@template act_shared_auth_ui.MixinTermsRedirectService.getTermsChanges}
  /// A stream which emits whenever the answer of [mustAcceptTerms] may have changed.
  ///
  /// The guard then asks again for the page which is on top, which is how a user already sitting
  /// on a page is sent to the terms. An application which only needs the navigation answers null.
  /// {@endtemplate}
  @protected
  Stream<Object?>? getTermsChanges() => null;

  /// {@macro act_router_manager.MixinRedirectService.initRedirectService}
  @override
  Future<bool> initRedirectService() async {
    // First call super method, if not null, we don't go further
    if (!(await super.initRedirectService())) {
      return false;
    }

    _termsRoute = getTermsRoute();
    _changesSub = getTermsChanges()?.listen(_onTermsChanged);

    return true;
  }

  /// Called when the application says that the answer of [mustAcceptTerms] may have changed.
  ///
  /// This is the reactive counterpart of [onRedirect]: a user who is already sitting on a page
  /// which needs accepted terms has to be sent to the terms page without waiting for their next
  /// navigation.
  Future<void> _onTermsChanged(Object? event) async {
    if (_isHandlingChange) {
      // A change which comes during the handling of another is dropped, and the answer
      // read is the one of the first; queue the changes if an application ever needs both
      return;
    }

    final currentView = routerManager.getCurrentTopView();

    if (currentView == null || !currentView.needsAcceptedTerms) {
      // No need of accepted terms on this page
      return;
    }

    _isHandlingChange = true;
    try {
      if (await mustAcceptTerms()) {
        // Not awaited: the future of a replace only completes when the page is left
        unawaited(routerManager.replace(_termsRoute));
      }
    } finally {
      _isHandlingChange = false;
    }
  }

  /// {@macro act_router_manager.MixinRedirectService.onRedirect}
  ///
  /// If the super class has already required a view, this service don't go further. We consider
  /// that the order of the mixins is also the order of priority: signing in comes before accepting
  /// the terms, since there is no account to read the acceptance of before that.
  @override
  Future<T?> onRedirect(BuildContext context, T route, GoRouterState state) async {
    final redirect = await super.onRedirect(context, route, state);

    if (redirect != null) {
      return redirect;
    }

    if (!route.needsAcceptedTerms) {
      // Nothing to do, and nothing to ask the application
      return null;
    }

    return (await mustAcceptTerms()) ? _termsRoute : null;
  }

  /// {@macro act_router_manager.MixinRedirectService.closeRedirectService}
  @override
  Future<void> closeRedirectService() async {
    await super.closeRedirectService();

    await _changesSub?.cancel();
  }
}
