// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async' show FutureOr;

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_websocket_core/act_websocket_core.dart';
import 'package:flutter/foundation.dart';

/// This is the callback used to parse the event message
// We don't know the data we receive therefore, we keep a dynamic type for the data
// ignore: avoid_annotating_with_dynamic
typedef EventMessageCallback = FutureOr<void> Function(dynamic data);

/// This is the abstract class to parse the received message by the WebSocket
mixin MixinWsEventMsgParserService<Event extends MixinStringValueType> on MixinWsMsgParserService {
  /// This is the default JSON key for the event attribute
  static const defaultJsonEventKey = "event";

  /// This is the default JSON key for the data attribute
  static const defaultJsonDataKey = "data";

  /// {@template act_websocket_core.MixinWsEventMsgParserService.eventJsonKey}
  /// This is the event json key used to parse the message received
  /// {@endtemplate}
  String get eventJsonKey;

  /// {@template act_websocket_core.MixinWsEventMsgParserService.dataJsonKey}
  /// This is the data json key used to parse the message received
  /// {@endtemplate}
  String get dataJsonKey;

  /// {@template act_websocket_core.MixinWsEventMsgParserService.eventsList}
  /// This is the events list
  /// {@endtemplate}
  List<Event> get eventsList;

  /// {@template act_websocket_core.MixinWsEventMsgParserService.eventCallbacks}
  /// Contains the callbacks linked to the events
  /// {@endtemplate}
  @protected
  Map<Event, EventMessageCallback> get eventCallbacks;

  /// {@template act_websocket_core.MixinWsEventMsgParserService.logsHelper}
  /// The logs helper
  /// {@endtemplate}
  @protected
  LogsHelper get logsHelper;

  /// {@macro act_websocket_core.MixinWsMsgParserService.onRawMessageReceived}
  @override
  // The message received can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<void> onRawMessageReceived(dynamic message) async {
    await super.onRawMessageReceived(message);

    final loggerManager = appLogger();
    if (message is! String && message is! Map<String, dynamic>) {
      logsHelper.w(
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
      logsHelper.w(
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
      logsHelper.w(
        "The message received by the WebSocket doesn't contain an event field, with key: "
        "$eventJsonKey, we can't parse it",
      );
      return;
    }

    if (!eventCallbacks.containsKey(event)) {
      // Nothing to do
      return;
    }

    if (!jsonMsg.containsKey(dataJsonKey)) {
      logsHelper.w(
        "The message received by the WebSocket doesn't contain a data field, with key: "
        "$dataJsonKey, we can't parse it",
      );
      return;
    }

    final callback = eventCallbacks[event]!;
    await callback(jsonMsg[dataJsonKey]);
  }

  /// This method register a callback for the given [event]
  @protected
  void registerEventCallback(Event event, EventMessageCallback callback) {
    eventCallbacks[event] = callback;
  }
}
