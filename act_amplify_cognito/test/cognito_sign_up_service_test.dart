// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_cognito/src/cognito_sign_up_service.dart';
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
  late CognitoSignUpService service;

  setUp(() async {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    cloud = await FakeAuthPlugin.install();
    service = CognitoSignUpService(logsHelper: logs.buildHelper(category: "cognito"));
    await service.initLifeCycle();
  });

  tearDown(() async {
    await service.disposeLifeCycle();
    await Amplify.reset();
  });

  group("CognitoSignUpService.signUp", () {
    test("registers the user with the account and the password it was given", () async {
      final result = await service.signUp(accountId: "a user", password: "a password");

      expect(result.status, AuthSignUpStatus.done);
      final arguments = cloud.argumentsOf("signUp");
      expect(arguments["username"], "a user");
      expect(arguments["password"], "a password");
    });

    test("sends the email address of the user to the pool", () async {
      await service.signUp(
        accountId: "a user",
        password: "a password",
        email: "a.user@example.com",
      );

      expect(
        cloud.argumentsOf("signUp")["attributes"],
        {AuthUserAttributeKey.email: "a.user@example.com"},
      );
    });

    test("sends no attribute for a user who gave no email address", () async {
      await service.signUp(accountId: "a user", password: "a password");

      expect(cloud.argumentsOf("signUp")["attributes"], isEmpty);
    });

    test("asks the user for the code the pool sent", () async {
      cloud.signUpStep = AuthSignUpStep.confirmSignUp;

      final result = await service.signUp(accountId: "a user", password: "a password");

      expect(result.status, AuthSignUpStatus.confirmSignUpWithCode);
    });

    test("refuses to register a user who gave no account", () async {
      final result = await service.signUp(accountId: "", password: "a password");

      expect(result.status, AuthSignUpStatus.badArgument);
      expect(cloud.calls, isEmpty);
    });

    test("refuses to register a user who gave no password", () async {
      final result = await service.signUp(accountId: "a user", password: "");

      expect(result.status, AuthSignUpStatus.badArgument);
      expect(cloud.calls, isEmpty);
    });

    test("refuses to register a user whose email address is empty", () async {
      final result = await service.signUp(accountId: "a user", password: "a password", email: "");

      expect(result.status, AuthSignUpStatus.badArgument);
      expect(cloud.calls, isEmpty);
    });

    test("says that the account of the user is already taken", () async {
      cloud.exception = const UsernameExistsException("User already exists");

      final result = await service.signUp(accountId: "a user", password: "a password");

      expect(result.status, AuthSignUpStatus.accountIdentifierConflict);
    });

    test("says that the password does not follow the rules of the pool", () async {
      cloud.exception = const InvalidPasswordException("password too short");

      final result = await service.signUp(accountId: "a user", password: "short");

      expect(result.status, AuthSignUpStatus.passwordNotConform);
    });

    test("says that the device is not online when the cloud cannot be reached", () async {
      cloud.exception = const NetworkException("no network");

      final result = await service.signUp(accountId: "a user", password: "a password");

      expect(result.status, AuthSignUpStatus.networkError);
      expect(result.extra, cloud.exception);
    });
  });

  group("CognitoSignUpService.confirmSignUp", () {
    test("sends the code the user read", () async {
      final result = await service.confirmSignUp(accountId: "a user", code: "123456");

      expect(result.status, AuthSignUpStatus.done);
      expect(cloud.argumentsOf("confirmSignUp"), {
        "username": "a user",
        "confirmationCode": "123456",
      });
    });

    test("refuses to confirm without an account or a code", () async {
      expect(
        (await service.confirmSignUp(accountId: "", code: "123456")).status,
        AuthSignUpStatus.badArgument,
      );
      expect(
        (await service.confirmSignUp(accountId: "a user", code: "")).status,
        AuthSignUpStatus.badArgument,
      );
      expect(cloud.calls, isEmpty);
    });

    test("says that the code the user read is not the one the pool sent", () async {
      cloud.exception = const CodeMismatchException("Invalid verification code provided");

      final result = await service.confirmSignUp(accountId: "a user", code: "000000");

      expect(result.status, AuthSignUpStatus.wrongConfirmationCode);
    });

    test("says that the email address of the user is already taken", () async {
      cloud.exception = const AliasExistsException("An account with the email already exists");

      final result = await service.confirmSignUp(accountId: "a user", code: "123456");

      expect(result.status, AuthSignUpStatus.accountPropertyConflict);
    });
  });

  group("CognitoSignUpService.resendSignUpCode", () {
    test("asks the pool to send the code again, and says that it did", () async {
      final result = await service.resendSignUpCode(accountId: "a user");

      expect(result.status, AuthSignUpStatus.confirmSignUpWithCode);
      expect(result.extra, isA<AuthCodeDeliveryDetails>());
      expect(cloud.argumentsOf("resendSignUpCode"), {"username": "a user"});
    });

    test("says that the device is not online when the cloud cannot be reached", () async {
      cloud.exception = const NetworkException("no network");

      final result = await service.resendSignUpCode(accountId: "a user");

      expect(result.status, AuthSignUpStatus.networkError);
    });
  });
}
