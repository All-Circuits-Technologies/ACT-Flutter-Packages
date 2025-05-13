import 'package:act_server_req_manager/src/types/request_status.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

extension RequestStatusExtAuth on RequestStatus {
  AuthSignInStatus get signInStatus => switch (this) {
        RequestStatus.success => AuthSignInStatus.done,
        RequestStatus.loginError => AuthSignInStatus.sessionExpired,
        RequestStatus.globalError => AuthSignInStatus.genericError,
      };
}
