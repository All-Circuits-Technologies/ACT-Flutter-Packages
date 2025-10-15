// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_websocket_core/src/mixins/mixin_ws_event_msg_parser_service.dart';
import 'package:act_websocket_core/src/mixins/mixin_ws_msg_sender_service.dart';

/// This is is the WebSocket message parser used to send event message
mixin MixinWsEventMsgSenderService<Event extends MixinStringValueType>
    on MixinWsMsgSenderService, MixinWsEventMsgParserService<Event> {
  /// {@template act_websocket_core.MixinWsEventMsgSenderService.sendMessage}
  /// Send event message through the WebSocket.
  ///
  /// Return false, if the WebSocket isn't connected.
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
        "An error occurred when tried to encode the json message to send to the WebSocket: $error",
      );
    }

    if (strMsg == null) {
      return false;
    }

    return sendRawMessage(strMsg);
  }
}
