// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth.dart';

void main() {
  late FakeAuthService native;
  late FakeAuthService external;

  setUp(() {
    FakeGlobalManager.install();
    native = FakeAuthService();
    external = FakeAuthService();
  });

  tearDown(() async {
    await native.close();
    await external.close();
  });

  /// Builds the service of an application which offers [providers], and initializes it.
  Future<FakeMultiAuthService> aService({
    required Map<FakeProviders, MixinAuthService> providers,
    FakeProviders? currentProvider,
  }) async {
    final service = FakeMultiAuthService(providers: providers, currentProvider: currentProvider);
    await service.initLifeCycle();
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  group("SimpleMultiAuthService.initLifeCycle", () {
    test("signs the user in through the provider it was told to start with", () async {
      final service = await aService(
        providers: {FakeProviders.native: native, FakeProviders.external: external},
        currentProvider: FakeProviders.external,
      );

      expect(service.chosenProvider, FakeProviders.external);
    });

    test("signs the user in through the only provider of the application", () async {
      final service = await aService(providers: {FakeProviders.native: native});

      expect(service.chosenProvider, FakeProviders.native);
    });

    test("waits for the user to choose when the application offers several providers", () async {
      final service = await aService(
        providers: {FakeProviders.native: native, FakeProviders.external: external},
      );

      expect(service.chosenProvider, isNull);
    });
  });
}
