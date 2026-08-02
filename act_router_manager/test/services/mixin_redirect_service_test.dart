// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../fakes/fake_routes.dart';

void main() {
  late FakeRouterManager manager;

  setUp(() async {
    FakeGlobalManager.install();
    manager = FakeRouterManager();
    await manager.initLifeCycle();
    await manager.initAfterManagersAndBeforeViews();
    addTearDown(manager.router.dispose);
  });

  group("MixinRedirectService.initRedirectService", () {
    test("registers its redirection on the router manager", () async {
      final service = _RedirectService(manager);

      expect(await service.start(), isTrue);
      expect(manager.hasARouterRedirection, isTrue);
    });

    test("returns false when the manager already has a redirection", () async {
      await _RedirectService(manager).start();

      expect(await _RedirectService(manager).start(), isFalse);
    });
  });

  group("MixinRedirectService.closeRedirectService", () {
    test("unregisters its redirection from the router manager", () async {
      final service = _RedirectService(manager);
      await service.start();

      await service.stop();

      expect(manager.hasARouterRedirection, isFalse);
    });

    test("leaves the redirection of another service alone", () async {
      await _RedirectService(manager).start();
      final refused = _RedirectService(manager);
      await refused.start();

      await refused.stop();

      expect(manager.hasARouterRedirection, isTrue);
    });
  });

  group("MixinRedirectService.onRedirect", () {
    test("lets every page through unless the derived class says otherwise", () async {
      final service = _RedirectService(manager);

      expect(await service.redirect(FakeRoute.settings), isNull);
    });

    test("returns the page the derived class redirects to", () async {
      final service = _RedirectService(manager, redirectTo: FakeRoute.home);

      expect(await service.redirect(FakeRoute.settings), FakeRoute.home);
    });
  });
}

/// A service of an application which watches where the router goes.
class _RedirectService with MixinRedirectService<FakeRoute> {
  /// The manager the service registers its redirection on.
  final FakeRouterManager manager;

  /// The page the service sends every other one to, if it has one.
  final FakeRoute? redirectTo;

  /// Class constructor
  _RedirectService(this.manager, {this.redirectTo});

  /// {@macro act_router_manager.MixinRedirectService.getRouterManagerFromGlobal}
  @override
  AbstractRouterManager<FakeRoute> getRouterManagerFromGlobal() => manager;

  /// {@macro act_router_manager.MixinRedirectService.initRedirectService}
  Future<bool> start() => initRedirectService();

  /// {@macro act_router_manager.MixinRedirectService.closeRedirectService}
  Future<void> stop() => closeRedirectService();

  /// {@macro act_router_manager.MixinRedirectService.onRedirect}
  Future<FakeRoute?> redirect(FakeRoute route) =>
      onRedirect(_FakeContext(), route, _aState(route));

  /// {@macro act_router_manager.MixinRedirectService.onRedirect}
  @override
  Future<FakeRoute?> onRedirect(
    BuildContext context,
    FakeRoute route,
    GoRouterState state,
  ) async {
    await super.onRedirect(context, route, state);

    return (route == redirectTo) ? null : redirectTo;
  }
}

/// Builds the state the router gives to a redirection.
GoRouterState _aState(FakeRoute route) => GoRouterState(
  RouteConfiguration(
    ValueNotifier(
      RoutingConfig(
        routes: [GoRoute(path: "/home", builder: (context, state) => const SizedBox())],
      ),
    ),
    navigatorKey: GlobalKey<NavigatorState>(),
  ),
  uri: Uri.parse(route.path),
  matchedLocation: route.path,
  fullPath: route.path,
  pathParameters: const {},
  pageKey: ValueKey(route.name),
  name: route.name,
);

/// A context the redirection of the test does not read.
class _FakeContext extends StatelessElement {
  /// Class constructor
  _FakeContext() : super(const _FakeWidget());
}

/// The widget of the context the redirection of the test does not read.
class _FakeWidget extends StatelessWidget {
  /// Class constructor
  const _FakeWidget();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
