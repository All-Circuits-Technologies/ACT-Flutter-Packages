// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_amplify_cognito/act_amplify_cognito.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_cognito.dart';

/// The user the events of the cloud carry.
const _user = AuthUser(userId: "aUserId", username: "a user", signInDetails: _signInDetails);

/// How the user of the events of the cloud signed in.
const _signInDetails = CognitoSignInDetailsApiBased(username: "a user");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeExternalLogger logs;
  late FakeAuthPlugin cloud;
  late StreamController<AuthHubEvent> events;

  setUp(() async {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    cloud = await FakeAuthPlugin.install();

    // The events of the authentication are the ones of Cognito in an application; here they are the
    // ones the test sends.
    events = StreamController<AuthHubEvent>.broadcast();
    Amplify.Hub.addChannel(HubChannel.Auth, events.stream);
  });

  tearDown(() async {
    await events.close();
    Amplify.Hub.close();
    await Amplify.reset();
  });

  /// The Cognito service of an application, over the authentication of the test.
  Future<AmplifyCognitoService> aService() async {
    final service = AmplifyCognitoService();
    await service.initLifeCycle(parentLogsHelper: logs.buildHelper(category: "amplify"));
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  /// Tells the application what the cloud has to say about its user.
  Future<void> theCloudSays(AuthHubEvent event) async {
    events.add(event);
    await pumpEventQueue();
  }

  group("AmplifyCognitoService.initLifeCycle", () {
    test("starts with the user of a session which is already open", () async {
      final service = await aService();

      expect(service.authStatus, AuthStatus.signedIn);
    });

    test("starts with a user who is signed out", () async {
      cloud.isSignedIn = false;

      final service = await aService();

      expect(service.authStatus, AuthStatus.signedOut);
    });

    test("asks Cognito for the plugin of the authentication", () async {
      final service = await aService();

      expect(await service.getLinkedPluginsList(), [isA<AmplifyAuthCognito>()]);
    });
  });

  group("AmplifyCognitoService", () {
    test("follows the user the cloud says signed in", () async {
      cloud.isSignedIn = false;
      final service = await aService();

      final pushed = expectLater(service.authStatusStream, emits(AuthStatus.signedIn));
      await theCloudSays(AuthHubEvent.signedIn(_user));

      expect(service.authStatus, AuthStatus.signedIn);
      await pushed;
    });

    test("follows the user the cloud says signed out", () async {
      final service = await aService();

      await theCloudSays(AuthHubEvent.signedOut());

      expect(service.authStatus, AuthStatus.signedOut);
    });

    test("follows the session the cloud says expired", () async {
      final service = await aService();

      await theCloudSays(AuthHubEvent.sessionExpired());

      expect(service.authStatus, AuthStatus.sessionExpired);
    });

    test("follows the user the cloud says was deleted", () async {
      final service = await aService();

      await theCloudSays(AuthHubEvent.userDeleted());

      expect(service.authStatus, AuthStatus.userDeleted);
    });

    test("says nothing of a status which did not change", () async {
      final service = await aService();
      final pushed = <AuthStatus>[];
      service.authStatusStream.listen(pushed.add);

      await theCloudSays(AuthHubEvent.signedIn(_user));

      expect(pushed, isEmpty);
    });

    test("names the exceptions which mean that a user has to sign in again", () async {
      final service = await aService();

      expect(service.getNonTransientAuthFailureTypes(), {
        UserNotFoundException,
        SignedOutException,
      });
    });
  });

  group("AmplifyCognitoService, the calls it hands to its services", () {
    test("signs a user in", () async {
      final service = await aService();

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.done);
      expect(cloud.argumentsOf("signIn"), {"username": "a user", "password": "a password"});
    });

    test("registers a user", () async {
      final service = await aService();

      final result = await service.signUp(accountId: "a user", password: "a password");

      expect(result.status, AuthSignUpStatus.done);
      expect(cloud.callNames, contains("signUp"));
    });

    test("resets the password of a user", () async {
      final service = await aService();

      final result = await service.resetPassword(username: "a user");

      expect(result.status, AuthResetPwdStatus.done);
      expect(cloud.callNames, contains("resetPassword"));
    });

    test("reads the address of the user", () async {
      final service = await aService();
      cloud.attributes = const [
        AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          value: "a.user@example.com",
        ),
      ];

      expect(await service.getEmailAddress(), "a.user@example.com");
    });

    test("deletes the account of the user", () async {
      final service = await aService();

      final result = await service.deleteAccount();

      expect(result.status, AuthDeleteStatus.done);
      expect(cloud.callNames, contains("deleteUser"));
    });

    test("says whether the user is signed in", () async {
      final service = await aService();

      expect(await service.isUserSigned(), isTrue);
    });
  });

  group("AmplifyCognitoService.disposeLifeCycle", () {
    test("stops following the user of the cloud", () async {
      final service = await aService();

      await service.disposeLifeCycle();

      expect(service.authStatusStream, emitsDone);
    });
  });
}
