// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth_ui/act_shared_auth_ui.dart';

/// Builds a token carrying [payload], the way an identity provider would.
///
/// The signature is not one: nothing here verifies it, and the server is what checks the tokens
/// the application actually uses.
String fakeIdpToken(Map<String, dynamic> payload) {
  String segment(Map<String, dynamic> content) =>
      base64Url.encode(utf8.encode(jsonEncode(content))).replaceAll("=", "");

  return "${segment({"alg": "RS256", "typ": "JWT"})}.${segment(payload)}.signature";
}

/// Builds a token whose account accepted the terms on [acceptedAt].
String fakeAcceptanceToken(DateTime acceptedAt) =>
    fakeIdpToken({termsAcceptedAtClaim: acceptedAt.millisecondsSinceEpoch ~/ 1000});

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
