// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';

/// This is is the WebSocket message parser
mixin MixinWsMsgParserService on AbsWithLifeCycle {
  /// {@template act_websocket_client_manager.MixinWsMsgParserService.onMessageReceived}
  /// Called when a new message is received
  /// {@endtemplate}
  // The message received can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<void> onMessageReceived(dynamic message);
}
