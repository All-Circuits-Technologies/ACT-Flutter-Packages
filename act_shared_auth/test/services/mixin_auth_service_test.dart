// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth.dart';

void main() {
  late BareAuthService service;

  setUp(() => service = BareAuthService());

  group("MixinAuthService.storageService", () {
    test("keeps nothing for a service which was given no storage", () {
      expect(service.storageService, isNull);
    });

    test("accepts a storage a service does nothing with", () async {
      await expectLater(service.setStorageService(FakeAuthStorageService()), completes);
    });
  });

  group("MixinAuthService", () {
    // The assertions are enabled when the tests are run, so the trap of the mixin fires the
    // assertion it guards the release behaviour with.
    test("crashes when the sign up is asked of a service which does not support it", () {
      expect(
        () => service.signUp(accountId: "a user", password: "a password"),
        throwsAssertionError,
      );
    });

    test("crashes when the sign up confirmation is asked of a service which lacks it", () {
      expect(() => service.confirmSignUp(accountId: "a user", code: "1234"), throwsAssertionError);
    });

    test("crashes when a new sign up code is asked of a service which lacks it", () {
      expect(() => service.resendSignUpCode(accountId: "a user"), throwsAssertionError);
    });

    test("crashes when the sign in confirmation is asked of a service which lacks it", () {
      expect(() => service.confirmSignIn(confirmationValue: "1234"), throwsAssertionError);
    });

    test("crashes when an external sign in is asked of a service which lacks it", () {
      expect(service.redirectToExternalUserSignIn, throwsAssertionError);
    });

    test("crashes when the user identifier is asked of a service which lacks it", () {
      expect(service.getCurrentUserId, throwsAssertionError);
    });

    test("crashes when the tokens are asked of a service which lacks them", () {
      expect(service.getTokens, throwsAssertionError);
    });

    test("crashes when a password reset is asked of a service which lacks it", () {
      expect(() => service.resetPassword(username: "a user"), throwsAssertionError);
    });

    test("crashes when a password reset confirmation is asked of a service which lacks it", () {
      expect(
        () => service.confirmResetPassword(
          username: "a user",
          newPassword: "a password",
          confirmationCode: "1234",
        ),
        throwsAssertionError,
      );
    });

    test("crashes when a password change is asked of a service which lacks it", () {
      expect(
        () => service.updatePassword(oldPassword: "old", newPassword: "new"),
        throwsAssertionError,
      );
    });

    test("crashes when the email address is asked of a service which lacks it", () {
      expect(service.getEmailAddress, throwsAssertionError);
    });

    test("crashes when an email address change is asked of a service which lacks it", () {
      expect(() => service.setEmailAddress("a@host"), throwsAssertionError);
    });

    test("crashes when an email address confirmation is asked of a service which lacks it", () {
      expect(() => service.confirmEmailAddressUpdate(code: "1234"), throwsAssertionError);
    });

    test("crashes when the deletion of the account is asked of a service which lacks it", () {
      expect(service.deleteAccount, throwsAssertionError);
    });
  });
}
