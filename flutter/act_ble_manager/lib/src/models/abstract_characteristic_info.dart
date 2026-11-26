// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Characteristic's scope
enum CharacteristicScope {
  /// This means that the characteristic can be read and written by the client
  readWrite,

  /// This means that the characteristic can only be read by the client
  readOnly,

  /// This means that the characteristic can only be written by the client
  writeOnly,
}

/// Characteristic enum
abstract class AbstractCharacteristicInfo {
  /// This is the characteristic name
  final String name;

  /// This is the characteristic uuid
  final String uuid;

  /// This is the characteristic scope
  final CharacteristicScope scope;

  /// This is the type of the data received in the characteristic
  final Type? receiveType;

  /// This is the type of the data sent in the characteristic
  final Type? sendType;

  /// Say if the characteristic may notify and can be subscribed
  bool get hasNotification => false;

  /// Class constructor
  const AbstractCharacteristicInfo({
    required this.name,
    required this.uuid,
    required this.scope,
    this.receiveType,
    this.sendType,
  });
}
