// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:equatable/equatable.dart';

/// This object contains the user ids and it's used to store them in the secure local storage.
class AuthUserIds extends Equatable {
  /// This is the key used to stringify or parse the username from a JSON object
  static const _usernameKey = "username";

  /// This is the key used to stringify or parse the password from a JSON object
  static const _passwordKey = "password";

  /// The stored username
  final String username;

  /// The stored password
  final String password;

  /// Class constructor
  const AuthUserIds({required this.username, required this.password});

  /// Transform the current object to a JSON object
  Map<String, dynamic> toJson() => {_usernameKey: username, _passwordKey: password};

  /// Parse a JSON object to create a [AuthUserIds]
  static AuthUserIds? fromJson(Map<String, dynamic> json) {
    final username = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _usernameKey,
      loggerManager: appLogger(),
    );

    final password = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _passwordKey,
      loggerManager: appLogger(),
    );

    if (username == null || password == null) {
      appLogger().w(
        "A problem occurred when tried to get the authentication user ids from the given JSON",
      );
      return null;
    }

    return AuthUserIds(username: username, password: password);
  }

  /// Object properties
  @override
  List<Object?> get props => [username, password];
}
