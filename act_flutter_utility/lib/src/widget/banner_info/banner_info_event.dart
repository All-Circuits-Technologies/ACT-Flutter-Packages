// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// This is the event base for the Banner information bloc
abstract class BannerInfoEvent extends Equatable {
  /// Class constructor
  const BannerInfoEvent();
}

/// Emitted when the internet status has been updated
class BannerInfoInternetUpdateEvent extends BannerInfoEvent {
  /// True if the internet connectivity is ok
  final bool isInternetOk;

  /// Class constructor
  const BannerInfoInternetUpdateEvent({
    required this.isInternetOk,
  });

  @override
  List<Object?> get props => [isInternetOk];
}
