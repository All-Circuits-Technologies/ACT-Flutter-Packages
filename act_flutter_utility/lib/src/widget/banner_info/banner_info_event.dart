// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// Emitted when the internet status has been updated
class BannerInfoInternetUpdateEvent extends BlocEventForMixin {
  /// True if the internet connectivity is ok
  final bool isInternetOk;

  /// Class constructor
  const BannerInfoInternetUpdateEvent({
    required this.isInternetOk,
  });

  /// This is the event properties
  @override
  List<Object?> get props => [...super.props, isInternetOk];
}
