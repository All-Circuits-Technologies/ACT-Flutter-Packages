// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_aws_iot.dart';

void main() {
  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  group("AwsIotShadowStateModel.empty", () {
    test("knows nothing of a shadow it was never told about", () {
      final state = AwsIotShadowStateModel.empty();

      expect(state.version, 0);
      expect(state.desiredState, isEmpty);
      expect(state.reportedState, isEmpty);
    });
  });

  group("AwsIotShadowStateModel.copyAfterAcceptedGetUpdate", () {
    test("reads the state and the version the server answered", () {
      final state = AwsIotShadowStateModel.empty();

      final newState = state.copyAfterAcceptedGetUpdate(
        aShadowDoc(version: 3, desired: {"led": true}, reported: {"led": false}),
      );

      expect(newState?.version, 3);
      expect(newState?.desiredState, {"led": true});
      expect(newState?.reportedState, {"led": false});
    });

    test("reads an answer which is not a document as nothing", () {
      final state = AwsIotShadowStateModel.empty();

      expect(state.copyAfterAcceptedGetUpdate("not a document"), isNull);
    });

    test("reads an answer without a state as nothing", () {
      final state = AwsIotShadowStateModel.empty();

      expect(state.copyAfterAcceptedGetUpdate(jsonEncode({"version": 1})), isNull);
    });

    test("reads an answer without a version as nothing", () {
      final state = AwsIotShadowStateModel.empty();

      final answer = jsonEncode({
        "state": {"reported": <String, dynamic>{}},
      });

      expect(state.copyAfterAcceptedGetUpdate(answer), isNull);
    });

    test("keeps what it knows of a shadow whose answer is older than it", () {
      const state = AwsIotShadowStateModel(
        version: 5,
        desiredState: {"led": true},
        reportedState: {"led": true},
      );

      final newState = state.copyAfterAcceptedGetUpdate(
        aShadowDoc(version: 4, reported: {"led": false}),
      );

      expect(newState, same(state));
    });

    test("adds to what it knows when the answer is of the version it already knows", () {
      const state = AwsIotShadowStateModel(
        version: 5,
        desiredState: {"led": true},
        reportedState: {"temperature": 20},
      );

      final newState = state.copyAfterAcceptedGetUpdate(
        aShadowDoc(version: 5, desired: {"fan": false}, reported: {"humidity": 50}),
      );

      expect(newState?.desiredState, {"led": true, "fan": false});
      expect(newState?.reportedState, {"temperature": 20, "humidity": 50});
    });

    test("forgets what it knew when the answer is of a newer version", () {
      const state = AwsIotShadowStateModel(
        version: 5,
        desiredState: {"led": true},
        reportedState: {"temperature": 20},
      );

      final newState = state.copyAfterAcceptedGetUpdate(
        aShadowDoc(version: 6, reported: {"humidity": 50}),
      );

      expect(newState?.desiredState, isEmpty);
      expect(newState?.reportedState, {"humidity": 50});
    });

    test("reads a shadow whose desired state the server does not answer", () {
      final state = AwsIotShadowStateModel.empty();

      final answer = jsonEncode({
        "state": {
          "reported": {"led": true},
        },
        "version": 2,
      });

      final newState = state.copyAfterAcceptedGetUpdate(answer);

      expect(newState?.desiredState, isEmpty);
      expect(newState?.reportedState, {"led": true});
    });
  });

  group("AwsIotShadowStateModel.getJsonForUpdateRequest", () {
    test("asks for the state the caller wants, at the version it knows", () {
      const state = AwsIotShadowStateModel(
        version: 4,
        desiredState: {},
        reportedState: {"led": false},
      );

      final json = state.getJsonForUpdateRequest({"led": true}, "a-token");

      expect(jsonDecode(json!), {
        "state": {
          "desired": {"led": true},
        },
        "version": 4,
        "clientToken": "a-token",
      });
    });

    test("keeps the state it already asked for beside the one it is asked for", () {
      const state = AwsIotShadowStateModel(
        version: 1,
        desiredState: {"led": true},
        reportedState: {},
      );

      final json = state.getJsonForUpdateRequest({"fan": true}, "a-token");
      final request = jsonDecode(json!) as Map<String, dynamic>;
      final asked = request["state"] as Map<String, dynamic>;

      expect(asked["desired"], {"led": true, "fan": true});
    });

    test("asks for nothing when the state it is asked for is the one it asked for", () {
      const state = AwsIotShadowStateModel(
        version: 1,
        desiredState: {"led": true},
        reportedState: {},
      );

      expect(state.getJsonForUpdateRequest({"led": true}, "a-token"), isNull);
    });

    test("asks for a state which is only part of the one it asked for", () {
      const state = AwsIotShadowStateModel(
        version: 1,
        desiredState: {"led": true, "fan": false},
        reportedState: {},
      );

      expect(state.getJsonForUpdateRequest({"led": false}, "a-token"), isNotNull);
    });
  });

  group("AwsIotShadowStateModel.isClientTokenValid", () {
    test("says that an answer which carries the token of the request is the one", () {
      final answer = aShadowDoc(clientToken: "a-token");

      expect(AwsIotShadowStateModel.isClientTokenValid(answer, "a-token"), isTrue);
    });

    test("says that an answer which carries another token is not the one", () {
      final answer = aShadowDoc(clientToken: "another-token");

      expect(AwsIotShadowStateModel.isClientTokenValid(answer, "a-token"), isFalse);
    });

    test("says that an answer without a token is not the one", () {
      expect(AwsIotShadowStateModel.isClientTokenValid(aShadowDoc(), "a-token"), isFalse);
    });

    test("says that an answer which is not a document is not the one", () {
      expect(AwsIotShadowStateModel.isClientTokenValid("not a document", "a-token"), isFalse);
    });
  });

  group("AwsIotShadowStateModel.copyWith", () {
    test("keeps what it is not asked to change", () {
      const state = AwsIotShadowStateModel(
        version: 2,
        desiredState: {"led": true},
        reportedState: {"led": false},
      );

      final copy = state.copyWith(version: 3);

      expect(copy.version, 3);
      expect(copy.desiredState, state.desiredState);
      expect(copy.reportedState, state.reportedState);
    });

    test("reads two states which hold the same thing as the same one", () {
      const state = AwsIotShadowStateModel(
        version: 2,
        desiredState: {"led": true},
        reportedState: {},
      );

      expect(state.copyWith(), state);
    });
  });
}
