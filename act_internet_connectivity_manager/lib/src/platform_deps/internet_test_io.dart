// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

import 'dart:io' show InternetAddress;

import 'package:act_internet_connectivity_manager/src/constants/internet_constants.dart'
    as internet_constants;

/// This method tests if the device is connected to the internet.
///
/// To do so, it requests a distant server and returns true if the distant server responds
Future<bool> requestFqdnAndTestIfConnectionOk({
  required String fqdn,
}) async {
  var connection = false;
  var listAddresses = <InternetAddress>[];

  try {
    listAddresses = await InternetAddress.lookup(fqdn).timeout(internet_constants.requestTimeout);
  } catch (error) {
    // An error occurred
  }

  if (listAddresses.isNotEmpty && listAddresses[0].rawAddress.isNotEmpty) {
    connection = true;
  }

  return connection;
}
