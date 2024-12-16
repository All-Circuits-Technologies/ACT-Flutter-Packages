// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The ids of the OCSIGEN requests
enum OcsigenRequestId with MixinHaloType, MixinHaloRequestId {
  // Functions list
  getSavedWiFi(rawValue: 0xF3, type: HaloRequestType.function),
  forgetSavedWiFi(rawValue: 0xF4, type: HaloRequestType.function),
  setGpsCoordinates(rawValue: 0xF5, type: HaloRequestType.function),
  getSerialNumber(rawValue: 0xF6, type: HaloRequestType.function),
  claimDevice(rawValue: 0xF7, type: HaloRequestType.function),
  wiFiSsidScan(rawValue: 0xF8, type: HaloRequestType.function),
  wiFiCompleteScan(rawValue: 0xF9, type: HaloRequestType.function),
  wiFiConnect(rawValue: 0xFA, type: HaloRequestType.function),
  wiFiDisconnect(rawValue: 0xFB, type: HaloRequestType.function),
  wiFiGetStatus(rawValue: 0xFC, type: HaloRequestType.function),
  wiFiGetMacAddress(rawValue: 0xFD, type: HaloRequestType.function),
  apWifiEnable(rawValue: 0xFE, type: HaloRequestType.function),
  echo(rawValue: 0xFF, type: HaloRequestType.function),

  // Procedure lists
  quitCommunication(rawValue: 0xFF, type: HaloRequestType.procedure);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// The request type linked to the [OcsigenRequestId]
  @override
  final HaloRequestType type;

  /// Class constructor
  const OcsigenRequestId({
    required this.rawValue,
    required this.type,
  });
}

/// Helpful class to manage [OcsigenRequestId] enum
class OcsigenRequestIdHelper extends AbstractHaloRequestIdHelper {
  /// Class constructor
  ///
  /// [childRequests] contains the requests defined by the derived class, those requests will
  /// overwrite the OCSIGEN requests
  OcsigenRequestIdHelper({
    Map<int, MixinHaloRequestId> childRequests = const {},
    super.overriddenExecutionTimeout = const {},
    super.defaultRequestTimeout,
  }) : super(requestIds: _generateOcsigenRequestElement(childRequests: childRequests));

  /// Generate the requests ids linked to OCSIGEN
  static Map<int, MixinHaloRequestId> _generateOcsigenRequestElement({
    required Map<int, MixinHaloRequestId> childRequests,
  }) {
    final elementRequests = <int, MixinHaloRequestId>{};

    for (final ocsigenRequest in OcsigenRequestId.values) {
      final uniqueId = ocsigenRequest.uniqueId;

      elementRequests[uniqueId] = ocsigenRequest;
    }

    return AbstractHaloRequestIdHelper.mergeRequestElement(
      elementRequests: elementRequests,
      toOverwriteWith: childRequests,
    );
  }
}
