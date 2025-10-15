// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_websocket_core/act_websocket_core.dart';

/// This is the abstract class to parse the received message by the WebSocket
abstract class AbsWsEventMsgParser<Event extends MixinStringValueType> extends AbsWithLifeCycle
    with MixinWsMsgParserService, MixinWsEventMsgParserService<Event> {
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
  AbsWsEventMsgParser({
    required this.eventsList,
    required String logsCategory,
    LogsHelper? parentLogger,
    this.eventJsonKey = MixinWsEventMsgParserService.defaultJsonEventKey,
    this.dataJsonKey = MixinWsEventMsgParserService.defaultJsonDataKey,
  }) : logsHelper =
           parentLogger?.createASubLogsHelper(logsCategory) ??
           LogsHelper(logsManager: appLogger(), logsCategory: logsCategory),
       eventCallbacks = {};
}
