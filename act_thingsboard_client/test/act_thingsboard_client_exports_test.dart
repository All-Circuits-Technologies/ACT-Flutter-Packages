// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('act_thingsboard_client', () {
    test('re-exports the request status of the requests it answers with', () {
      expect(RequestStatus.values, isNotEmpty);
    });

    test('re-exports the claim models of the server', () {
      expect(ClaimResponse.values, isNotEmpty);
      expect(ClaimRequest(secretKey: "a secret"), isA<ClaimRequest>());
      expect(<ClaimResult>[], isA<List<ClaimResult>>());
    });

    test('re-exports the attribute scope of the attributes it reads', () {
      expect(AttributeScope.values, isNotEmpty);
    });
  });
}
