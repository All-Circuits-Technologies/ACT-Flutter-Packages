// Copyright (c) 2020. BMS Circuits

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_request_manager/act_server_request_manager.dart';
import 'package:act_thingsboard/src/data/abstract_constants_manager.dart';
import 'package:act_thingsboard/src/http/http_server_request.dart';
import 'package:act_thingsboard/src/model/token_data.dart';
import 'package:act_thingsboard/src/tb_global_manager.dart';
import 'package:act_thingsboard/src/tb_secrets_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

/// Builder for creating the TokenManager
class TokenBuilder extends ManagerBuilder<TokenManager> {
  final Type _tbSecretsManagerDependency;

  /// Class constructor with the class construction
  TokenBuilder({
    @required Type tbSecretsManagerDependency,
  })  : assert(tbSecretsManagerDependency != null),
        _tbSecretsManagerDependency = tbSecretsManagerDependency,
        super(() => TokenManager());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [
        _tbSecretsManagerDependency,
        LoggerManager,
        ServerRequestManager,
      ];
}

/// Events linked to the token management
///
/// [NoValidToken] is sent when the token is detected as no valid; this can only
/// happens after a request to the server
enum TokenEvent { NoValidToken, NewValidToken }

/// Manage token for HTTP client
class TokenManager extends AbstractManager {
  TokenData _tokenData;

  /// This is a mutex to prevent the manager to refresh in parallel the token
  LockUtility _refreshingLock;

  StreamController<TokenEvent> _tokenStreamController;

  SecretItem<String> _serverToken;
  SecretItem<String> _serverRefreshToken;
  SecretItem<String> _serverPassword;
  SecretItem<String> _serverUsername;

  /// Token manager main constructor
  TokenManager() : super() {
    _tokenData = TokenData.init();
    _refreshingLock = LockUtility();
    _tokenStreamController = StreamController<TokenEvent>.broadcast();
  }

  /// Init the token manager and load the token from preferences
  @override
  Future<void> initManager() async {
    var secretsManager = TbGlobalManager.getSecretsManager();

    _serverPassword = secretsManager.thingsboardUserPassword;
    _serverUsername = secretsManager.thingsboardUserEmail;
    _serverToken = secretsManager.thingsboardToken;
    _serverRefreshToken = secretsManager.thingsboardRefreshToken;

    return _loadTokenFromProperties();
  }

  /// To call before instance deleting
  @override
  Future<void> dispose() async {
    return _tokenStreamController.close();
  }

  /// Get token from server
  ///
  /// If the token is being gotten, the method waits before returning a value
  Future<String> getToken() async {
    await _refreshingLock.wait();
    return _tokenData.token;
  }

  /// Get the token validity stream, when the token has changed or is no more
  /// valid, the stream receives a new event
  ///
  /// [NewValidToken] is sent each time a new token is got from server
  Stream<TokenEvent> get tokenValidityStream => _tokenStreamController.stream;

  /// Get the token from server.
  ///
  /// The method will say if it has succeeded to get the token from server, if
  /// it fails or if the credentials aren't correct.
  Future<RequestResult> _getTokenFromServer(
    Uri uri,
    Map<String, String> body,
  ) async {
    _tokenData.clear();

    Tuple2<RequestResult, Response> serverResult =
        await GlobalGetIt().get<ServerRequestManager>().sendHttpRequest(
              command: HttpMethod.post,
              url: uri,
              body: body,
            );

    RequestResult result = await _parseServerResponse(serverResult);

    TokenEvent event = TokenEvent.NoValidToken;

    if (_tokenData.isValid) {
      event = TokenEvent.NewValidToken;
    }

    await _saveTokenToProperties();

    _tokenStreamController.add(event);
    return result;
  }

  /// Parse the response from server when trying to get the token
  Future<RequestResult> _parseServerResponse(
      Tuple2<RequestResult, Response> result) async {
    if (result.item1 == RequestResult.DisconnectFromNetwork ||
        result.item1 == RequestResult.WrongAddress) {
      // No more connected to the network
      return result.item1;
    }

    if (result.item1 != RequestResult.Ok || result.item2 == null) {
      AppLogger().w("An error occurred when tried to sign-in to server");
      return RequestResult.GenericError;
    }

    Response response = result.item2;

    var tmpResponseBody;

    try {
      tmpResponseBody = jsonDecode(response.body);
    } catch (_) {
      AppLogger()
          .w("Can't parsed to JSON, the body received: ${response.body}");
    }

    if (tmpResponseBody == null || (tmpResponseBody is! Map<String, dynamic>)) {
      AppLogger().w("The body received is mal formed: ${response.body}");
      return RequestResult.GenericError;
    }

    Map<String, dynamic> responseBody = tmpResponseBody as Map<String, dynamic>;

    if (response.statusCode == HttpStatus.ok) {
      _tokenData = TokenData.fromJson(responseBody);
      return RequestResult.Ok;
    }

    if (response.statusCode == HttpStatus.unauthorized) {
      var errorCode = responseBody[AbstractConstantsManager.serverErrorCodeKey];

      if (errorCode is int &&
          errorCode == AbstractConstantsManager.serverLoggingErrorCode) {
        AppLogger().w("Wrong user credentials");
        return RequestResult.WrongCredentials;
      }
    }

    AppLogger().w("An error occurred when tried to sign-in to server "
        "${response.toString()}");
    return RequestResult.GenericError;
  }

