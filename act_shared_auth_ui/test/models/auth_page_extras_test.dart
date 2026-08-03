// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_ui/act_shared_auth_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_ui.dart';

void main() {
  group("SignInPageExtra", () {
    test("carries the page to go to and the error which led to the sign in", () {
      const extra = SignInPageExtra<FakeAuthRoute>(
        nextRouteWhenSuccess: FakeAuthRoute.profile,
        previousError: AuthSignInStatus.sessionExpired,
      );

      expect(extra.nextRouteWhenSuccess, FakeAuthRoute.profile);
      expect(extra.previousError, AuthSignInStatus.sessionExpired);
    });

    test("carries nothing for a user who opened the sign in page itself", () {
      const extra = SignInPageExtra<FakeAuthRoute>();

      expect(extra.nextRouteWhenSuccess, isNull);
      expect(extra.previousError, isNull);
    });

    test("is the same extra as another one which carries the same", () {
      expect(
        const SignInPageExtra<FakeAuthRoute>(nextRouteWhenSuccess: FakeAuthRoute.profile),
        const SignInPageExtra<FakeAuthRoute>(nextRouteWhenSuccess: FakeAuthRoute.profile),
      );
    });

    test("is another extra as soon as the page to go to differs", () {
      expect(
        const SignInPageExtra<FakeAuthRoute>(nextRouteWhenSuccess: FakeAuthRoute.profile),
        isNot(const SignInPageExtra<FakeAuthRoute>(nextRouteWhenSuccess: FakeAuthRoute.about)),
      );
    });
  });

  group("SignUpPageExtra", () {
    test("carries the account and the password a form is filled from", () {
      const extra = SignUpPageExtra<FakeAuthRoute>(
        accountId: "a user",
        password: "a password",
        previousError: AuthSignUpStatus.accountIdentifierConflict,
      );

      expect(extra.accountId, "a user");
      expect(extra.password, "a password");
      expect(extra.previousError, AuthSignUpStatus.accountIdentifierConflict);
    });

    test("carries nothing for a user who is registering from the start", () {
      const extra = SignUpPageExtra<FakeAuthRoute>();

      expect(extra.accountId, isNull);
      expect(extra.password, isNull);
    });

    test("is another extra as soon as the account differs", () {
      expect(
        const SignUpPageExtra<FakeAuthRoute>(accountId: "a user"),
        isNot(const SignUpPageExtra<FakeAuthRoute>(accountId: "another user")),
      );
    });
  });

  group("ConfirmSignUpPageExtra", () {
    test("carries the account of the user, which it cannot do without", () {
      const extra = ConfirmSignUpPageExtra<FakeAuthRoute>(
        accountId: "a user",
        password: "a password",
      );

      expect(extra.accountId, "a user");
      expect(extra.password, "a password");
    });

    test("is the extra of a sign up which is being confirmed", () {
      const extra = ConfirmSignUpPageExtra<FakeAuthRoute>(accountId: "a user");

      expect(extra, isA<SignUpPageExtra<FakeAuthRoute>>());
    });
  });

  group("ResetPwdPageExtra", () {
    test("carries the user and the code the password is reset with", () {
      const extra = ResetPwdPageExtra<FakeAuthRoute>(
        username: "a user",
        confirmationCode: "123456",
        nextRouteWhenSuccess: FakeAuthRoute.signIn,
        previousError: AuthResetPwdStatus.wrongConfirmationCode,
      );

      expect(extra.username, "a user");
      expect(extra.confirmationCode, "123456");
      expect(extra.nextRouteWhenSuccess, FakeAuthRoute.signIn);
      expect(extra.previousError, AuthResetPwdStatus.wrongConfirmationCode);
    });

    test("carries no code for a user who has not read one yet", () {
      const extra = ResetPwdPageExtra<FakeAuthRoute>(username: "a user");

      expect(extra.confirmationCode, isNull);
    });

    test("is another extra as soon as the code differs", () {
      expect(
        const ResetPwdPageExtra<FakeAuthRoute>(username: "a user", confirmationCode: "123456"),
        isNot(
          const ResetPwdPageExtra<FakeAuthRoute>(username: "a user", confirmationCode: "000000"),
        ),
      );
    });
  });

  group("MixinAuthRoute", () {
    test("says which pages of an application need a signed in user", () {
      expect(
        FakeAuthRoute.values.where((route) => route.isAuthNeeded),
        [FakeAuthRoute.profile],
      );
    });
  });
}
