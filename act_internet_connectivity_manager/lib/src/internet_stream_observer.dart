// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';

/// [InternetStreamObserver] is a [StreamObserver] that listens to the internet connection status.
/// Check [StreamObserver] for more information.
class InternetStreamObserver extends StreamObserver<bool> {
  /// Factory constructor to create a [InternetStreamObserver] instance.
  factory InternetStreamObserver() {
    final internetManager = globalGetIt().get<InternetConnectivityManager>();

    bool get() => internetManager.hasConnection;

    return InternetStreamObserver._(
      stream: internetManager.hasInternetStream,
      get: get,
    );
  }

  /// Private class constructor.
  InternetStreamObserver._({
    required super.stream,
    required super.get,
  });

  /// Check if the value received on the stream is valid or not but since the value we listen to is
  /// a boolean, we can directly return it.
  @override
  bool isNewValueValid(bool value) => value;
}
