// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_websocket_server_manager/act_websocket_server_manager.dart';

/// This mixin adds WebSocket event API service functionalities
mixin MixinWsEventApiService<
  Event extends MixinStringValueType,
  ChService extends AbsWsEventChannelService<Event>
>
    on AbsWebsocketApiService<ChService> {
  /// Send an event message to all connected WebSocket clients
  ///
  /// The method returns true if all messages were sent successfully
  // The message to send can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<bool> sendMessageToAll({required Event event, required dynamic data}) async =>
      FutureUtility.waitGlobalBooleanSuccess(
        channelServices.values.map((service) => service.sendMessage(event: event, data: data)),
      );
}
