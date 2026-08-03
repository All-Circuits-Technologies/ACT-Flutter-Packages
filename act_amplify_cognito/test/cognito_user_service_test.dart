// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_cognito/src/cognito_user_service.dart';
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
  late CognitoUserService service;

  setUp(() async {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    cloud = await FakeAuthPlugin.install();
    service = CognitoUserService(logsHelper: logs.buildHelper(category: "cognito"));
    await service.initLifeCycle();
  });

  tearDown(() async {
    await service.disposeLifeCycle();
    await Amplify.reset();
  });

  group("CognitoUserService.isUserSigned", () {
    test("says that the user of a session which is open is signed in", () async {
      expect(await service.isUserSigned(), isTrue);
    });

    test("says that the user of a session which is closed is not signed in", () async {
      cloud.isSignedIn = false;

      expect(await service.isUserSigned(), isFalse);
    });

    test("says that a user whose session cannot be read is not signed in", () async {
      cloud.exception = const SignedOutException("no session");

      expect(await service.isUserSigned(), isFalse);
    });
  });

  group("CognitoUserService.getEmailAddress", () {
    test("reads the address of the user among its attributes", () async {
      cloud.attributes = const [
        AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.name, value: "a name"),
        AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          value: "a.user@example.com",
        ),
      ];

      expect(await service.getEmailAddress(), "a.user@example.com");
    });

    test("reads nothing for a user whose attributes carry no address", () async {
      cloud.attributes = const [
        AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.name, value: "a name"),
      ];

      expect(await service.getEmailAddress(), isNull);
    });

    test("reads nothing when the attributes cannot be read", () async {
      cloud.exception = const SignedOutException("no session");

      expect(await service.getEmailAddress(), isNull);
    });
  });

  group("CognitoUserService.setEmailAddress", () {
    test("sends the address the user chose", () async {
      final result = await service.setEmailAddress("a.user@example.com");

      expect(result.status, AuthPropertyStatus.done);
      expect(cloud.argumentsOf("updateUserAttribute"), {
        "key": AuthUserAttributeKey.email,
        "value": "a.user@example.com",
      });
    });

    test("asks the user for the code the pool sent to the new address", () async {
      cloud.updateAttributeStep = AuthUpdateAttributeStep.confirmAttributeWithCode;

      final result = await service.setEmailAddress("a.user@example.com");

      expect(result.status, AuthPropertyStatus.confirmWithCode);
      expect(result.extra, isA<UpdateUserAttributeResult>());
    });

    test("refuses an address which would clear the one of the user", () async {
      await expectLater(() => service.setEmailAddress("  "), throwsAssertionError);
      expect(cloud.calls, isEmpty);
    });

    test("says that the address is already the one of another user", () async {
      cloud.exception = const AliasExistsException("An account with the email already exists");

      final result = await service.setEmailAddress("a.user@example.com");

      expect(result.status, AuthPropertyStatus.accountPropertyConflict);
    });

    test("says that the address is not one the pool takes", () async {
      cloud.exception = const InvalidParameterException("Invalid email address format");

      final result = await service.setEmailAddress("not an address");

      expect(result.status, AuthPropertyStatus.badArgument);
    });

    test("says that the device is not online when the cloud cannot be reached", () async {
      cloud.exception = const NetworkException("no network");

      final result = await service.setEmailAddress("a.user@example.com");

      expect(result.status, AuthPropertyStatus.networkError);
    });
  });

  group("CognitoUserService.confirmEmailAddressUpdate", () {
    test("sends the code the user read", () async {
      final result = await service.confirmEmailAddressUpdate(code: "123456");

      expect(result.status, AuthPropertyStatus.done);
      expect(cloud.argumentsOf("confirmUserAttribute"), {
        "key": AuthUserAttributeKey.email,
        "confirmationCode": "123456",
      });
    });

    test("says that the code the user read is not the one the pool sent", () async {
      cloud.exception = const CodeMismatchException("Invalid verification code provided");

      final result = await service.confirmEmailAddressUpdate(code: "000000");

      expect(result.status, AuthPropertyStatus.wrongConfirmationCode);
    });

    test("says that anything else the cloud refused is an error", () async {
      cloud.exception = const SignedOutException("no session");

      final result = await service.confirmEmailAddressUpdate(code: "123456");

      expect(result.status, AuthPropertyStatus.genericError);
    });
  });

  group("CognitoUserService.getTokens", () {
    test("reads no token from a session which carries none", () async {
      expect(await service.getTokens(), isNull);
    });
  });

  group("CognitoUserService.getCurrentUserId", () {
    test("reads no identity from a session which carries none", () async {
      expect(await service.getCurrentUserId(), isNull);
    });
  });
}
