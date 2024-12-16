// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This service manages the interaction with the user currently log in
class CognitoUserService extends AbstractService {
  /// This is the Cognito service logs helper
  final LogsHelper logsHelper;

  /// Class constructor
  CognitoUserService({
    required this.logsHelper,
  }) : super();

  /// Service init method
  @override
  Future<void> initService() async {}

  /// Test if an user is signed to the app (or not)
  Future<bool> isUserSigned() async {
    AuthSession amplifyResult;
    try {
      amplifyResult = await Amplify.Auth.fetchAuthSession();
    } on AuthException catch (e) {
      logsHelper.d("Error retrieving auth session: ${e.message}");
      return false;
    }

    return amplifyResult.isSignedIn;
  }
}
