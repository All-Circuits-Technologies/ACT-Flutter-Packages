import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:equatable/equatable.dart';

class AuthUserIds extends Equatable {
  static const _usernameKey = "username";

  static const _passwordKey = "password";

  final String username;

  final String password;

  const AuthUserIds({required this.username, required this.password});

  Map<String, dynamic> toJson() => {_usernameKey: username, _passwordKey: password};

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

  @override
  List<Object?> get props => [username, password];
}
