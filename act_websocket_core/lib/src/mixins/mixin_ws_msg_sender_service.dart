// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';

/// This is is the WebSocket message sender service
mixin MixinWsMsgSenderService on AbsWithLifeCycle {
  /// {@template act_websocket_core.MixinWsMsgParserService.sendRawMessage}
  /// Send a raw message to the WebSocket channel
  ///
  /// Returns false if an error occurred and the message hasn't been sent
  /// {@endtemplate}
  // The message received can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<bool> sendRawMessage(dynamic message);
}
