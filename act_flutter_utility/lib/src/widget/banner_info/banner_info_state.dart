// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/blocs/bloc_state_for_mixin.dart';
import 'package:act_flutter_utility/src/models/banner_information_model.dart';

/// State of the banner information bloc
class BannerInfoState extends BlocStateForMixin<BannerInfoState> {
  /// True if the internet connectivity is ok
  final bool isInternetOk;

  /// Class constructor
  const BannerInfoState({
    required this.isInternetOk,
  });

  /// Init class constructor
  const BannerInfoState.init() : isInternetOk = true;

  /// {@macro act_flutter_utility.BlocStateForMixin.copyWith}
  @override
  BannerInfoState copyWith({
    bool? isInternetOk,
  }) =>
      BannerInfoState(isInternetOk: isInternetOk ?? this.isInternetOk);

  /// Copy the state with internet update
  BannerInfoState copyWithInternetState({
    required bool isInternetOk,
  }) =>
      copyWith(
        isInternetOk: isInternetOk,
      );

  /// Get the banners to display. This manages the [knownBanners] and the banners added
  /// automatically.
  /// The list returned is sorted from the banner with the highest priority weight to the lowest
  List<BannerInformationModel> getBanners({
    required BannerInformationModel? internetBannerInfoModel,
    required List<BannerInformationModel> knownBanners,
  }) {
    final displayInternetLoose = ((internetBannerInfoModel != null) && !isInternetOk);
    final toDisplayBanners = <BannerInformationModel>[];

    if (displayInternetLoose) {
      toDisplayBanners.add(internetBannerInfoModel);
    }

    toDisplayBanners.addAll(knownBanners);

    toDisplayBanners.sort((a, b) => b.priorityWeight.compareTo(a.priorityWeight));

    return toDisplayBanners;
  }

  @override
  List<Object?> get props => [...super.props, isInternetOk];
}
