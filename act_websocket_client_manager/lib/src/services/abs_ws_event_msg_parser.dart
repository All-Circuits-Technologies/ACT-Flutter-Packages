// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async' show FutureOr;

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_websocket_client_manager/src/mixins/mixin_ws_msg_parser_service.dart';
import 'package:flutter/cupertino.dart';

/// This is the callback used to parse the event message
// We don't know the data we receive therefore, we keep a dynamic type for the data
// ignore: avoid_annotating_with_dynamic
typedef EventMessageCallback = FutureOr<void> Function(dynamic data);

/// This is the abstract class to parse the received message by the WebSocket
abstract class AbsWsEventMsgParser<Event extends MixinStringValueType> extends AbsWithLifeCycle
    with MixinWsMsgParserService {
  /// This is the default JSON key for the event attribute
  static const defaultJsonEventKey = "event";

  /// This is the default JSON key for the data attribute
  static const defaultJsonDataKey = "data";

  /// This is the event json key used to parse the message received
  final String eventJsonKey;

  /// This is the data json key used to parse the message received
  final String dataJsonKey;

  /// Contains the callbacks linked to the events
  final Map<Event, EventMessageCallback> _eventCallbacks;

  /// This is the events list
  final List<Event> eventsList;

  /// This is the logs helper of the message parser
  final LogsHelper _logsHelper;

  /// Get the logs helper value
  @protected
  LogsHelper get logsHelper => _logsHelper;

  /// Class constructor
  AbsWsEventMsgParser({
    required this.eventsList,
    required String logsCategory,
    LogsHelper? parentLogger,
    this.eventJsonKey = defaultJsonEventKey,
    this.dataJsonKey = defaultJsonDataKey,
  }) : _logsHelper =
           parentLogger?.createASubLogsHelper(logsCategory) ??
           LogsHelper(logsManager: appLogger(), logsCategory: logsCategory),
       _eventCallbacks = {};

  /// {@macro act_websocket_client_manager.MixinWsMsgParserService.onMessageReceived}
  @override
  // The message received can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<void> onMessageReceived(dynamic message) async {
    final loggerManager = appLogger();
    if (message is! String && message is! Map<String, dynamic>) {
      _logsHelper.w(
        "The message received by the WebSocket isn't a string or JSON object; therefore we can't "
        "parse it",
      );
      return;
    }

    var jsonMsg = message;

    if (jsonMsg is String) {
      jsonMsg = JsonUtility.parseJsonBodyToObj(jsonMsg, loggerManager: loggerManager);
    }

    if (jsonMsg == null || jsonMsg is! Map<String, dynamic>) {
      _logsHelper.w(
        "The message received by the WebSocket isn't a JSON object; therefore we can't parse "
        "it",
      );
      return;
    }

    final event = JsonUtility.getNotNullOneElement<Event, String>(
      json: jsonMsg,
      key: eventJsonKey,
      loggerManager: loggerManager,
      castValueFunc: (toCast) =>
          MixinStringValueType.tryToParseFromStringValue(value: toCast, values: eventsList),
    );
    if (event == null) {
      _logsHelper.w(
        "The message received by the WebSocket doesn't contain an event field, with key: "
        "$eventJsonKey, we can't parse it",
      );
      return;
    }

    if (!_eventCallbacks.containsKey(event)) {
      // Nothing to do
      return;
    }

    if (!jsonMsg.containsKey(dataJsonKey)) {
      _logsHelper.w(
        "The message received by the WebSocket doesn't contain a data field, with key: "
        "$dataJsonKey, we can't parse it",
      );
      return;
    }

    final callback = _eventCallbacks[event]!;
    await callback(jsonMsg[dataJsonKey]);
  }

  /// This method register a callback for the given [event]
  @protected
  void registerEventCallback(Event event, EventMessageCallback callback) {
    _eventCallbacks[event] = callback;
  }
}
