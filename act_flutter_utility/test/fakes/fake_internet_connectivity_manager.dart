// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';

/// A connectivity manager whose answers are decided by the test.
///
/// The real manager reaches a host to know whether the device is connected; this one is told, so a
/// test can lose and recover the connection when it wants to.
class FakeInternetConnectivityManager extends InternetConnectivityManager {
  /// The stream the listeners of the manager are fed from.
  final StreamController<bool> _controller;

  /// The connection the manager answers with.
  bool _hasConnection;

  /// Class constructor
  FakeInternetConnectivityManager({bool hasConnection = true})
    : _hasConnection = hasConnection,
      _controller = StreamController<bool>.broadcast(),
      super(configGetter: _noConfiguration);

  /// The manager never reads a configuration, because it never reaches a host.
  static MixinInternetTestConfig _noConfiguration() =>
      throw UnimplementedError("The fake connectivity manager reads no configuration");

  @override
  bool get hasConnection => _hasConnection;

  @override
  Stream<bool> get hasInternetStream => _controller.stream;

  /// Tells the listeners that the connection is now [hasConnection].
  void updateConnection({required bool hasConnection}) {
    _hasConnection = hasConnection;
    _controller.add(hasConnection);
  }

  @override
  Future<void> disposeLifeCycle() async {
    await _controller.close();

    return super.disposeLifeCycle();
  }
}
