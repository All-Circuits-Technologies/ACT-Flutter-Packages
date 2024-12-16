// Copyright (c) 2020. BMS Circuits

import 'package:act_server_request_manager/act_server_request_manager.dart';
import 'package:act_thingsboard/src/data/abstract_constants_manager.dart';
import 'package:act_thingsboard/src/http/http_server_request.dart';
import 'package:act_thingsboard/src/model/attribute_scope.dart';
import 'package:act_thingsboard/src/model/device.dart';
import 'package:act_thingsboard/src/model/entity_id.dart';
import 'package:act_thingsboard/src/model/entity_type.dart';
import 'package:act_thingsboard/src/model/rpc_call_type.dart';
import 'package:act_thingsboard/src/model/user.dart';
import 'package:act_thingsboard/src/model/user_signup_data.dart';
import 'package:act_thingsboard/src/tb_global_manager.dart';
import 'package:act_thingsboard/src/token_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

/// HTTP request maker, contains all the requests to the server, it simplifies
/// the communication with the server.
class HttpRequestMaker extends AbstractHttpRequestMaker {
  static const _responsePagerDataArray = "data";
  static const _currentPasswordString = "currentPassword";
  static const _newPasswordString = "newPassword";
  static const _passwordString = "password";
  static const _emailString = "email";
  static const _resetTokenString = "resetToken";
  static const responsePagerDataArray = "data";
  static const _captchaSiteDataArray = "captchaSiteKey";
  static const _resultString = "result";

  static const _rpcMethodString = "method";
  static const _rpcParamsString = "params";
  static const _rpcStartUpdateFunction = "startUpdate";
  static const _rpcValidAnswer = "ok";

