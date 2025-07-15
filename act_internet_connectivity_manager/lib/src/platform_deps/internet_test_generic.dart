// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/src/constants/internet_constants.dart'
    as internet_constants;
import 'package:http/http.dart' as http;

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
  } catch (error) {
    // An error occurred
    appLogger().t("An error occurred when tried to test internet: $error");
  }

  return connection;
}
