// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("RequestStatusExtAuth.signInStatus", () {
    test("says that a request which succeeded signed the user in", () {
      expect(RequestStatus.success.signInStatus, AuthSignInStatus.done);
    });

    test("says that a request which was refused ended the session of the user", () {
      expect(RequestStatus.loginError.signInStatus, AuthSignInStatus.sessionExpired);
    });

    test("says that a request which failed for any other reason is an error", () {
      expect(RequestStatus.timeoutError.signInStatus, AuthSignInStatus.genericError);
      expect(RequestStatus.failedToFetchError.signInStatus, AuthSignInStatus.genericError);
      expect(RequestStatus.globalError.signInStatus, AuthSignInStatus.genericError);
    });
  });
}
