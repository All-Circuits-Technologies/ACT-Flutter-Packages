// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_manager/act_halo_manager.dart';
import 'package:act_ocsigen_halo_manager/src/features/ocsigen_request_to_device_feature.dart';

/// The ocsigen HALO manager builder
abstract class AbstractOcsigenHaloBuilder<T extends AbstractOcsigenHaloManager>
    extends AbstractHaloBuilder<T> {
  /// The class constructor
  AbstractOcsigenHaloBuilder(super.factory);
}

/// This the HALO manager for the OCSIGEN implementation
abstract class AbstractOcsigenHaloManager<MaterialType> extends AbstractHaloManager<MaterialType> {
  /// Get the requests feature linked to OCSIGEN
  OcsigenRequestToDeviceFeature<MaterialType> get ocsigenRequestToDevice =>
      requestToDeviceFeature as OcsigenRequestToDeviceFeature<MaterialType>;

  /// Class constructor
  AbstractOcsigenHaloManager() : super();

  /// This allows to define a request to device feature linked to the OCSIGEN layer
  @override
  Future<HaloRequestToDeviceFeature<MaterialType>> createRequestToDeviceFeature({
    required HaloManagerConfig<MaterialType> haloManagerConfig,
  }) async =>
      OcsigenRequestToDeviceFeature<MaterialType>(
        haloManagerConfig: haloManagerConfig,
      );
}
