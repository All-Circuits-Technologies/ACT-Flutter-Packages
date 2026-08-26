// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_flutter_utility/src/widget/banner_info/banner_info_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a banner of the given [type], whose text says which one it is.
BannerInformationModel _aBanner(BannerInformationType type) => BannerInformationModel(
  type: type,
  text: type.name,
  foregroundColor: Colors.white,
  backgroundColor: Colors.black,
);

/// The banner shown when the device has no internet connection.
final _internetBanner = _aBanner(BannerInformationType.warning);

/// The texts of [banners], in the order they are shown.
List<String> _textsOf(List<BannerInformationModel> banners) =>
    banners.map((banner) => banner.text).toList();

void main() {
  group("BannerInfoState.getBanners", () {
    test("shows the banners of the page from the most to the least important", () {
      const state = BannerInfoState.init();

      final banners = state.getBanners(
        internetBannerInfoModel: null,
        knownBanners: [
          _aBanner(BannerInformationType.info),
          _aBanner(BannerInformationType.error),
          _aBanner(BannerInformationType.debug),
        ],
      );

      expect(_textsOf(banners), ["error", "info", "debug"]);
    });

    test("shows nothing when the page has no banner", () {
      const state = BannerInfoState.init();

      expect(state.getBanners(internetBannerInfoModel: null, knownBanners: []), isEmpty);
    });

    test("hides the internet banner while the connection is there", () {
      const state = BannerInfoState.init();

      final banners = state.getBanners(internetBannerInfoModel: _internetBanner, knownBanners: []);

      expect(banners, isEmpty);
    });

    test("shows the internet banner once the connection is lost", () {
      const state = BannerInfoState(isInternetOk: false);

      final banners = state.getBanners(internetBannerInfoModel: _internetBanner, knownBanners: []);

      expect(_textsOf(banners), ["warning"]);
    });

    test("weighs the internet banner against the banners of the page", () {
      const state = BannerInfoState(isInternetOk: false);

      final banners = state.getBanners(
        internetBannerInfoModel: _internetBanner,
        knownBanners: [_aBanner(BannerInformationType.error), _aBanner(BannerInformationType.info)],
      );

      expect(_textsOf(banners), ["error", "warning", "info"]);
    });

    test("shows the banners of a page which has no internet banner", () {
      const state = BannerInfoState(isInternetOk: false);

      final banners = state.getBanners(
        internetBannerInfoModel: null,
        knownBanners: [_aBanner(BannerInformationType.info)],
      );

      expect(_textsOf(banners), ["info"]);
    });
  });

  group("BannerInfoState.copyWithInternetState", () {
    test("keeps the state the connection it is given", () {
      const state = BannerInfoState.init();

      expect(state.copyWithInternetState(isInternetOk: false).isInternetOk, isFalse);
    });
  });
}
