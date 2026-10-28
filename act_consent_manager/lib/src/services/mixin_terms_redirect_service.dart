// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_consent_manager/src/services/abstract_consent_service.dart';
import 'package:act_consent_manager/src/types/consent_state_enum.dart';
import 'package:act_consent_manager/src/types/mixin_terms_route.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:flutter/widgets.dart';

/// A route guard which imposes the terms page while the user has not accepted the terms in force.
///
/// It reads the state of the consent from the service of the terms the application hands over:
/// anything else than [ConsentStateEnum.accepted] imposes the terms page, [ConsentStateEnum.unknown]
/// included: as long as the service could not read the version in force or what the user agreed
/// to, a page which needs accepted terms is not shown; this is not configurable.
///
/// Stack it after the authentication guard: the mixin order is the redirection priority.
///
/// The guard does not follow the account: the application calls
/// [AbstractConsentService.resetLocalConsentInfo] when the user signs out, otherwise the next user
/// is taken for having accepted what the previous one accepted.
mixin MixinTermsRedirectService<T extends MixinTermsRoute> on MixinRedirectService<T> {
  /// The route of the page the terms are accepted on.
  late final T _termsRoute;

  /// The service which holds the terms the user has to accept.
  late final AbstractConsentService _termsService;

  /// This is the subscription to the state of the terms
  ///
  /// This is null as long as the service hasn't been initialized, which may never happen: the
  /// initialization stops before if a redirection is already registered.
  StreamSubscription<ConsentStateEnum>? _stateSub;

  /// Whether a change is being handled, during which the next ones are dropped
  bool _isHandlingChange = false;

  /// {@template act_consent_manager.MixinTermsRedirectService.getTermsRoute}
  /// The page the user is sent to while the terms have to be accepted.
  ///
  /// That page has to answer false to [MixinTermsRoute.needsAcceptedTerms], otherwise the guard
  /// would impose it over and over.
  /// {@endtemplate}
  @protected
  T getTermsRoute();

  /// {@template act_consent_manager.MixinTermsRedirectService.getTermsConsentService}
  /// The service which holds the terms the user has to accept.
  ///
  /// It is read once, when the redirection is initialized, so it has to exist by then.
  /// {@endtemplate}
  @protected
  AbstractConsentService getTermsConsentService();

  /// {@macro act_router_manager.MixinRedirectService.initRedirectService}
  @override
  Future<bool> initRedirectService() async {
    // First call super method, if not null, we don't go further
    if (!(await super.initRedirectService())) {
      return false;
    }

    _termsRoute = getTermsRoute();
    _termsService = getTermsConsentService();
    _stateSub = _termsService.stateStream.listen(_onTermsChanged);

    return true;
  }

  /// Loads what the service of the terms is missing, and answers whether the user has to accept
  /// the terms.
  Future<bool> _isAcceptanceNeeded() async {
    await _termsService.loadAllConsentInfo();

    return _termsService.consentState != ConsentStateEnum.accepted;
  }

  /// Called when the state of the terms changed.
  ///
  /// This is the reactive counterpart of [onRedirect]: a user who is already sitting on a page
  /// which needs accepted terms has to be sent to the terms page without waiting for their next
  /// navigation.
  Future<void> _onTermsChanged(ConsentStateEnum state) async {
    if (_isHandlingChange) {
      // A change which comes during the handling of another is dropped, the state read at the
      // end of the first one is the latest anyway
      return;
    }

    final currentView = routerManager.getCurrentTopView();

    if (currentView == null || !currentView.needsAcceptedTerms) {
      // No need of accepted terms on this page
      return;
    }

    _isHandlingChange = true;
    final isAcceptanceNeeded = await _isAcceptanceNeeded();
    _isHandlingChange = false;

    if (isAcceptanceNeeded) {
      // Not awaited: the future of a replace only completes when the page is left
      unawaited(routerManager.replace(_termsRoute));
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
      // Nothing to do, and nothing to load
      return null;
    }

    return (await _isAcceptanceNeeded()) ? _termsRoute : null;
  }

  /// {@macro act_router_manager.MixinRedirectService.closeRedirectService}
  @override
  Future<void> closeRedirectService() async {
    await super.closeRedirectService();

    await _stateSub?.cancel();
  }
}
