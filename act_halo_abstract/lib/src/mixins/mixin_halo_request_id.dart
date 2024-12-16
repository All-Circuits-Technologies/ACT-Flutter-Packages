// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// Defines the id of the HALO requests
mixin MixinHaloRequestId on MixinHaloType {
  /// The type of request
  HaloRequestType get type;

  /// The ids of function, procedure and order requests aren't unique between each others.
  ///
  /// This function is useful to return an id unique to all the request types
  int get uniqueId => ByteUtility.unsafeConvertFromLsb(
        lsbNumber: Uint8List.fromList([
          type.rawValue,
          rawValue,
        ]),
        isSigned: false,
      );
}
