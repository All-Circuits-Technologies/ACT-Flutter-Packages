// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// This enum contains the restricted statuses linked to the end of a communication.
///
/// Those statuses have special meanings for the device.
///
/// This enum is useful when you don't want to define other statuses in your project.
/// If you want to define other statuses (outside the defined raw values) you can do it on your own
/// enum, but don't forget to include the restricted elements.
enum RestrictedEndComStatus with MixinHaloType {
  endComOk(rawValue: 0x00),
  endComGenericError(rawValue: 0xFF);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// Enum values
  const RestrictedEndComStatus({required this.rawValue});
}
