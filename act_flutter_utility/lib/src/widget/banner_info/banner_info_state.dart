// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/models/banner_information_model.dart';
import 'package:equatable/equatable.dart';

/// State of the banner information bloc
abstract class BannerInfoState extends Equatable {
  /// True if the internet connectivity is ok
  final bool isInternetOk;

  /// Class constructor
  BannerInfoState({
    required BannerInfoState previousState,
    bool? isInternetOk,
  }) : isInternetOk = isInternetOk ?? previousState.isInternetOk;

  /// Init class constructor
  const BannerInfoState.init() : isInternetOk = true;

  /// Get the banners to display. This manages the [knownBanners] and the banners added
  /// automatically.
  /// The list returned is sorted from the banner with the highest priority weight to the lowest
  List<BannerInformationModel> getBanners({
    required BannerInformationModel? internetBannerInfoModel,
    required List<BannerInformationModel> knownBanners,
  }) {
    final displayInternetLoose =
        ((internetBannerInfoModel != null) && !isInternetOk);
    final toDisplayBanners = <BannerInformationModel>[];

    if (displayInternetLoose) {
      toDisplayBanners.add(internetBannerInfoModel);
    }

    toDisplayBanners.addAll(knownBanners);

    toDisplayBanners
        .sort((a, b) => b.priorityWeight.compareTo(a.priorityWeight));

    return toDisplayBanners;
  }

  @override
  List<Object?> get props => [isInternetOk];
}

/// Init state
class BannerInfoInitState extends BannerInfoState {
  const BannerInfoInitState() : super.init();
}

/// State linked to internet update
class BannerInfoInternetState extends BannerInfoState {
  BannerInfoInternetState({
    required super.previousState,
    required super.isInternetOk,
  }) : super();
}
