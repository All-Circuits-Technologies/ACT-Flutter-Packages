// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_thingsboard_client/src/constants/tb_constants.dart' as tb_constants;
import 'package:act_thingsboard_client/src/managers/abs_tb_server_req_manager.dart';
import 'package:act_thingsboard_client/src/models/tb_request_response.dart';

/// This is the builder to [TbStdAuthServerReqManager]
class TbStdAuthServerReqBuilder<A extends AbsAuthManager>
    extends AbsTbServerReqBuilder<TbStdAuthServerReqManager> {
  /// Class constructor
  TbStdAuthServerReqBuilder()
      : super(() => TbStdAuthServerReqManager(
              authGetter: globalGetIt().get<A>,
            ));

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [...super.dependsOn(), A];
}

/// This manager uses a derived class of [AbsAuthManager] to manage the Thingsboard tokens.
///
/// We expect that `TbStdAuthService` is used as auth provider.
///
/// The manager watches the status of the user: when the user leaves, the values of the devices
/// watched so far are forgotten, so that nothing of an account reaches the next one.
///
/// {@macro act_thingsboard_client.AbsTbServerReqManager.details}
class TbStdAuthServerReqManager extends AbsTbServerReqManager {
  /// This is the log category of the [TbStdAuthServerReqManager]
  static final _stdAuthTbLogsCategory = "stdAuth";

  /// Getter to access the [AbsAuthManager]
  final AbsAuthManager Function() _authGetter;

  /// The observer of the status of the user
  late final AuthStreamObserver _signedIn;

  /// The subscription to the observer, which clears the devices when the user leaves
  late final StreamSubscription<bool> _signedInSub;

  /// Class constructor
  TbStdAuthServerReqManager({
    required AbsAuthManager Function() authGetter,
  })  : _authGetter = authGetter,
        super(logCategory: _stdAuthTbLogsCategory);

  /// {@macro act_life_cycle.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _signedIn = AuthStreamObserver.ofService(_authGetter().authService);
    _signedInSub = _signedIn.stream.listen((signedIn) {
      if (!signedIn) {
        unawaited(devicesService.clear());
      }
    });
  }

  /// This encapsulates the Thingsboard request and allow to do multiple retry request if fails but
  /// also reconnect the user to its account if the tokens are no more valid
  ///
  /// This method waits the end of the service initialisation
  @override
  Future<TbRequestResponse<T>> request<T>(tb_constants.TbRequestToCall<T> requestToCall) async {
    var triedNb = 0;
    TbRequestResponse<T> result;

    do {
      final tokens = await _authGetter().authService.getTokens();
      if (tokens == null) {
        return TbRequestResponse(status: RequestStatus.loginError);
      }

      // After having get the tokens from the auth service we set it in the Thingsboard client
      await noAuthManager.tbClient
          .setUserFromJwtToken(tokens.accessToken?.raw, tokens.refreshToken?.raw, null);

      result = await noAuthManager.request(requestToCall);
      triedNb++;
    } while (result.status == RequestStatus.loginError && triedNb <= 1);

    return result;
  }

  /// {@macro act_life_cycle.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _signedInSub.cancel();
    await _signedIn.dispose();

    await super.disposeLifeCycle();
  }
}
