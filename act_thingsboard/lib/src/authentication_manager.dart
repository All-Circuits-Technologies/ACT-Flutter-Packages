// Copyright (c) 2020. BMS Circuits

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_request_manager/act_server_request_manager.dart';
import 'package:act_thingsboard/act_thingsboard.dart';
import 'package:act_thingsboard/src/http/http_request_maker.dart';
import 'package:act_thingsboard/src/model/user.dart';
import 'package:act_thingsboard/src/token_manager.dart';
import 'package:act_thingsboard/src/ws/web_socket_manager.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

/// Builder for creating the AuthenticationManager
class AuthenticationBuilder extends ManagerBuilder<AuthenticationManager> {
  /// Class constructor with the class construction
  AuthenticationBuilder() : super(() => AuthenticationManager());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [TokenManager, WebSocketManager];
}

/// The authentication manager keeps the current user and contains useful
/// methods to sign-in, sign-up, manage password, etc...
class AuthenticationManager extends AbstractManager {
  User _currentUser;
  StreamController<bool> _authenticatedStreamController;

  /// This is a mutex to prevent the manager to get the user in parallel
  LockUtility _gettingUser;

  bool _stillInit;

  bool get isStillInit => _stillInit;

  /// Default constructor
  AuthenticationManager() : super() {
    _gettingUser = LockUtility();
    _stillInit = true;
  }

  Future<Tuple2<RequestResult, User>> get currentUser async {
    await _gettingUser.wait();

    if (_currentUser != null) {
      return Tuple2(RequestResult.Ok, _currentUser);
    }

    return Tuple2(await _getCurrentUser(), _currentUser);
  }

  /// Init the authentication manager and if credentials have been previously
  /// saved, try to get the current user
  @override
  Future<void> initManager() async {
    _authenticatedStreamController = StreamController<bool>.broadcast();

    GlobalGetIt()
        .get<TokenManager>()
        .tokenValidityStream
        .listen(_onNewTokenEvent);

    // Don't await here, because if a problem occurs or the connection is too
    // long this will make all the init process wait for the result of this
    unawaited(_manageGettingUserAtStart());
  }

  /// Manage the user getting at start
  ///
  /// If token is invalid, get token from stored username and password and
  /// sign-in
  /// if there is no username and password stored, do nothing
  ///
  /// After to have get the token, get the current user data
  Future<void> _manageGettingUserAtStart() async {
    var tokenManager = GlobalGetIt().get<TokenManager>();

    String token = await tokenManager.getToken();

    RequestResult result = RequestResult.Ok;

    if (token == null || token.isEmpty) {
      result = await tokenManager.signInFromMemory();
    }

    if (result == RequestResult.Ok) {
      result = await _getCurrentUser();
    }

    if (result == RequestResult.DisconnectFromNetwork) {
      // In that case, force the retry connection to server
      _stillInit = false;
      return GlobalGetIt().get<WebSocketManager>().connect();
    } else if (result != RequestResult.Ok) {
      _authenticatedStreamController.add(false);
    }

    _stillInit = false;
  }

  /// Get the current user linked to the current token
  Future<RequestResult> _getCurrentUser() async {
    LockEntity lock = await _gettingUser.waitAndLock();

    if (_currentUser != null) {
      // Nothing to do we already have the current user
      lock.freeLock();
      return RequestResult.Ok;
    }

    Tuple2<RequestResult, User> result =
        await HttpRequestMaker.getCurrentUser();

    if (result.item1 != RequestResult.Ok) {
      AppLogger().w("A problem occurred when tried to get the current "
          "user data");
      lock.freeLock();
      return result.item1;
    }

    _setCurrentUser(result.item2);

    lock.freeLock();
    return RequestResult.Ok;
  }

  /// Sign-in method to use by HMI
  ///
  /// The [username] and [password] parameters are given by user
  Future<RequestResult> signIn(String username, String password) async {
    RequestResult result =
        await GlobalGetIt().get<TokenManager>().signIn(username, password);

    if (result != RequestResult.Ok) {
      return result;
    }

    return _getCurrentUser();
  }

