// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Characteristic's scope
enum CharacteristicScope {
  readWrite,
  readOnly,
  writeOnly,
}

/// Characteristic enum
abstract class AbstractCharacteristicInfo {
  final String name;
  final String uuid;
  final CharacteristicScope scope;
  final Type? receiveType;
  final Type? sendType;

  /// Say if the characteristic may notify and can be subscribed
  bool get hasNotification => false;

  const AbstractCharacteristicInfo({
    required this.name,
    required this.uuid,
    required this.scope,
    this.receiveType,
    this.sendType,
  });
}
