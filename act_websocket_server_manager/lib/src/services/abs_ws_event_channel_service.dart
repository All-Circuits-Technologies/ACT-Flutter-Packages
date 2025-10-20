// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_websocket_core/act_websocket_core.dart';
import 'package:act_websocket_server_manager/src/services/abs_websocket_channel_service.dart';

/// This is the abstract class to manage a specific WebSocket channel with events
abstract class AbsWsEventChannelService<Event extends MixinStringValueType>
    extends AbsWebsocketChannelService
    with MixinWsEventMsgParserService<Event>, MixinWsEventMsgSenderService<Event> {
  /// This is the logs category for the WebSocket event channel service
  static const _eventLogsCategory = "wsEvent";

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.eventJsonKey}
  @override
  final String eventJsonKey;

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.dataJsonKey}
  @override
  final String dataJsonKey;

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.eventsList}
  @override
  final List<Event> eventsList;

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.eventCallbacks}
  @override
  final Map<Event, EventMessageCallback> eventCallbacks;

  /// {@macro act_websocket_core.MixinWsEventMsgParserService.logsHelper}
  @override
  final LogsHelper logsHelper;

  /// Class constructor
  AbsWsEventChannelService({
    required super.webSocket,
    required super.httpLoggingManager,
    required super.onClose,
    required this.eventsList,
    this.eventJsonKey = MixinWsEventMsgParserService.defaultJsonEventKey,
    this.dataJsonKey = MixinWsEventMsgParserService.defaultJsonDataKey,
  }) : logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _eventLogsCategory),
       eventCallbacks = {};
}
