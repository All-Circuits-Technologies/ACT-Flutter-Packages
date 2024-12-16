// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The ids of the OCSIGEN requests
enum OcsigenRequestId {
  setGpsCoordinates(hexValue: 0xF5, requestType: HaloRequestType.function),
  getSerialNumber(hexValue: 0xF6, requestType: HaloRequestType.function),
  claimDevice(hexValue: 0xF7, requestType: HaloRequestType.function),
  wiFiSsidScan(hexValue: 0xF8, requestType: HaloRequestType.function),
  wiFiCompleteScan(hexValue: 0xF9, requestType: HaloRequestType.function),
  wiFiConnect(hexValue: 0xFA, requestType: HaloRequestType.function),
  wiFiDisconnect(hexValue: 0xFB, requestType: HaloRequestType.function),
  wiFiGetStatus(hexValue: 0xFC, requestType: HaloRequestType.function),
  wiFiGetMacAddress(hexValue: 0xFD, requestType: HaloRequestType.function),
  apWifiEnable(hexValue: 0xFE, requestType: HaloRequestType.function),
  echo(hexValue: 0xFF, requestType: HaloRequestType.function);

  /// The hex value linked to the enum
  final int hexValue;

  /// The request type linked to the [OcsigenRequestId]
  final HaloRequestType requestType;

  /// Class constructor
  const OcsigenRequestId({
    required this.hexValue,
    required this.requestType,
  });
}

/// Helpful class to manage [OcsigenRequestId] enum
class OcsigenRequestIdHelper extends AbstractHaloRequestIdHelper {
  /// Class constructor
  ///
  /// [childRequests] contains the requests defined by the derived class, those requests will
  /// overwrite the OCSIGEN requests
  OcsigenRequestIdHelper({
    Map<int, HaloRequestId> childRequests = const {},
  }) : super(
            requestIds:
                _generateOcsigenRequestElement(childRequests: childRequests));

  /// Generate the requests ids linked to OCSIGEN
  static Map<int, HaloRequestId> _generateOcsigenRequestElement({
    required Map<int, HaloRequestId> childRequests,
  }) {
    final elementRequests = <int, HaloRequestId>{};

    for (final ocsigenRequest in OcsigenRequestId.values) {
      final hexValue = ocsigenRequest.hexValue;

      elementRequests[hexValue] = HaloRequestId(
        id: ocsigenRequest.hexValue,
        type: ocsigenRequest.requestType,
      );
    }

    return AbstractHaloRequestIdHelper.mergeRequestElement(
      elementRequests: elementRequests,
      toOverwriteWith: childRequests,
    );
  }
}
