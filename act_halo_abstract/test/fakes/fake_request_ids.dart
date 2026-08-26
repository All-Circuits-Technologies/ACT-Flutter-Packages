// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The requests of a device, as an application declares them.
enum FakeRequestId with MixinHaloType, MixinHaloRequestId {
  /// A request which returns a value.
  readTemperature(rawValue: 0x01, type: HaloRequestType.function),

  /// A request which returns no value but is acknowledged.
  startHeating(rawValue: 0x02, type: HaloRequestType.procedure),

  /// A request which is neither acknowledged nor answered.
  reboot(rawValue: 0x03, type: HaloRequestType.order),

  /// A request which shares its raw value with another one of another type.
  stopHeating(rawValue: 0x01, type: HaloRequestType.procedure);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// The type of request
  @override
  final HaloRequestType type;

  /// Enum constructor
  const FakeRequestId({required this.rawValue, required this.type});
}

/// The requests of another element of the same device.
enum OtherFakeRequestId with MixinHaloType, MixinHaloRequestId {
  /// A request which returns a value.
  readPressure(rawValue: 0x04, type: HaloRequestType.function),

  /// A request whose unique id collides with the one of [FakeRequestId.readTemperature].
  readTemperature(rawValue: 0x01, type: HaloRequestType.function);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// The type of request
  @override
  final HaloRequestType type;

  /// Enum constructor
  const OtherFakeRequestId({required this.rawValue, required this.type});
}