  /// Get the current user (the user currently connected with its token)
  static Future<Tuple2<RequestResult, User>> getCurrentUser() async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.get,
      url: HttpServerRequest.currentUser.getUrl(),
    );

    if (result.item1 != RequestResult.Ok) {
      return Tuple2(result.item1, User());
    }

    Map<String, dynamic> responseBody =
        AbstractHttpRequestMaker.parseJsonBodyToObj(result.item2);

    if (responseBody == null) {
      // Return an invalid user
      AppLogger().w("Can't parse the user response body: it's not a "
          "json");
      return Tuple2(RequestResult.GenericError, User());
    }

    return Tuple2(RequestResult.Ok, User.fromJson(responseBody));
  }

  /// Ask reset password to server. User is identified with [email].
  static Future<RequestResult> askResetPasswordByEmail(
    String email,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.askPasswordReset.getUrl(),
      body: {
        _emailString: email,
      },
      needAuth: false,
    );

    if (result.item1 != RequestResult.Ok) {
      return result.item1;
    }

    return RequestResult.Ok;
  }

  /// Ask to resend email activation again.
  static Future<RequestResult> resendEmailActivationAccount(
    String email,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.resendEmailActivationAccount.getUrl(
        queryParameters: {
          _emailString: email,
        },
      ),
      needAuth: false,
    );

    if (result.item1 != RequestResult.Ok) {
      return result.item1;
    }

    return RequestResult.Ok;
  }

  /// Check [resetToken] is valid
  static Future<RequestResult> checkResetToken(
    String resetToken,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.get,
      url: HttpServerRequest.checkResetToken.getUrl(
        queryParameters: {
          HttpServerRequestHelper.paramResetToken: resetToken,
        },
      ),
      needAuth: false,
    );

    if (result.item1 != RequestResult.Ok) {
      return result.item1;
    }

    return RequestResult.Ok;
  }

  /// Check [activateToken] is valid
  static Future<RequestResult> activateAccountByEmail(
    String activateToken,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.activateAccountByEmail.getUrl(
        queryParameters: {
          HttpServerRequestHelper.paramEmailCode: activateToken,
        },
      ),
      needAuth: false,
    );

    if (result.item1 != RequestResult.Ok) {
      return result.item1;
    }

    return RequestResult.Ok;
  }

  /// Reset [password] with [resetToken] retrieved from email sent by server.
  static Future<RequestResult> resetPassword(
    String password,
    String resetToken,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.changePasswordReset.getUrl(),
      body: {
        _passwordString: password,
        _resetTokenString: resetToken,
      },
      needAuth: false,
    );

    if (result.item1 != RequestResult.Ok) {
      return result.item1;
    }

    return RequestResult.Ok;
  }

  /// Change [currentPassword] into [newPassword].
  static Future<RequestResult> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.changePassword.getUrl(),
      body: {
        _currentPasswordString: currentPassword,
        _newPasswordString: newPassword,
      },
    );

    if (result.item1 != RequestResult.Ok) {
      return result.item1;
    }

    return RequestResult.Ok;
  }

  /// Save [user] data
  static Future<Tuple2<RequestResult, User>> saveUserData(
    User user,
    bool sendActivationEmail,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.saveUserData.getUrl(
        queryParameters: {
          HttpServerRequestHelper.paramSendActivationMail:
              sendActivationEmail.toString(),
        },
      ),
      body: user.toJson(),
    );

    if (result.item1 != RequestResult.Ok) {
      return Tuple2(result.item1, User());
    }

    Map<String, dynamic> responseBody =
        AbstractHttpRequestMaker.parseJsonBodyToObj(result.item2);

    if (responseBody == null) {
      // Return an invalid list
      AppLogger().w("Can't parse the save user response body: it's not a "
          "json");
      return Tuple2(RequestResult.GenericError, User());
    }

    User userReceived = User.fromJson(responseBody);

    if (!userReceived.isValid) {
      AppLogger().w("The user parsed and got from server $responseBody "
          "is not valid");
      return Tuple2(RequestResult.GenericError, User());
    }

    return Tuple2(RequestResult.Ok, userReceived);
  }

  /// Get devices linked to user
  ///
  /// For now we don't manage pager (we don't limit the number of devices got)
  /// If the number overflows 10, it may be nice to do it (in order to be
  /// faster)
  static Future<Tuple2<RequestResult, List<Device>>> getDevicesLinkedToUser(
      User user) async {
    if (user == null || user.customerId == null || !user.customerId.isValid) {
      AppLogger().w("Can't get the devices of an unknown user");
      return Tuple2(RequestResult.GenericError, []);
    }

    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.get,
      url: HttpServerRequest.getUserListDevices.getUrl(
        ids: [user.customerId.id],
        queryParameters: {
          HttpServerRequestHelper.paramPage: '0',
          HttpServerRequestHelper.paramPageSize:
              AbstractConstantsManager.maxDeviceNumberByPage.toString(),
        },
      ),
    );

    if (result.item1 != RequestResult.Ok) {
      return Tuple2(result.item1, []);
    }

    Map<String, dynamic> responseBody =
        AbstractHttpRequestMaker.parseJsonBodyToObj(result.item2);

    if (responseBody == null) {
      // Return an invalid list
      AppLogger().w("Can't parse the devices response body: it's not a "
          "json");
      return Tuple2(RequestResult.GenericError, []);
    }

    if (!responseBody.containsKey(_responsePagerDataArray)) {
      AppLogger().w("The response doesn't contains a data attribute, "
          "can't get the devices.");
      return Tuple2(RequestResult.GenericError, []);
    }

    var devicesList = responseBody[_responsePagerDataArray];

    if (devicesList is! List<dynamic>) {
      AppLogger().w("The $_responsePagerDataArray attribute in the "
          "response received is not a list of device");
      return Tuple2(RequestResult.GenericError, []);
    }

    List<Device> devices = [];

    for (dynamic jsonDevice in devicesList) {
      if (jsonDevice is! Map<String, dynamic>) {
        AppLogger().w("The element is not a json");
        return Tuple2(RequestResult.GenericError, []);
      }

      Device device = Device.fromJson(jsonDevice as Map<String, dynamic>);

      if (!device.isValid) {
        AppLogger().w("The device parsed and got from server $jsonDevice "
            "is not valid");
        continue;
      }

      devices.add(device);
    }

    return Tuple2(RequestResult.Ok, devices);
  }

  /// Get a device thanks to its database name (not the name displayed in the
  /// app).
  static Future<Tuple2<RequestResult, Device>> getDeviceByName(
    User user,
    String name,
  ) async {
    Tuple2<RequestResult, List<Device>> result =
        await getDevicesLinkedToUser(user);

    if (result.item1 != RequestResult.Ok) {
      return Tuple2(result.item1, Device());
    }

    for (Device device in result.item2) {
      if (device.name == name) {
        // Device found
        return Tuple2(RequestResult.Ok, device);
      }
    }

    AppLogger().i("The device wanted: $name, doesn't exist or it's not "
        "linked to the user");
    return Tuple2(RequestResult.Ok, Device());
  }

  /// Get a device thanks to its database id
  static Future<Tuple2<RequestResult, Device>> getDevice(
      EntityId deviceId) async {
    if (deviceId == null ||
        !deviceId.isValid ||
        deviceId.entityType != EntityType.device) {
      AppLogger().w("Can't get device, the id is not known");
      return Tuple2(RequestResult.GenericError, Device());
    }

    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.get,
      url: HttpServerRequest.getLinkedDeviceData.getUrl(
        ids: [deviceId.id],
      ),
    );

    if (result.item1 != RequestResult.Ok) {
      return Tuple2(result.item1, Device());
    }

    Map<String, dynamic> responseBody =
        AbstractHttpRequestMaker.parseJsonBodyToObj(result.item2);

    if (responseBody == null) {
      // Return an invalid user
      AppLogger().w("Can't parse the user response body: it's not a "
          "json");
      return Tuple2(RequestResult.GenericError, Device());
    }

    return Tuple2(RequestResult.Ok, Device.fromJson(responseBody));
  }

  /// Get ReCaptcha needed to create an account
  static Future<Tuple2<RequestResult, String>> getReCaptcha() async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.get,
      url: HttpServerRequest.reCAPTCHAPublicKey.getUrl(),
      needAuth: false,
    );

    if (result.item1 != RequestResult.Ok) {
      return Tuple2(result.item1, "");
    }

    Map<String, dynamic> responseBody =
        AbstractHttpRequestMaker.parseJsonBodyToObj(result.item2);

    if (responseBody == null) {
      // Return an invalid captcha
      AppLogger().w("Can't parse the user response body: it's not a "
          "json");
      return Tuple2(RequestResult.GenericError, "");
    }

    String siteKey;
    if (responseBody[_captchaSiteDataArray] is String) {
      siteKey = responseBody[_captchaSiteDataArray] as String;
    }

    if (siteKey == null) {
      AppLogger().w("Can't parse the $_captchaSiteDataArray : it's empty");
      return Tuple2(RequestResult.GenericError, "");
    }

    return Tuple2(RequestResult.Ok, siteKey);
  }

  /// Create a new user account with a [reCaptcha]
  static Future<RequestResult> signUp(
    UserSignUpData userData,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.signup.getUrl(),
      body: userData.toJson(),
      needAuth: false,
    );

    if (result.item1 != RequestResult.Ok) {
      return result.item1;
    }

    return RequestResult.Ok;
  }

  /// Set the attributes linked to a device
  ///
  /// For the server, we have to do specific requests which contains the
  /// attributes grouped by scope, we cannot mix the attributes which have not
  /// the same scopes: we have to differentiate [AttributeScope.client],
  /// [AttributeScope.serverReadWrite] and shared attributes:
  /// [AttributeScope.sharedOneWay] or [AttributeScope.sharedTwoWays].
  ///
  /// For the server, the scopes: [AttributeScope.sharedTwoWays] and
  /// [AttributeScope.sharedOneWay] are identical, we only make a difference
  /// in the mobile application. Therefore, there is no need to make multiple
  /// requests for attributes in those scopes, merge the shared attributes
  /// together
  static Future<RequestResult> setDeviceAttributes(
    EntityId deviceId,
    Map<String, dynamic> attributes,
    AttributeScope attributesScope,
  ) async {
    if (deviceId == null ||
        !deviceId.isValid ||
        deviceId.entityType != EntityType.device) {
      AppLogger().w("Can't get device, the id is not known");
      return RequestResult.GenericError;
    }

    if (attributesScope == null || attributesScope == AttributeScope.client) {
      AppLogger().w("The attribute scope can't be null or can't be equal "
          "to client: you can't modify client attributes");
      return RequestResult.GenericError;
    }

    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.saveDeviceAttributes.getUrl(
        ids: [deviceId.id, attributesScope.requestScope],
      ),
      body: attributes,
    );

    return result.item1;
  }

  /// Start device [deviceId] update
  static Future<bool> startDeviceUpdate(String deviceId) {
    return _sendRPCToDevice(
      RpcCallType.twoway.text,
      deviceId,
      _rpcStartUpdateFunction,
      {},
    );
  }

  /// Send Remote Procedure Call to device [deviceId].
  static Future<bool> _sendRPCToDevice(
    String callType,
    String deviceId,
    String method,
    Map<String, dynamic> params,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.sendDeviceRPC.getUrl(
        ids: [
          callType,
          deviceId,
        ],
      ),
      body: {
        _rpcMethodString: method,
        _rpcParamsString: params,
      },
    );

    if (result.item1 != RequestResult.Ok) {
      return false;
    }

    Map<String, dynamic> responseBody =
        AbstractHttpRequestMaker.parseJsonBodyToObj(result.item2);
    if (responseBody[_resultString] != _rpcValidAnswer) {
      return false;
    }

    return true;
  }

  /// Claim device depending on [deviceSn]
  static Future<RequestResult> claimDevice(
    String deviceSn,
    String resetToken,
  ) async {
    Tuple2<RequestResult, Response> result = await _sendTbHttpRequest(
      command: HttpMethod.post,
      url: HttpServerRequest.claimDevice.getUrl(
        ids: [deviceSn],
      ),
      body: {
        HttpServerRequestHelper.paramSecretKey: resetToken,
      },
    );

    return result.item1;
  }

  static Future<Tuple2<RequestResult, Response>> _sendTbHttpRequest({
    @required HttpMethod command,
    @required Uri url,
    Map<String, String> headers = const {},
    Map<String, dynamic> body = const {},
    int tryNumber = 1,
    bool updateRequestState = true,
    bool needAuth = true,
  }) async {
    GetXAuthHeaderAsync getXAuth;
    RefreshXAuthHeaderAsync refreshXAuth;

    if (needAuth) {
      TokenManager tokenManager = GlobalGetIt().get<TokenManager>();

      getXAuth = tokenManager.getToken;
      refreshXAuth = tokenManager.refreshToken;
    }

    return AbstractHttpRequestMaker.sendHttpRequest(
      command: command,
      url: url,
      headers: headers,
      body: body,
      tryNumber: tryNumber,
      updateRequestState: updateRequestState,
      getXAuth: getXAuth,
      refreshXAuth: refreshXAuth,
    );
  }
}
