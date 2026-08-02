// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth.dart';

void main() {
  late FakeAuthService native;
  late FakeAuthService external;

  setUp(() {
    FakeGlobalManager.install();
    native = FakeAuthService();
    external = FakeAuthService();
  });

  tearDown(() async {
    await native.close();
    await external.close();
  });

  /// Builds the service of an application which offers two providers, and initializes it.
  ///
  /// The user signs in through [currentProvider], or through none of them when the test gives
  /// none, which is what an application looks like before the user chose.
  Future<FakeMultiAuthService> aService({FakeProviders? currentProvider}) async {
    final service = FakeMultiAuthService(
      providers: {FakeProviders.native: native, FakeProviders.external: external},
      currentProvider: currentProvider,
    );
    await service.initLifeCycle();
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  group("MixinMultiAuthService.authStatus", () {
    test("answers with the status of the provider the user signs in through", () async {
      native.updateStatus(AuthStatus.signedIn);
      final service = await aService(currentProvider: FakeProviders.native);

      expect(service.authStatus, AuthStatus.signedIn);
    });

    test("holds the user for signed out while no provider is chosen", () async {
      native.updateStatus(AuthStatus.signedIn);
      final service = await aService();

      expect(service.authStatus, AuthStatus.signedOut);
    });
  });

  group("MixinMultiAuthService.authStatusStream", () {
    test("tells the application about the status of the chosen provider", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      final statuses = <AuthStatus>[];
      final subscription = service.authStatusStream.listen(statuses.add);
      addTearDown(subscription.cancel);

      native.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(statuses, [AuthStatus.signedIn]);
    });

    test("says nothing of the providers the user did not choose", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      final statuses = <AuthStatus>[];
      final subscription = service.authStatusStream.listen(statuses.add);
      addTearDown(subscription.cancel);

      external.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(statuses, isEmpty);
    });

    test("stops telling the application about a provider the user left", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      final statuses = <AuthStatus>[];
      final subscription = service.authStatusStream.listen(statuses.add);
      addTearDown(subscription.cancel);

      await service.chooseProvider(FakeProviders.external);
      native.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(statuses, isEmpty);
    });
  });

  group("MixinMultiAuthService.setStorageService", () {
    test("hands the storage to the provider the user signs in through", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      final storage = FakeAuthStorageService();

      await service.setStorageService(storage);

      expect(native.storageService, storage);
      expect(external.storageService, isNull);
    });

    test("keeps the storage for the provider the user chooses later", () async {
      final service = await aService();
      final storage = FakeAuthStorageService();
      await service.setStorageService(storage);

      await service.chooseProvider(FakeProviders.external);

      expect(external.storageService, storage);
    });

    test("hands the storage only once", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      final storage = FakeAuthStorageService();
      await service.setStorageService(storage);
      native.calls.clear();

      await service.setStorageService(storage);

      expect(native.calls, isEmpty);
    });
  });

  group("MixinMultiAuthService.setCurrentProviderKey", () {
    test("takes the storage away from the provider the user left", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      await service.setStorageService(FakeAuthStorageService());

      await service.chooseProvider(FakeProviders.external);

      expect(native.storageService, isNull);
    });

    test("clears what the provider the user left kept", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      final storage = FakeAuthStorageService();
      await service.setStorageService(storage);
      await storage.storeTokens(
        tokens: const AuthTokens(accessToken: AuthToken(raw: "a token")),
      );
      await storage.storeUserIds(username: "a user", password: "a password");

      await service.chooseProvider(FakeProviders.external);

      expect(storage.storedTokens, isNull);
      expect(storage.storedUserIds, isNull);
    });

    test("leaves the identifiers alone in a storage which keeps none", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      final storage = FakeAuthStorageService(userIdsSupported: false);
      await service.setStorageService(storage);
      storage.calls.clear();

      await service.chooseProvider(FakeProviders.external);

      expect(storage.calls, isNot(contains("clearUserIds()")));
    });

    test("does nothing when the user chooses the provider they already sign in through", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      await service.setStorageService(FakeAuthStorageService());
      native.calls.clear();

      await service.chooseProvider(FakeProviders.native);

      expect(native.calls, isEmpty);
    });
  });

  group("MixinMultiAuthService", () {
    test("signs the user in through the provider they chose while signing in", () async {
      final service = await aService();

      await service.signInUser(
        username: "a user",
        password: "a password",
        providerKey: FakeProviders.external,
      );

      expect(service.chosenProvider, FakeProviders.external);
      expect(external.calls, contains("signInUser(a user)"));
    });

    test("redirects the sign in to the provider the user chose", () async {
      final service = await aService();

      await service.redirectToExternalUserSignIn(providerKey: FakeProviders.external);

      expect(external.calls, contains("redirectToExternalUserSignIn()"));
    });

    test("hands every call to the provider the user signs in through", () async {
      final service = await aService(currentProvider: FakeProviders.native);

      await service.signUp(accountId: "a user", password: "a password");
      await service.confirmSignUp(accountId: "a user", code: "1234");
      await service.resendSignUpCode(accountId: "a user");
      await service.signInUser(username: "a user", password: "a password");
      await service.confirmSignIn(confirmationValue: "1234");
      await service.signOut();
      await service.isUserSigned();
      await service.getCurrentUserId();
      await service.getTokens();
      await service.resetPassword(username: "a user");
      await service.confirmResetPassword(
        username: "a user",
        newPassword: "a password",
        confirmationCode: "1234",
      );
      await service.updatePassword(oldPassword: "old", newPassword: "new");
      await service.getEmailAddress();
      await service.setEmailAddress("a@host");
      await service.confirmEmailAddressUpdate(code: "1234");
      await service.deleteAccount();

      expect(native.calls, [
        "signUp(a user)",
        "confirmSignUp(a user, 1234)",
        "resendSignUpCode(a user)",
        "signInUser(a user)",
        "confirmSignIn(1234)",
        "signOut()",
        "isUserSigned()",
        "getCurrentUserId()",
        "getTokens()",
        "resetPassword(a user)",
        "confirmResetPassword(a user, 1234)",
        "updatePassword()",
        "getEmailAddress()",
        "setEmailAddress(a@host)",
        "confirmEmailAddressUpdate(1234)",
        "deleteAccount()",
      ]);
      expect(external.calls, isEmpty);
    });

    test("answers an error to every call made before the user chose a provider", () async {
      final service = await aService();

      expect(
        (await service.signUp(accountId: "a user", password: "a password")).status,
        AuthSignUpStatus.genericError,
      );
      expect(
        (await service.confirmSignUp(accountId: "a user", code: "1234")).status,
        AuthSignUpStatus.genericError,
      );
      expect(
        (await service.resendSignUpCode(accountId: "a user")).status,
        AuthSignUpStatus.genericError,
      );
      expect(
        (await service.signInUser(username: "a user", password: "a password")).status,
        AuthSignInStatus.genericError,
      );
      expect(
        (await service.confirmSignIn(confirmationValue: "1234")).status,
        AuthSignInStatus.genericError,
      );
      expect((await service.redirectToExternalUserSignIn()).status, AuthSignInStatus.genericError);
      expect(
        (await service.resetPassword(username: "a user")).status,
        AuthResetPwdStatus.genericError,
      );
      expect(
        (await service.updatePassword(oldPassword: "old", newPassword: "new")).status,
        AuthResetPwdStatus.genericError,
      );
      expect((await service.setEmailAddress("a@host")).status, AuthPropertyStatus.genericError);
      expect(
        (await service.confirmEmailAddressUpdate(code: "1234")).status,
        AuthPropertyStatus.genericError,
      );
      expect((await service.deleteAccount()).status, AuthDeleteStatus.genericError);
    });

    test("answers nothing to the questions asked before the user chose a provider", () async {
      final service = await aService();

      expect(await service.signOut(), isFalse);
      expect(await service.isUserSigned(), isFalse);
      expect(await service.getCurrentUserId(), isNull);
      expect(await service.getTokens(), isNull);
      expect(await service.getEmailAddress(), isNull);
      expect(native.calls, isEmpty);
      expect(external.calls, isEmpty);
    });

    test("answers an error when the chosen provider is not one it knows", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      await service.forgetProviders();
      await service.chooseProvider(FakeProviders.native);

      expect(await service.isUserSigned(), isFalse);
    });
  });

  group("MixinMultiAuthService.disposeLifeCycle", () {
    test("forgets the providers of the application", () async {
      final service = await aService(currentProvider: FakeProviders.native);

      await service.disposeLifeCycle();

      expect(service.chosenProvider, isNull);
    });

    test("stops following the providers of the application", () async {
      final service = await aService(currentProvider: FakeProviders.native);
      final statuses = <AuthStatus>[];
      final subscription = service.authStatusStream.listen(statuses.add);
      addTearDown(subscription.cancel);

      await service.disposeLifeCycle();
      native.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(statuses, isEmpty);
    });
  });
}
