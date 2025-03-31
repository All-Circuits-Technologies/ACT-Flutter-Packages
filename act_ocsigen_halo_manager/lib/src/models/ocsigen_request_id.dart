// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The ids of the OCSIGEN requests
enum OcsigenRequestId with MixinHaloType, MixinHaloRequestId {
  // FUNCTIONS list

  /// This function retrieves the list of WiFi SSIDs saved in the device. The WiFi SSIDs saved are
  /// those to which the device tries to connect when it is within range.
  getSavedWiFi(rawValue: 0xF3, type: HaloRequestType.function),

  /// The function allows you to forget a specific saved WiFi.
  forgetSavedWiFi(rawValue: 0xF4, type: HaloRequestType.function),

  /// This function allows a user to enter the GPS coordinates of the device, if they do not have a
  /// GPS component themselves.
  setGpsCoordinates(rawValue: 0xF5, type: HaloRequestType.function),

  /// This function allows a user to configure the coordinates of a wifi access point saved in
  /// memory. These values are returned to thingsboard
  getSerialNumber(rawValue: 0xF6, type: HaloRequestType.function),

  /// This feature allows a user to claim the Device from Thingsboard. The Device must use the key
  /// given in the parameter as the verification key.
  claimDevice(rawValue: 0xF7, type: HaloRequestType.function),

  /// This function allows you to retrieve the list of SSIDs detected by the Device
  wiFiSsidScan(rawValue: 0xF8, type: HaloRequestType.function),

  /// This function allows you to retrieve the list of SSIDs detected by the Device
  wiFiCompleteScan(rawValue: 0xF9, type: HaloRequestType.function),

  /// The function allows you to ask the Device to connect to a nearby WiFi
  wiFiConnect(rawValue: 0xFA, type: HaloRequestType.function),

  /// The function allows you to ask the Device to disconnect from the WiFi to which it was
  /// connected
  wiFiDisconnect(rawValue: 0xFB, type: HaloRequestType.function),

  /// The function allows you to retrieve the current WiFi status
  wiFiGetStatus(rawValue: 0xFC, type: HaloRequestType.function),

  /// The function allows you to retrieve the MAC address of the WiFi chip used to connect to WiFi
  wiFiGetMacAddress(rawValue: 0xFD, type: HaloRequestType.function),

  /// The function allows you to activate/deactivate the AP on the Device
  apWifiEnable(rawValue: 0xFE, type: HaloRequestType.function),

  /// This function allows you to repeat a value to your interlocutor
  echo(rawValue: 0xFF, type: HaloRequestType.function),

  // PROCEDURES list

  /// This procedure gives a status to the device before ending a communication.
  /// The given parameter value is contextual and linked to a project.
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