  /// Logout the current user
  Future<void> logout() async {
    await Future.wait([
      // Useless to set current user to NULL, because the token manager will
      // generate an event, which will fire an erase of the current user
      GlobalGetIt().get<TokenManager>().forgetToken(),
      TbGlobalManager.getSecretsManager().thingsboardUserPassword.delete(),
      // We delete the current value of the devices list, because we change of
      // user and we don't want to keep those values in memory
      TbGlobalManager.getPropertiesManager().devicesList.delete()
    ]);
  }

  /// Change user's current password to [newPassword]
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // Query server to change password
    RequestResult result =
        await HttpRequestMaker.changePassword(currentPassword, newPassword);

    if (result != RequestResult.Ok) {
      return false;
    }

    // Store new password
    await TbGlobalManager.getSecretsManager()
        .thingsboardUserPassword
        .store(newPassword);

    return true;
  }

  /// Get the Thingsboard username of latest signed in user, if any.
  ///
  /// Note: If a user is currently signed in, its email is returned.
  /// Note: Thingsboard "usernames" are actually emails.
  Future<String> getLastSignedInUsername() async {
    return GlobalGetIt().get<TokenManager>().getLastSignedInUsername();
  }

  /// Called when a [TokenEvent] is emitted
  ///
  /// If the token is no more valid, this will consider that the user is
  /// disconnected
  void _onNewTokenEvent(TokenEvent event) {
    if (event == TokenEvent.NoValidToken) {
      // Because the TokenManager can be retying to load token we wait the
      // process before saying that we are disconnected
      GlobalGetIt().get<TokenManager>().getToken().then((token) {
        if (token == null || token.isEmpty) {
          _setCurrentUser(null);
        }
      });
    } else if (event == TokenEvent.NewValidToken && !isAuthenticated) {
      _getCurrentUser();
    }
  }

  /// Set the current user and emit an event to inform the user connection or
  /// disconnection
  void _setCurrentUser(User user) {
    bool wasNull = (_currentUser == null);

    _currentUser = user;

    if (wasNull != (user == null)) {
      var wsManager = GlobalGetIt().get<WebSocketManager>();

      if (wasNull) {
        // In that case, no user was connected; therefore it wasn't possible to
        // connect to the web socket. But now, an user is connected, so we can
        // connect
        wsManager.connect();
      } else {
        // We are no more authenticated, in that case we disconnect the web
        // socket
        wsManager.disconnect();
      }

      _authenticatedStreamController.add(isAuthenticated);
    }
  }

  /// Reset current password and change it with [password].
  /// This function is in case of password forgotten.
  ///
  /// It can be called when authenticated and have forgotten your password -> your new password is stored
  /// or when not authenticated and have forgotten your password -> your new password is not stored (and will be stored on connection).
  /// Requires the [resetToken] retrieved from user's mail.
  Future<bool> resetPassword(String password, String resetToken) async {
    RequestResult result = await HttpRequestMaker.resetPassword(
      password,
      resetToken,
    );

    if (result != RequestResult.Ok) {
      return false;
    }

    if (isAuthenticated) {
      await TbGlobalManager.getSecretsManager()
          .thingsboardUserPassword
          .store(password);
    }

    return true;
  }

  /// Change email
  Future<bool> changeEmail(String email) async {
    // Retrieve current password
    Tuple2<RequestResult, User> tupleUser = await currentUser;

    if (tupleUser.item1 != RequestResult.Ok) {
      return false;
    }

    User newUser = tupleUser.item2;
    newUser.email = email;

    // Query server to change email
    Tuple2<RequestResult, User> result = await HttpRequestMaker.saveUserData(
      newUser,
      true,
    );

    if (result.item1 != RequestResult.Ok) {
      return false;
    }

    User user = result.item2;

    // Store new email
    await TbGlobalManager.getSecretsManager()
        .thingsboardUserEmail
        .store(user.email);

    return true;
  }

  /// Test if the user is authenticated
  bool get isAuthenticated => (_currentUser != null);

  /// The authenticated stream to receive event when the authentication changes
  Stream<bool> get authenticatedStream => _authenticatedStreamController.stream;
}
