// Copyright (c) 2020. BMS Circuits

import 'package:act_thingsboard/src/data/abstract_constants_manager.dart';
import 'package:act_thingsboard/src/tb_global_manager.dart';

/// List of [HttpServerRequest] to HTTP server
enum HttpServerRequest {
  login,
  tokenRenew,
  logout,
  currentUser,
  reCAPTCHAPublicKey,
  signup,
  activateAccountByEmail,
  resendEmailActivationAccount,
  askPasswordReset,
  changePasswordReset,
  changePassword,
  checkResetToken,
  getUserDataById,
  saveUserData,
  getUserListDevices,
  getLinkedDeviceData,
  claimDevice,
  unlinkDevice,
  getDeviceAttributes,
  saveDeviceAttributes,
  getDeviceTelemetries,
  sendDeviceRPC,
  accountClosure,
  webSocket,
}

/// Extension of [HttpServerRequest]
extension HttpServerRequestExtension on HttpServerRequest {
  /// Get URL to HTTP server from [HttpServerRequest].
  /// [ids] and [queryParameters]
  Uri getUrl({
    List<String> ids = const [],
    Map<String, String> queryParameters = const {},
  }) {
    String url = "";
    switch (this) {
      case HttpServerRequest.login:
        url = '/api/auth/login';
        break;

      case HttpServerRequest.tokenRenew:
        url = '/api/auth/token';
        break;

      case HttpServerRequest.logout:
        url = '/api/auth/logout';
        break;

      case HttpServerRequest.currentUser:
        url = '/api/auth/user';
        break;

      case HttpServerRequest.reCAPTCHAPublicKey:
        url = '/api/noauth/selfRegistration/signUpSelfRegistrationParams';
        break;

      case HttpServerRequest.signup:
        url = '/api/noauth/signup';
        break;

      case HttpServerRequest.activateAccountByEmail:
        assert(queryParameters
            .containsKey(HttpServerRequestHelper.paramEmailCode));
        url = "/api/noauth/activateByEmailCode";
        break;

      case HttpServerRequest.resendEmailActivationAccount:
        assert(queryParameters.containsKey(HttpServerRequestHelper.paramEmail));
        url = '/api/noauth/resendEmailActivation';
        break;

      case HttpServerRequest.askPasswordReset:
        url = '/api/noauth/resetPasswordByEmail';
        break;

      case HttpServerRequest.changePasswordReset:
        url = '/api/noauth/resetPassword';
        break;

      case HttpServerRequest.changePassword:
        url = '/api/auth/changePassword';
        break;

      case HttpServerRequest.checkResetToken:
        assert(queryParameters
            .containsKey(HttpServerRequestHelper.paramResetToken));
        url = '/api/noauth/resetPassword';
        break;

      case HttpServerRequest.getUserDataById:
        assert(ids.isNotEmpty);
        String userId = ids.first;
        url = '/api/user/$userId';
        break;

      case HttpServerRequest.saveUserData:
        assert(queryParameters
            .containsKey(HttpServerRequestHelper.paramSendActivationMail));
        url = '/api/user';
        break;

      case HttpServerRequest.getUserListDevices:
        assert(queryParameters.containsKey(HttpServerRequestHelper.paramPage));
        assert(
            queryParameters.containsKey(HttpServerRequestHelper.paramPageSize));
        assert(ids.isNotEmpty);
        String customerId = ids.first;
        url = '/api/customer/$customerId/devices';
        break;

      case HttpServerRequest.getLinkedDeviceData:
        assert(ids.isNotEmpty);
        String deviceId = ids.first;
        url = '/api/device/$deviceId';
        break;

      case HttpServerRequest.unlinkDevice:
      case HttpServerRequest.claimDevice:
        assert(ids.isNotEmpty);
        String deviceName = ids.first;
        url = '/api/customer/device/$deviceName/claim';
        break;

      case HttpServerRequest.getDeviceAttributes:
        assert(queryParameters.containsKey(HttpServerRequestHelper.paramKeys));
        assert(ids.length == 2);
        String deviceId = ids[0];
        String scope = ids[1];
        url = '/api/plugins/telemetry/DEVICE/$deviceId/values'
            '/attributes/$scope';
        break;

      case HttpServerRequest.saveDeviceAttributes:
        assert(ids.length == 2);
        String deviceId = ids[0];
        String scope = ids[1];
        url = '/api/plugins/telemetry/DEVICE/$deviceId/$scope';
        break;

      case HttpServerRequest.getDeviceTelemetries:
        assert(queryParameters.containsKey(HttpServerRequestHelper.paramKeys));
        assert(ids.length == 1);
        String deviceId = ids[0];
        url = '/api/plugins/telemetry/DEVICE/$deviceId/values/timeseries';
        break;

      case HttpServerRequest.sendDeviceRPC:
        assert(ids.length == 2);
        String callType = ids[0];
        String deviceId = ids[1];
        url = '/api/plugins/rpc/$callType/$deviceId';
        break;

      case HttpServerRequest.accountClosure:
        url = '/isa/api/auth/user';
        break;

      default:
        break;
    }

    return Uri.https(
      GlobalGetIt().get<AbstractConstantsManager>().serverAddress,
      url,
      queryParameters,
    );
  }

  /// Retrieve websocket Url with [basicUserToken] query parameter.
  String getWebSocketUri(String basicUserToken) {
    if (this == HttpServerRequest.webSocket) {
      return 'api/ws/plugins/telemetry?token=$basicUserToken';
    }

    return "";
  }
}

/// Helper class for the [HttpServerRequest]
class HttpServerRequestHelper {
  static const String paramPage = "page";
  static const String paramPageSize = "pageSize";
  static const String paramEmailCode = "emailCode";
  static const String paramEmail = "email";
  static const String paramKeys = "keys";
  static const String paramSendActivationMail = "sendActivationMail";
  static const String paramResetToken = "resetToken";
  static const String paramSecretKey = "secretKey";
}
