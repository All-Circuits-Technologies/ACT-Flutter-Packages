// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:convert';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth_ui/act_shared_auth_ui.dart';
import 'package:flutter/widgets.dart';

/// Builds a token carrying [payload], the way an identity provider would.
///
/// The signature is not one: nothing here verifies it, and the server is what checks the tokens
/// the application actually uses.
String fakeIdpToken(Map<String, dynamic> payload) {
  String segment(Map<String, dynamic> content) =>
      base64Url.encode(utf8.encode(jsonEncode(content))).replaceAll("=", "");

  return "${segment({"alg": "RS256", "typ": "JWT"})}.${segment(payload)}.signature";
}

/// The pages of an application under test, and whether each of them needs accepted terms.
enum FakeTermsRoute with MixinRoute, MixinTermsRoute {
  /// The page the user accepts the terms on, which has to stay reachable.
  terms(needsAcceptedTerms: false),

  /// A page anybody can read.
  about(needsAcceptedTerms: false),

  /// A page only a user who accepted the terms in force can read.
  home(needsAcceptedTerms: true);

  /// {@macro act_shared_auth_ui.MixinTermsRoute.needsAcceptedTerms}
  @override
  final bool needsAcceptedTerms;

  /// Enum constructor
  const FakeTermsRoute({required this.needsAcceptedTerms});

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

/// The router of an application under test, which records the pages it was asked to replace with.
///
/// A real router needs a view to push a page into; this one answers what a test asks of it and
/// records the pages, so that the redirection can be driven without a view.
class FakeTermsRouterManager extends AbstractRouterManager<FakeTermsRoute> {
  /// The pages the router was asked to replace the page on top with.
  final List<FakeTermsRoute> replaced = [];

  /// The page which is on top.
  FakeTermsRoute? topView;

  /// Class constructor
  FakeTermsRouterManager({this.topView});

  /// {@macro act_router_manager.AbstractRouterManager.registerRedirect}
  @override
  bool registerRedirect(RouterRedirect<FakeTermsRoute> routerRedirect) => true;

  /// {@macro act_router_manager.AbstractRouterManager.getCurrentTopView}
  @override
  FakeTermsRoute? getCurrentTopView() => topView;

  /// {@macro act_router_manager.AbstractRouterManager.replace}
  @override
  Future<Y?> replace<Y extends Object?>(
    FakeTermsRoute route, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) async {
    replaced.add(route);
    topView = route;

    return null;
  }

  /// {@macro act_router_manager.AbstractRouterManager.createRoutesHelper}
  @override
  Future<AbstractRoutesHelper<FakeTermsRoute>> createRoutesHelper(LogsHelper logsHelper) =>
      throw UnimplementedError("The router of a test pushes no real page");
}

/// The redirection of an application which imposes its terms page.
///
/// The application is what answers the question the guard asks, so this one answers what the test
/// decided and records how many times it was asked.
class FakeTermsRedirectService
    with MixinRedirectService<FakeTermsRoute>, MixinTermsRedirectService<FakeTermsRoute> {
  /// The router of the application.
  final FakeTermsRouterManager router;

  /// What the application answers when the guard asks whether the terms are to be accepted.
  bool mustAccept;

  /// The number of times the guard asked the application.
  int mustAcceptCalls = 0;

  /// The events the application tells the guard that its answer may have changed through.
  // The stream belongs to the application, not to the redirection, so a test closes it itself
  // ignore: close_sinks
  final StreamController<Object?> changes = StreamController<Object?>.broadcast();

  /// Whether the application hands the guard a stream at all.
  final bool withChanges;

  /// Class constructor
  FakeTermsRedirectService({
    required this.router,
    this.mustAccept = false,
    this.withChanges = true,
  });

  /// {@macro act_router_manager.MixinRedirectService.getRouterManagerFromGlobal}
  @override
  AbstractRouterManager<FakeTermsRoute> getRouterManagerFromGlobal() => router;

  /// {@macro act_shared_auth_ui.MixinTermsRedirectService.getTermsRoute}
  @override
  FakeTermsRoute getTermsRoute() => FakeTermsRoute.terms;

  /// {@macro act_shared_auth_ui.MixinTermsRedirectService.mustAcceptTerms}
  @override
  Future<bool> mustAcceptTerms() async {
    mustAcceptCalls++;

    return mustAccept;
  }

  /// {@macro act_shared_auth_ui.MixinTermsRedirectService.getTermsChanges}
  @override
  Stream<Object?>? getTermsChanges() => withChanges ? changes.stream : null;

  /// Initializes the redirection the way the application does.
  Future<bool> init() => initRedirectService();

  /// Closes the redirection the way the application does.
  ///
  /// The stream is the one of the application, so it outlives the redirection and a test closes
  /// it on its own.
  Future<void> close() => closeRedirectService();

  /// Asks the redirection where to go for [route], the way the router asks it.
  ///
  /// The context and the state of a redirection are what a page is built from, and this
  /// redirection reads neither, so a test hands it values which answer nothing.
  Future<FakeTermsRoute?> askFor(FakeTermsRoute route) =>
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
