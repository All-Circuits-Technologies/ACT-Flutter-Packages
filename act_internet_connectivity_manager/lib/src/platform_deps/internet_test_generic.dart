// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

import 'package:act_internet_connectivity_manager/src/constants/internet_constants.dart'
    as internet_constants;
import 'package:http/http.dart' as http show head;

/// This method tests if the device is connected to the internet.
///
/// To do so, it requests a distant server and returns true if the distant server responds
Future<bool> requestFqdnAndTestIfConnectionOk({
  required String fqdn,
}) async {
  var connection = false;

  try {
    await http.head(Uri.http(fqdn)).timeout(internet_constants.requestTimeout);
    connection = true;
  } catch (_) {
    // An error occurred
  }

  return connection;
}
