// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_cognito/src/cognito_password_service.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_cognito.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeExternalLogger logs;
  late FakeAuthPlugin cloud;
  late CognitoPasswordService service;

  setUp(() async {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    cloud = await FakeAuthPlugin.install();
    service = CognitoPasswordService(logsHelper: logs.buildHelper(category: "cognito"));
    await service.initLifeCycle();
  });

  tearDown(() async {
    await service.disposeLifeCycle();
    await Amplify.reset();
  });

  group("CognitoPasswordService.resetPassword", () {
    test("asks the pool to send the code a user resets a password with", () async {
      final result = await service.resetPassword(username: "a user");

      expect(result.status, AuthResetPwdStatus.done);
      expect(cloud.argumentsOf("resetPassword"), {"username": "a user"});
    });

    test("says that the device is not online when the cloud cannot be reached", () async {
      cloud.exception = const NetworkException("no network");

      final result = await service.resetPassword(username: "a user");

      expect(result.status, AuthResetPwdStatus.networkError);
      expect(result.extra, cloud.exception);
    });

    test("says that anything else the cloud refused is an error", () async {
      cloud.exception = const UserNotFoundException("User does not exist");

      final result = await service.resetPassword(username: "a user");

      expect(result.status, AuthResetPwdStatus.genericError);
    });
  });

  group("CognitoPasswordService.confirmResetPassword", () {
    test("sends the new password and the code the user read", () async {
      final result = await service.confirmResetPassword(
        username: "a user",
        newPassword: "a new password",
        confirmationCode: "123456",
      );

      expect(result.status, AuthResetPwdStatus.done);
      expect(cloud.argumentsOf("confirmResetPassword"), {
        "username": "a user",
        "newPassword": "a new password",
        "confirmationCode": "123456",
      });
    });

    test("says that the code the user read is not the one the pool sent", () async {
      cloud.exception = const CodeMismatchException("Invalid verification code provided");

      final result = await service.confirmResetPassword(
        username: "a user",
        newPassword: "a new password",
        confirmationCode: "000000",
      );

      expect(result.status, AuthResetPwdStatus.wrongConfirmationCode);
    });

    test("says that the new password does not follow the rules of the pool", () async {
      cloud.exception = const InvalidPasswordException("password too short");

      final result = await service.confirmResetPassword(
        username: "a user",
        newPassword: "short",
        confirmationCode: "123456",
      );

      expect(result.status, AuthResetPwdStatus.newPasswordNotConform);
    });
  });

  group("CognitoPasswordService.updatePassword", () {
    test("sends the password the user had and the one it chose", () async {
      final result = await service.updatePassword(
        oldPassword: "a password",
        newPassword: "a new password",
      );

      expect(result.status, AuthResetPwdStatus.done);
      expect(cloud.argumentsOf("updatePassword"), {
        "oldPassword": "a password",
        "newPassword": "a new password",
      });
    });

    test("says that the password the user gave is not the one it had", () async {
      cloud.exception = const NotAuthorizedServiceException("Incorrect username or password");

      final result = await service.updatePassword(
        oldPassword: "a wrong password",
        newPassword: "a new password",
      );

      expect(result.status, AuthResetPwdStatus.wrongUsernameOrPwd);
    });

    test("says that the new password does not follow the rules of the pool", () async {
      cloud.exception = const InvalidPasswordException("password too short");

      final result = await service.updatePassword(oldPassword: "a password", newPassword: "short");

      expect(result.status, AuthResetPwdStatus.newPasswordNotConform);
    });
  });
}
