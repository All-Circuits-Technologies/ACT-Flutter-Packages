import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client/src/constants/tb_constants.dart' as tb_constants;
import 'package:act_thingsboard_client/src/managers/abs_tb_server_req_manager.dart';

class TbStdAuthServerReqBuilder<A extends AbsAuthManager>
    extends AbsTbServerReqBuilder<TbStdAuthServerReqManager> {
  TbStdAuthServerReqBuilder()
      : super(() => TbStdAuthServerReqManager(
              authGetter: globalGetIt().get<A>,
            ));

  @override
  Iterable<Type> dependsOn() => [...super.dependsOn(), A];
}

class TbStdAuthServerReqManager extends AbsTbServerReqManager {
  static final _stdAuthTbLogsCategory = "stdAuth";

  final AbsAuthManager Function() _authGetter;

  TbStdAuthServerReqManager({
    required AbsAuthManager Function() authGetter,
  })  : _authGetter = authGetter,
        super(logCategory: _stdAuthTbLogsCategory);

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
}
