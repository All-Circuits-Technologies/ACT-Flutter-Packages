// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/widget/banner_info/banner_info_bloc.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_internet_connectivity_manager.dart';

void main() {
  late FakeGlobalManager globalManager;
  late FakeInternetConnectivityManager connectivity;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    await connectivity.disposeLifeCycle();
    await globalManager.reset();
  });

  /// Builds the bloc of a page, on a device whose connection is [hasConnection].
  Future<BannerInfoBloc> aBloc({bool hasConnection = true}) async {
    connectivity = FakeInternetConnectivityManager(hasConnection: hasConnection);
    globalManager.managers.registerSingleton<InternetConnectivityManager>(connectivity);

    final bloc = BannerInfoBloc();
    addTearDown(bloc.close);
    await pumpEventQueue();

    return bloc;
  }

  group("BannerInfoBloc", () {
    test("starts with the connection the manager already knows about", () async {
      final bloc = await aBloc();

      expect(bloc.state.isInternetOk, isTrue);
    });

    test("starts with the loss the manager already knows about", () async {
      final bloc = await aBloc(hasConnection: false);

      expect(bloc.state.isInternetOk, isFalse);
    });

    test("follows the loss of the connection", () async {
      final bloc = await aBloc();

      connectivity.updateConnection(hasConnection: false);
      await pumpEventQueue();

      expect(bloc.state.isInternetOk, isFalse);
    });

    test("follows the connection coming back", () async {
      final bloc = await aBloc(hasConnection: false);

      connectivity.updateConnection(hasConnection: true);
      await pumpEventQueue();

      expect(bloc.state.isInternetOk, isTrue);
    });

    test("stops following the connection once it is closed", () async {
      final bloc = await aBloc();

      await bloc.close();
      connectivity.updateConnection(hasConnection: false);
      await pumpEventQueue();

      expect(bloc.state.isInternetOk, isTrue);
    });
  });
}
