// Copyright (c) 2020. BMS Circuits

import 'dart:io';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_request_manager/src/data/server_constants.dart';
import 'package:act_server_request_manager/src/request_result.dart';
import 'package:act_server_request_manager/src/x_auth_exception.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Contains helper methods to communicate with the server
class ServerHelper {
  /// Parse a request error to a request result
  ///
  /// [error] can be a [RequestResult], in that case, the method does nothing
  /// and only returns the value given
  /// [error] can be an [Exception], in that case the method analyzes the
  /// exception to understand what need to be returned
  static RequestResult parseRequestError(error) {
    if (error is RequestResult) {
      return error;
    }

    Exception innerError = _getInnerException(error);

    if (innerError is XAuthException || innerError is WebSocketException) {
      AppLogger().w("[SERVER] Wrong connection ids");
      return RequestResult.WrongCredentials;
    }

    if (innerError is SocketException && innerError.osError != null) {
      if (innerError.osError.errorCode ==
              ServerConstants.WsNetworkUnreachableOsErrorCode ||
          innerError.osError.errorCode ==
              ServerConstants.WsNetworkFailedHostLookup ||
          innerError.osError.errorCode ==
              ServerConstants.WsNetworkConnectionConnRefusedErrorCode) {
        // The network is unreachable, no connection tries is used
        AppLogger().w("[SERVER] Cannot establish connection to network");
        return RequestResult.DisconnectFromNetwork;
      }

      if (innerError.osError.errorCode ==
          ServerConstants.WsNetworkConnectionTimeoutOsErrorCode) {
        // Wrong address useless to try to reconnect again and again
        AppLogger().w("[SERVER] Can't connect to server address");
        return RequestResult.WrongAddress;
      }
    }

    AppLogger().w("[SERVER] A generic error occurred in the web socket: "
        "$error");

    return RequestResult.GenericError;
  }

  /// This method allows to go to the source of the [Exception] if it has been
  /// encapsulated in others Exception
  static Exception _getInnerException(exception) {
    if (exception is WebSocketChannelException) {
      var tmpError = _getInnerException(exception.inner);

      if (tmpError == null) {
        return exception;
      }

      return tmpError;
    } else if (exception is Exception) {
      return exception;
    }

    return null;
  }
}
