// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_cognito/src/cognito_delete_service.dart';
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
  late CognitoDeleteService service;

  setUp(() async {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    cloud = await FakeAuthPlugin.install();
    service = CognitoDeleteService(logsHelper: logs.buildHelper(category: "cognito"));
    await service.initLifeCycle();
  });

  tearDown(() async {
    await service.disposeLifeCycle();
    await Amplify.reset();
  });

  group("CognitoDeleteService.deleteAccount", () {
    test("asks the pool to delete the account of the user", () async {
      final result = await service.deleteAccount();

      expect(result.status, AuthDeleteStatus.done);
      expect(cloud.callNames, ["deleteUser"]);
    });

    test("says that the device is not online when the cloud cannot be reached", () async {
      cloud.exception = const NetworkException("no network");

      final result = await service.deleteAccount();

      expect(result.status, AuthDeleteStatus.networkError);
      expect(result.extra, cloud.exception);
    });

    test("says that an account the pool refused to delete is an error", () async {
      cloud.exception = const NotAuthorizedServiceException("User is disabled");

      final result = await service.deleteAccount();

      expect(result.status, AuthDeleteStatus.genericError);
    });

    test("says that an account which is not there any more is an error", () async {
      cloud.exception = const UserNotFoundException("User does not exist");

      final result = await service.deleteAccount();

      expect(result.status, AuthDeleteStatus.genericError);
    });
  });
}
