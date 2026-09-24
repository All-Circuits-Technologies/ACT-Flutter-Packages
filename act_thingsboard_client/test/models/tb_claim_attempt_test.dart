// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("TbClaimAttempt.outcome", () {
    test("says that the session is over when the request never reached the server", () {
      expect(
        anAttempt(status: RequestStatus.loginError, response: ClaimResponse.SUCCESS).outcome,
        TbClaimOutcome.loginError,
      );
    });

    test("says that the claim worked when the server answered SUCCESS", () {
      expect(anAttempt(response: ClaimResponse.SUCCESS).outcome, TbClaimOutcome.success);
    });

    test("says that the device is already claimed when the server answered CLAIMED", () {
      expect(anAttempt(response: ClaimResponse.CLAIMED).outcome, TbClaimOutcome.alreadyClaimed);
    });

    test("says that the claim was refused when the server answered FAILURE", () {
      expect(anAttempt(response: ClaimResponse.FAILURE).outcome, TbClaimOutcome.refused);
    });

    test("says that the device is unknown when the server answered 404", () {
      expect(anAttempt(httpStatus: 404).outcome, TbClaimOutcome.unknownDevice);
    });

    test("says that the secret was refused when the server answered 400", () {
      expect(anAttempt(httpStatus: 400).outcome, TbClaimOutcome.secretRefused);
    });

    test("says that the server could not be reached on any other answer", () {
      expect(anAttempt(httpStatus: 503).outcome, TbClaimOutcome.communicationError);
      expect(anAttempt().outcome, TbClaimOutcome.communicationError);
    });
  });
}

/// One answer of the server to a claim, as the decision table reads it.
TbClaimAttempt anAttempt({
  RequestStatus status = RequestStatus.success,
  ClaimResponse? response,
  int? httpStatus,
}) => TbClaimAttempt(status: status, response: response, httpStatus: httpStatus);
