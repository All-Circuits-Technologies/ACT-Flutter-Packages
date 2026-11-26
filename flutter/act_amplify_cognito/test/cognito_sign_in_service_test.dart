// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_cognito/src/cognito_sign_in_service.dart';
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
  late CognitoSignInService service;

  setUp(() async {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    cloud = await FakeAuthPlugin.install();
    service = CognitoSignInService(logsHelper: logs.buildHelper(category: "cognito"));
    await service.initLifeCycle();
  });

  tearDown(() async {
    await service.disposeLifeCycle();
    await Amplify.reset();
  });

  group("CognitoSignInService.signInUser", () {
    test("signs the user in with the credentials it was given", () async {
      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.done);
      expect(cloud.argumentsOf("signIn"), {"username": "a user", "password": "a password"});
    });

    test("asks for the new password of a user whose password is temporary", () async {
      cloud.signInStep = AuthSignInStep.confirmSignInWithNewPassword;

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.confirmSignInWithNewPassword);
    });

    test("asks the user to confirm the sign up which was never confirmed", () async {
      cloud.signInStep = AuthSignInStep.confirmSignUp;

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.confirmSignUp);
    });

    test("asks the user to reset a password the cloud will not take any more", () async {
      cloud.signInStep = AuthSignInStep.resetPassword;

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.resetPassword);
    });

    test("says that a step which is not supported yet is not supported yet", () async {
      const unsupported = [
        AuthSignInStep.confirmSignInWithSmsMfaCode,
        AuthSignInStep.confirmSignInWithTotpMfaCode,
        AuthSignInStep.continueSignInWithMfaSelection,
        AuthSignInStep.continueSignInWithTotpSetup,
        AuthSignInStep.confirmSignInWithCustomChallenge,
        AuthSignInStep.continueSignInWithMfaSetupSelection,
        AuthSignInStep.continueSignInWithEmailMfaSetup,
        AuthSignInStep.confirmSignInWithOtpCode,
      ];

      for (final step in unsupported) {
        cloud.signInStep = step;

        final result = await service.signInUser(username: "a user", password: "a password");

        expect(result.status, AuthSignInStatus.notSupportedYet, reason: "$step");
      }
    });

    test("says that the device is not online when the cloud cannot be reached", () async {
      cloud.exception = const NetworkException("no network");

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.networkError);
      expect(result.extra, cloud.exception);
    });

    test("says that the credentials are wrong when the cloud refuses them", () async {
      cloud.exception = const NotAuthorizedServiceException("Incorrect username or password");

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.wrongUsernameOrPwd);
    });

    test("tells a session which expired from credentials which are wrong", () async {
      cloud.exception = const NotAuthorizedServiceException("Your session is expired");

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.sessionExpired);
    });

    test("says that a new password does not follow the rules of the pool", () async {
      cloud.exception = const InvalidPasswordException("password too short");

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.newPasswordNotConform);
    });

    test("says that anything else the cloud refused is an error", () async {
      cloud.exception = const UserNotFoundException("User does not exist");

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.genericError);
    });
  });

  group("CognitoSignInService.confirmSignIn", () {
    test("sends the new password of a user whose password was temporary", () async {
      final result = await service.confirmSignIn(confirmationValue: "a new password");

      expect(result.status, AuthSignInStatus.done);
      expect(cloud.argumentsOf("confirmSignIn"), {"confirmationValue": "a new password"});
    });

    test("says that the new password does not follow the rules of the pool", () async {
      cloud.exception = const InvalidPasswordException("password too short");

      final result = await service.confirmSignIn(confirmationValue: "short");

      expect(result.status, AuthSignInStatus.newPasswordNotConform);
    });

    test("says that the session expired while the user was choosing a password", () async {
      cloud.exception = const NotAuthorizedServiceException("Your session is expired");

      final result = await service.confirmSignIn(confirmationValue: "a new password");

      expect(result.status, AuthSignInStatus.sessionExpired);
    });
  });
}
