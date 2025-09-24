// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_web_socket_manager/act_web_socket_manager.dart';
import 'package:flutter/foundation.dart';

/// This is is the web socket message parser used to send event message
mixin MixinWsSendEventParserService<Event extends MixinStringValueType>
    on AbsWsEventMsgParser<Event> {
  /// This is the web socket manager linked to the parser
  @protected
  WebSocketManager get wsManager;

  /// {@template act_web_socket_manager.MixinWsSendEventParserService.sendMessage}
  /// Send event message through the web socket.
  ///
  /// Return false, if the web socket isn't connected.
  /// {@endtemplate}
  // The message sent can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<bool> sendMessage({required Event event, required dynamic data}) async {
    final jsonMsg = {eventJsonKey: event.stringValue, dataJsonKey: data};

    String? strMsg;
    try {
      strMsg = jsonEncode(jsonMsg);
    } catch (error) {
      logsHelper.w(
        "An error occurred when tried to encode the json message to send to the web socket: $error",
      );
    }

    if (strMsg == null) {
      return false;
    }

    return wsManager.sendMessage(strMsg);
  }
}
