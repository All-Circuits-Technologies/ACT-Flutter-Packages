// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_internet_connectivity_manager.dart';

/// Builds a banner of the given [type], whose text says which one it is.
BannerInformationModel _aBanner(BannerInformationType type, {Widget? icon, Widget? action}) =>
    BannerInformationModel(
      type: type,
      text: type.name,
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
      icon: icon,
      action: action,
    );

void main() {
  late FakeGlobalManager globalManager;
  late FakeInternetConnectivityManager connectivity;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    await connectivity.disposeLifeCycle();
    await globalManager.reset();
  });

  /// Shows a page holding [banners] above its content, on a device whose connection is
  /// [hasConnection].
  Future<void> aPage(
    WidgetTester tester, {
    List<BannerInformationModel> banners = const [],
    int bannerNbToDisplay = 1,
    BannerInformationModel? internetBannerInfoModel,
    bool hasConnection = true,
  }) async {
    connectivity = FakeInternetConnectivityManager(hasConnection: hasConnection);
    globalManager.managers.registerSingleton<InternetConnectivityManager>(connectivity);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BannerInformationDisplay(
            banners: banners,
            bannerNbToDisplay: bannerNbToDisplay,
            internetBannerInfoModel: internetBannerInfoModel,
            child: const Text("the page"),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group("BannerInformationDisplay", () {
    testWidgets("shows the page alone when it has no banner to show", (tester) async {
      await aPage(tester);

      expect(find.text("the page"), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets("shows the banner of the page above it", (tester) async {
      await aPage(tester, banners: [_aBanner(BannerInformationType.info)]);

      expect(find.text("the page"), findsOneWidget);
      expect(find.text("info"), findsOneWidget);
    });

    testWidgets("shows the most important banner when it can show only one", (tester) async {
      await aPage(
        tester,
        banners: [_aBanner(BannerInformationType.info), _aBanner(BannerInformationType.error)],
      );

      expect(find.text("error"), findsOneWidget);
      expect(find.text("info"), findsNothing);
    });

    testWidgets("shows as many banners as it was told to", (tester) async {
      await aPage(
        tester,
        banners: [
          _aBanner(BannerInformationType.info),
          _aBanner(BannerInformationType.error),
          _aBanner(BannerInformationType.debug),
        ],
        bannerNbToDisplay: 2,
      );

      expect(find.text("error"), findsOneWidget);
      expect(find.text("info"), findsOneWidget);
      expect(find.text("debug"), findsNothing);
    });

    testWidgets("shows the icon and the action of a banner", (tester) async {
      await aPage(
        tester,
        banners: [
          _aBanner(
            BannerInformationType.info,
            icon: const Icon(Icons.info_outline_rounded),
            action: const Text("dismiss"),
          ),
        ],
      );

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.text("dismiss"), findsOneWidget);
    });

    testWidgets("shows the internet banner once the connection is lost", (tester) async {
      await aPage(
        tester,
        internetBannerInfoModel: _aBanner(BannerInformationType.warning),
        hasConnection: false,
      );

      expect(find.text("warning"), findsOneWidget);
    });

    testWidgets("hides the internet banner while the connection is there", (tester) async {
      await aPage(tester, internetBannerInfoModel: _aBanner(BannerInformationType.warning));

      expect(find.text("warning"), findsNothing);
    });

    testWidgets("shows the internet banner when the connection is lost later", (tester) async {
      await aPage(tester, internetBannerInfoModel: _aBanner(BannerInformationType.warning));

      connectivity.updateConnection(hasConnection: false);
      await tester.pumpAndSettle();

      expect(find.text("warning"), findsOneWidget);
    });

    testWidgets("refuses to show fewer than one banner", (tester) async {
      expect(
        () => BannerInformationDisplay(bannerNbToDisplay: 0, child: const Text("the page")),
        throwsAssertionError,
      );
    });
  });
}
