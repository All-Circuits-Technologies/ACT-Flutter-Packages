// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';

/// [ConsentObserverInternet] is a [ConsentObserver] that listens to the internet connection status.
/// Check [ConsentObserver] for more information.
class ConsentObserverInternet extends ConsentObserver<bool> {
  /// Factory constructor to create a [ConsentObserverInternet] instance.
  factory ConsentObserverInternet() {
    final internetManager = globalGetIt().get<InternetConnectivityManager>();

    bool get() => internetManager.hasConnection;

    return ConsentObserverInternet._(
      stream: internetManager.hasInternetStream,
      get: get,
    );
  }

  /// Private class constructor.
  ConsentObserverInternet._({
    required super.stream,
    required super.get,
  });

  /// Check if the value received on the stream is valid or not but since the value we listen to is
  /// a boolean, we can directly return it.
  @override
  bool isNewValueValid(bool value) => value;
}
