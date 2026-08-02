// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_websocket_core/act_websocket_core.dart';

/// The events an application exchanges over its WebSocket.
enum FakeEvent with MixinStringValueType {
  /// An event whose name on the wire is the one of the enum.
  measure,

  /// An event whose name on the wire differs from the one of the enum.
  deviceState;

  /// {@macro act_dart_utility.MixinStringValueType.stringValueOverride}
  @override
  String? get stringValueOverride => switch (this) {
    FakeEvent.deviceState => "device-state",
    _ => null,
  };
}

/// A service which exchanges the events of an application over a WebSocket.
class FakeWsService extends AbsWithLifeCycle
    with
        MixinWsMsgParserService,
        MixinWsMsgSenderService,
        MixinWsEventMsgParserService<FakeEvent>,
        MixinWsEventMsgSenderService<FakeEvent> {
  /// {@macro act_websocket_core.MixinWsEventMsgParserService.logsHelper}
  @override
  final LogsHelper logsHelper;

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.eventJsonKey}
  @override
  final String eventJsonKey;

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.dataJsonKey}
  @override
  final String dataJsonKey;

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.eventCallbacks}
  @override
  final Map<FakeEvent, EventMessageCallback> eventCallbacks = {};

  /// The messages the service has written on the channel.
  final List<Object?> sentMessages = [];

  /// True when the channel accepts the messages the service writes on it.
  bool isConnected = true;

  /// The raw messages the parser has been given, before any of them is read.
  final List<Object?> rawMessages = [];

  /// Class constructor
  FakeWsService({
    required this.logsHelper,
    this.eventJsonKey = MixinWsEventMsgParserService.defaultJsonEventKey,
    this.dataJsonKey = MixinWsEventMsgParserService.defaultJsonDataKey,
  });

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.eventsList}
  @override
  List<FakeEvent> get eventsList => FakeEvent.values;

  /// Registers [callback] for [event], the way a service of an application does.
  void listenTo(FakeEvent event, EventMessageCallback callback) =>
      registerEventCallback(event, callback);

  /// {@macro act_websocket_core.MixinWsMsgParserService.onRawMessageReceived}
  @override
  // The message received can be a string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<void> onRawMessageReceived(dynamic message) async {
    rawMessages.add(message);

    await super.onRawMessageReceived(message);
  }

  /// {@macro act_websocket_core.MixinWsMsgParserService.sendRawMessage}
  @override
  // The message sent can be a string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<bool> sendRawMessage(dynamic message) async {
    if (!isConnected) {
      return false;
    }

    sentMessages.add(message);

    return true;
  }
}
