// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import "package:act_internet_connectivity_manager/src/platform_deps/internet_test_generic.dart"
    if (dart.library.io) "package:act_internet_connectivity_manager/src/platform_deps/internet_test_io.dart"
    as internet_test;

/// This is the internet test class, used to test if the device is connected to the internet.
sealed class InternetTest {
  /// This method tests if the device is connected to the internet.
  ///
  /// To do so, it requests a distant server and returns true if the distant server responds
  static Future<bool> requestFqdnAndTestIfConnectionOk({
    required String fqdn,
  }) async =>
      internet_test.requestFqdnAndTestIfConnectionOk(fqdn: fqdn);
}
