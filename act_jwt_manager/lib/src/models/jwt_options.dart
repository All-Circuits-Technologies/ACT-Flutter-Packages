// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:equatable/equatable.dart';

/// Contains the options to use with the JWT
class JwtOptions extends Equatable {
  /// The algorithm linked to the JWT to create or verify
  final JWTAlgorithm algorithm;

  /// The audience linked to the JWT to create or verify
  final Audience? audience;

  /// The issuer linked to the JWT to create or verify
  final String? issuer;

  /// The subject linked to the JWT to create or verify
  final String? subject;

  /// The expiration time linked to the JWT to create or verify
  final Duration? expirationTime;

  /// The JWT won't be valid until the [notBefore] duration is raised
  /// cantUseUntilThisDate = now() + [notBefore]
  final Duration? notBefore;

  /// Class constructor
  const JwtOptions({
    required this.algorithm,
    this.audience,
    this.issuer,
    this.subject,
    this.expirationTime,
    this.notBefore,
  });

  @override
  List<Object?> get props => [
        algorithm,
        audience,
        issuer,
        subject,
        expirationTime,
        notBefore,
      ];
}
