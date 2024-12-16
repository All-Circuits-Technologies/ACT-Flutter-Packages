// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Contains the sign result
class SignResult extends Equatable {
  /// This is the expiration time of the JWT created
  final Duration expirationTime;

  /// The json web token
  final String jwt;

  /// Class constructor
  const SignResult({required this.expirationTime, required this.jwt});

  @override
  List<Object?> get props => [expirationTime, jwt];
}
