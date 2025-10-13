// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/src/types/request_status.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

/// This is used to extend [RequestStatus] object with elements linked to this package
extension RequestStatusExtAuth on RequestStatus {
  /// Return a [AuthSignInStatus] status linked to the current [RequestStatus]
  AuthSignInStatus get signInStatus => switch (this) {
        RequestStatus.success => AuthSignInStatus.done,
        RequestStatus.loginError => AuthSignInStatus.sessionExpired,
        RequestStatus.globalError => AuthSignInStatus.genericError,
      };
}