  /// Load the token from properties
  Future<void> _loadTokenFromProperties() async {
    List<String> tokenValues = await Future.wait([
      _serverToken.load(),
      _serverRefreshToken.load(),
    ]);

    _tokenData.token = tokenValues[0] ?? "";
    _tokenData.refreshToken = tokenValues[1] ?? "";
  }

  /// Save the token to properties
  Future<void> _saveTokenToProperties() async {
    return Future.wait([
      _serverToken.store(_tokenData.token),
      _serverRefreshToken.store(_tokenData.refreshToken)
    ]);
  }

  /// Get credentials from properties and try to sign-in
  Future<RequestResult> _signInFromMemory() async {
    List<String> credentials = await Future.wait([
      _serverUsername.load(),
      _serverPassword.load(),
    ]);

    String username = credentials[0];
    String password = credentials[1];

    if (username == null ||
        password == null ||
        username.isEmpty ||
        password.isEmpty) {
      return RequestResult.GenericError;
    }

    RequestResult result = await _signInToServer(username, password);

    if (result == RequestResult.WrongCredentials) {
      // The credentials are invalid, erase them from memory.
      // Note: username is explicitly kept for getLastSignedInUsername().
      // The deletion of the password is enough to make this credentials pair
      // clearly invalid.
      await Future.wait([
        _serverPassword.delete(),
      ]);
    }

    return result;
  }

  /// Get credentials from properties and try to sign-in
  Future<RequestResult> signInFromMemory() async {
    LockEntity lockEntity = await _refreshingLock.waitAndLock();
    RequestResult result = await _signInFromMemory();
    lockEntity.freeLock();
    return result;
  }

  /// Use credentials given and try to sign-in
  Future<RequestResult> signIn(String username, String password) async {
    LockEntity lockEntity = await _refreshingLock.waitAndLock();

    RequestResult result = await _signInToServer(username, password);

    if (result != RequestResult.Ok) {
      lockEntity.freeLock();
      return result;
    }

    // Because the sign-in has succeeded, try to save data in memory
    await Future.wait([
      _serverUsername.store(username),
      _serverPassword.store(password),
    ]);

    lockEntity.freeLock();
    return RequestResult.Ok;
  }

  /// Internal method to sign-in to server
  Future<RequestResult> _signInToServer(
    String username,
    String password,
  ) async {
    return _getTokenFromServer(
      HttpServerRequest.login.getUrl(),
      {
        'username': username,
        'password': password,
      },
    );
  }

  /// This method forces the refresh of token
  Future<Tuple2<RequestResult, String>> refreshToken() async {
    LockEntity lockEntity = await _refreshingLock.waitAndLock();

    RequestResult result = RequestResult.GenericError;

    if (_tokenData.isValid) {
      result = await _getTokenFromServer(
        HttpServerRequest.tokenRenew.getUrl(),
        {
          'refreshToken': _tokenData.refreshToken,
        },
      );
    }

    if (result == RequestResult.WrongAddress ||
        result == RequestResult.DisconnectFromNetwork) {
      // Useless to go forward
      lockEntity.freeLock();
      return Tuple2(result, "");
    }

    if (result != RequestResult.Ok) {
      result = await _signInFromMemory();
    }

    lockEntity.freeLock();
    return Tuple2(result, _tokenData.token);
  }

  /// This cleans the token from memory
  Future<void> forgetToken() async {
    if (!_tokenData.isValid) {
      // Nothing to do
      return;
    }

    _tokenData.clear();

    await _saveTokenToProperties();

    _tokenStreamController.add(TokenEvent.NoValidToken);
  }

  /// Return server username of latest signed in user.
  Future<String> getLastSignedInUsername() async {
    return _serverUsername.load();
  }
}
