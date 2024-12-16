// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_thingsboard_client/src/act_tb_storage.dart';
import 'package:act_thingsboard_client/src/mixins/mixin_thingsboard_conf.dart';
import 'package:act_thingsboard_client/src/mixins/mixin_thingsboard_secret.dart';
import 'package:act_thingsboard_client/src/models/tb_request_response.dart';
import 'package:act_thingsboard_client/src/thingsboard_manager.dart';
import 'package:mutex/mutex.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Useful method to request Thingsboard in a protective way
class TbRequestService<E extends MixinThingsboardConf, S extends MixinThingsboardSecret>
    extends AbstractService {
  /// Mutex protecting the sign in and avoiding to signIn in parallel
  final Mutex _signInMutex;

  /// This manages the lock linked to the authentication initialisation
  /// This prevent to request the server before having completed the service initialisation
  final LockUtility _authInitLock;

  /// This manages the lock entity linked to the authentication initialisation
  /// This is linked to [_authInitLock]
  late final LockEntity _authInitLockEntity;

  /// The [ThingsboardClient] used to request Thingsboard
  late final ThingsboardClient _tbClient;

  /// Getter to get the linked [ThingsboardClient]
  ThingsboardClient get tbClient => _tbClient;

  /// The logs helper linked to the manager
  late final LogsHelper _logsHelper;

  /// Class constructor
  TbRequestService({
    required LogsHelper logsHelper,
  })  : _logsHelper = logsHelper,
        _signInMutex = Mutex(),
        _authInitLock = LockUtility() {
    unawaited(_authInitLock.waitAndLock().then((value) => _authInitLockEntity = value));
  }

  /// Init the service
  @override
  Future<void> initService() async {
    final hostname = globalGetIt().get<E>().tbHostname.load();
    final port = globalGetIt().get<E>().tbPort.load();

    if (hostname == null) {
      _logsHelper.e("The Thingsboard hostname hasn't been given");
      throw Exception("The Thingsboard hostname hasn't been given");
    }

    final uri = Uri(port: port, host: hostname, scheme: ServerReqConstants.httpsScheme);

    final tbStorage = ActTbStorage<S>(tbSecretManager: globalGetIt().get<S>());

    _tbClient = ThingsboardClient(uri.toString(), storage: tbStorage);

    appLogger().i("Initialize connection to thingsboard service at url: $uri");

    await _initAuthUserAtStart();

    _authInitLockEntity.freeLock();
  }

  /// Get the authenticated user
  ///
  /// The method waits the end of the service initialisation and the end of signing before getting
  /// the value
  Future<AuthUser?> getSafeAuthUser() =>
      _initAndSignInMutexProtect(() async => _tbClient.getAuthUser());

  /// Returns true if a user is currently authenticated
  ///
  /// The method waits the end of the service initialisation and the end of signing before getting
  /// the value
  Future<bool> isSafeAuthenticated() =>
      _initAndSignInMutexProtect(() async => _tbClient.isAuthenticated());

  /// Useful to sign in the current user to its account
  ///
  /// The method waits the end of the service initialisation and the end of signing before getting
  /// the value
  Future<bool> signIn({
    required String username,
    required String password,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
  }) async =>
      _initAndSignInMutexProtect(() async {
        appLogger().d("Try to sign in");
        final secretManager = globalGetIt().get<S>();
        final usernameKey = secretManager.username;
        final passwordKey = secretManager.password;

        await Future.wait([usernameKey.delete(), passwordKey.delete()]);

        final loginResponse = await _safeRequestImpl(
          (tbClient) async => tbClient.login(LoginRequest(username, password)),
          useAuth: false,
          retryRequestIfErrorNb: retryRequestIfErrorNb,
          retryTimeout: retryTimeout,
        );

        if (loginResponse.result != RequestResult.success) {
          _logsHelper
              .w("A problem occurred when tried to sign in the user thanks to the identifiers "
                  "given");
          return false;
        }

        await usernameKey.store(username);
        await passwordKey.store(password);

        return true;
      });

  /// Get the username and password information from memory and sign in the user with it
  ///
  /// The method waits the end of the service initialisation and the end of signing before getting
  /// the value
  Future<bool> signInFromMemory() async {
    await _authInitLock.wait();

    return _signInFromMemoryImpl();
  }

  /// Logout the user and erase the credentials from memory
  ///
  /// This method waits the end of the service initialisation
  Future<void> logout() async {
    await _authInitLock.wait();

    final secretManager = globalGetIt().get<S>();

    await Future.wait([
      _tbClient.logout(),
      secretManager.username.delete(),
      secretManager.password.delete(),
    ]);
  }

  /// This encapsulates the Thingsboard request and allow to do multiple retry request if fails but
  /// also reconnect the user to its account if the tokens are no more valid
  ///
  /// This method waits the end of the service initialisation
  Future<TbRequestResponse<T>> safeRequest<T>(
    TbRequestToCall<T> requestToCall, {
    bool useAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
  }) async {
    await _authInitLock.wait();

    return _safeRequestImpl<T>(
      requestToCall,
      useAuth: useAuth,
      retryRequestIfErrorNb: retryRequestIfErrorNb,
      retryTimeout: retryTimeout,
    );
  }

  /// This encapsulates the Thingsboard request and allow to do multiple retry request if fails but
  /// also reconnect the user to its account if the tokens are no more valid
  Future<TbRequestResponse<T>> _safeRequestImpl<T>(
    TbRequestToCall<T> requestToCall, {
    bool useAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
  }) async {
    var retryRequestNb = 0;
    var loginRetryNb = 0;
    var globalResult = RequestResult.globalError;
    T? tbResult;

    while (globalResult != RequestResult.success && retryRequestNb <= retryRequestIfErrorNb) {
      // We reset the previous specific error
      globalResult = RequestResult.globalError;

      retryRequestNb++;
      (globalResult, tbResult) = (await _safeRequestNoAuth(requestToCall)).toPatterns();

      if (useAuth && globalResult == RequestResult.loginError && loginRetryNb == 0) {
        loginRetryNb++;
        retryRequestNb--;

        // If the Thingsboard methods return a login error, it means that we have to login with
        // username and password
        if (!(await _signInFromMemoryImpl())) {
          _logsHelper.e("There is a problem when tried to log in, may be the logins aren't right?");
          return TbRequestResponse(result: globalResult);
        }
      }

      if (globalResult != RequestResult.success && retryTimeout != null) {
        await Future.delayed(retryTimeout);
      }
    }

    return TbRequestResponse(result: globalResult, requestResponse: tbResult);
  }

  /// The method allows to call Thingsboard request and catches the error throwing from it for
  /// returning [RequestResult] information
  ///
  /// The method doesn't manage the reconnection and/or getting of user tokens
  Future<TbRequestResponse<T>> _safeRequestNoAuth<T>(TbRequestToCall<T> requestToCall) async {
    var result = RequestResult.success;
    T? tbResult;

    try {
      tbResult = await requestToCall(_tbClient);
    } on ThingsboardError catch (error) {
      result = RequestResult.globalError;

      if (error.errorCode == ThingsBoardErrorCode.general) {
        _logsHelper.w("A generic error happens on Thingsboard when tried to request it: $error");
        _logsHelper.w("Source of the error: ${error.error}");
      } else if (error.errorCode == ThingsBoardErrorCode.jwtTokenExpired ||
          error.errorCode == ThingsBoardErrorCode.authentication) {
        result = RequestResult.loginError;
      }
    } catch (error) {
      result = RequestResult.globalError;
      _logsHelper.d("An error occurred when requesting Thingsboard: $error");
    }

    return TbRequestResponse<T>(result: result, requestResponse: tbResult);
  }

  /// Get the username and password information from memory and sign in the user with it
  ///
  /// The method waits the end of signing before getting the value
  Future<bool> _signInFromMemoryImpl() => _signInMutex.protect(() async {
        final secretManager = globalGetIt().get<S>();
        final envManager = globalGetIt().get<E>();
        var username = await secretManager.username.load();
        var password = await secretManager.password.load();

        if (username == null || password == null) {
          // If there is no username and password stored in memory and if a default username/password
          // is defined in local environment, we use them.
          username = envManager.tbDefaultUsername.load();
          password = envManager.tbDefaultPassword.load();
        }

        if (username == null || password == null) {
          _logsHelper.i("Can't sign user from memory: the identifiers aren't stored in app");
          return false;
        }

        final loginResponse = await _safeRequestImpl(
          (tbClient) async => tbClient.login(LoginRequest(username!, password!)),
          useAuth: false,
        );

        if (loginResponse.result != RequestResult.success) {
          _logsHelper
              .w("A problem occurred when tried to sign in the user thanks to the identifiers "
                  "stored in memory");
          return false;
        }

        return true;
      });

  /// Called at start to init the authentication of the app user
  Future<void> _initAuthUserAtStart() async {
    var result = await _safeRequestImpl((tbClient) => tbClient.init());

    // The init method called previously doesn't consider that no JWT tokens in memory is an error
    if (result.result == RequestResult.success && _tbClient.getAuthUser() == null) {
      _logsHelper.d("There is no thingsboard tokens stored in app, we try to sign from memory");

      if (!(await _signInFromMemoryImpl())) {
        result = const TbRequestResponse(result: RequestResult.loginError);
      }
    }

    if (result.result != RequestResult.success) {
      _logsHelper.w("We can't log in to Thingsboard at start of the app.");
    }
  }

  /// The method waits the end of the service initialisation and the end of signing before calling
  /// the given method
  Future<T> _initAndSignInMutexProtect<T>(Future<T> Function() criticalSection) async {
    // We still initializing the service, we wait
    await _authInitLock.wait();

    return _signInMutex.protect(criticalSection);
  }

  /// Dispose the service
  @override
  Future<void> dispose() async {
    await super.dispose();

    await tbClient.logout();
  }
}
