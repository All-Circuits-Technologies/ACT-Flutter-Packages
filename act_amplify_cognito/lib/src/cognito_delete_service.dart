// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This service manages the Cognito account deletion methods
class CognitoDeleteService extends AbstractService {
  /// This is the Cognito service logs helper
  final LogsHelper logsHelper;

  /// Class constructor
  CognitoDeleteService({
    required this.logsHelper,
  }) : super();

  /// Service init method
  @override
  Future<void> initService() async {}

  /// User account deletion entry-point
  ///
  /// Cognito will delete currently logged-in account.
  ///
  /// This may fail for several reason, especially in case of network error.
  Future<AuthDeleteResult> deleteAccount() async {
    try {
      await Amplify.Auth.deleteUser();
    } on AuthException catch (e) {
      logsHelper.e('Error deletion: ${e.message}');
      return AuthDeleteResult(status: _parseException(e), extra: e);
    }

    return const AuthDeleteResult(status: AuthDeleteStatus.done);
  }

  /// AWS API throw upon any error. This method converts those errors into an enum.
  static AuthDeleteStatus _parseException(AuthException exception) => switch (exception) {
        NetworkException _ =>
          // Message example: "The request failed due to a network error."
          // Recovery suggestion example: "Ensure that you have an active network connection"
          AuthDeleteStatus.networkError,
        NotAuthorizedServiceException _ =>
          // ex: "User is disabled"
          // (no recovery suggestion)
          AuthDeleteStatus.genericError,
        UserNotFoundException _ =>
          // ex: "User does not exist"
          // (no recovery suggestion)
          AuthDeleteStatus.genericError,
        _ => AuthDeleteStatus.genericError,
      };
}
