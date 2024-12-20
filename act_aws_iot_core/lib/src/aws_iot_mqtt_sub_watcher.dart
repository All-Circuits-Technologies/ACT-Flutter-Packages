// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_aws_iot_core/src/services/aws_iot_mqtt_service.dart';
import 'package:act_aws_iot_core/src/types/aws_iot_mqtt_sub_event.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter/widgets.dart';

/// This class is responsible for subscribing to a topic and forwarding the messages / events to
/// the handlers.
class AwsIotMqttSubWatcher extends SharedWatcher<AwsIotMqttSubHandler> {
  /// This is the topic to subscribe to.
  final String _topic;

  /// This is the [AwsIotMqttService] to use
  final AwsIotMqttService _awsIotMqttService;

  /// This is the stream controller used to publish the messages received on the topic associated
  /// with this subscription watcher.
  final StreamController<String> _onMsgController;

  /// This is the stream controller used to publish the events related to the subscription.
  final StreamController<AwsIotMqttSubEvent> _onSubscriptionEventController;

  /// This completer is completed once the subscription is done (either successful or not).
  ///
  /// It is null at creation and is created but not completed during the subscription process.
  Completer<bool> _subCompleter;

  /// This completer is completed once the unscription is done (either successful or not).
  ///
  /// It is null at creation and is created but not completed during the unsubscription process.
  Completer<bool> _unsubCompleter;

  /// Get the [Stream] of the [_onMsgController].
  Stream<String> get onMsgStream => _onMsgController.stream;

  /// Get the [Stream] of the [_onSubscriptionEventController].
  Stream<AwsIotMqttSubEvent> get onEventStream => _onSubscriptionEventController.stream;

  /// Class contrusctor
  AwsIotMqttSubWatcher({
    required String topic,
    required AwsIotMqttService awsIotMqttService,
  })  : _topic = topic,
        _awsIotMqttService = awsIotMqttService,
        _onMsgController = StreamController.broadcast(),
        _onSubscriptionEventController = StreamController.broadcast(),
        _subCompleter = Completer(),
        _unsubCompleter = Completer();

  /// Get the subscription completer
  ///
  /// If the completer is not completed and [defaultValue] is not null, this will return the
  /// [defaultValue] instead of waiting the completion.
  Future<bool> isSubscribed({
    bool? defaultValue,
  }) async {
    if (_subCompleter.isCompleted || defaultValue == null) {
      return _subCompleter.future;
    }

    return defaultValue;
  }

  /// Get the unsubscription completer or false if the unsubscription is not ongoing.
  ///
  /// If the completer is not completed and [defaultValue] is not null, this will return the
  /// [defaultValue] instead of waiting the completion.
  Future<bool> isUnsubscribed({
    bool? defaultValue,
  }) async {
    if (_unsubCompleter.isCompleted || defaultValue == null) {
      return _unsubCompleter.future;
    }

    return defaultValue;
  }

  /// DO NOT CALL THIS METHOD DIRECTLY. Use [getHandler] instead.
  @Deprecated("Use getHandler instead, this method won't work as expected.")
  @override
  AwsIotMqttSubHandler generateHandler() => AwsIotMqttSubHandler(
        onMsgCb: (_) => {},
        sharedWatcher: this,
      );

  /// This method generates a handler for the subscription watcher.
  AwsIotMqttSubHandler getHandler({
    required Function(String) onMsgCb,
    Function(AwsIotMqttSubEvent)? onEventCb,
  }) =>
      AwsIotMqttSubHandler(
        sharedWatcher: this,
        onMsgCb: onMsgCb,
        onEventCb: onEventCb,
      );

  /// Subscribe to the topic when the watcher wakes up.
  @override
  Future<void> atFirstHandler() async {
    await _subscribe();
  }

  /// Unsubscribe from the topic when the watcher goes to sleep.
  @override
  Future<void> whenNoMoreHandler() async {
    await _unsubscribe();
  }

  /// This method is called whenever an event related to the subscription is received.
  void onSubEvent(AwsIotMqttSubEvent evt) {
    switch (evt) {
      case AwsIotMqttSubEvent.subscribed:
        _unsubCompleter = Completer();
        _subCompleter.complete(true);
        break;

      case AwsIotMqttSubEvent.subscriptionFailed:
        _subCompleter.complete(false);
        break;

      case AwsIotMqttSubEvent.unsubscribed:
        _subCompleter = Completer();
        _unsubCompleter.complete(true);
        break;
    }
    _onSubscriptionEventController.add(evt);
  }

  /// This method is called whenever a message is received on the topic.
  /// It publishes the message on the stream.
  void onMsgCb(String message) {
    _onMsgController.add(message);
  }

  /// This method is called when we connect to the broker.
  ///
  /// It subscribes to the topic if the watcher is awake.
  Future<void> onConnected() async {
    if (state == WatcherState.awake) {
      await _subscribe();
    }
  }

  /// This method is called when we lose the connection to the broker.
  void onDisconnected() {
    _subCompleter = Completer();
    _unsubCompleter = Completer();
  }

  /// This method tries to subscribe to the topic. If the subscription is already ongoing, it does
  /// nothing but waiting for the subscription to be done.
  Future<bool> _subscribe() async {
    if (!_subCompleter.isCompleted) {
      // If the subscription is already done, there is no need to subscribe again.

      // Start the subscription.
      final isSubscribeStarted = _awsIotMqttService.subscribe(_topic);
      if (!isSubscribeStarted) {
        // If we failed to start the subscription, there is no need to wait for the subscription to
        // be done.
        return false;
      }
    }

    // Wait for the subscription to be done.
    return _subCompleter.future;
  }

  /// This method tries to unsubscribe from the topic. If the unsubscription is already ongoing, it
  /// does nothing but waiting for the unsubscription to be done.
  Future<bool> _unsubscribe() async {
    if (!_unsubCompleter.isCompleted) {
      // Start the unsubscription.
      final isUnsubscribeStarted = _awsIotMqttService.unsubscribe(_topic);
      if (!isUnsubscribeStarted) {
        // If we failed to start the unsubscription, there is no need to wait for the unsubscription
        // to be done.
        return false;
      }
    }

    // Wait for the unsubscription to be done.
    return _unsubCompleter.future;
  }

  /// Call this method to close the subscription watcher.
  @override
  @mustCallSuper
  Future<void> close() async {
    await _onMsgController.close();
    await _onSubscriptionEventController.close();
    await super.close();
  }
}

/// This class is responsible for handling the messages and events received by the subscription
class AwsIotMqttSubHandler extends SharedHandler {
  /// This is the stream subscription to the messages.
  final StreamSubscription<String> _onMsgStreamSub;

  /// This is the stream subscription to the events.
  final StreamSubscription<AwsIotMqttSubEvent>? _onEventStreamSub;

  /// Class constructor
  AwsIotMqttSubHandler({
    required AwsIotMqttSubWatcher sharedWatcher,
    required Function(String) onMsgCb,
    Function(AwsIotMqttSubEvent)? onEventCb,
  })  : _onMsgStreamSub = sharedWatcher.onMsgStream.listen(onMsgCb),
        _onEventStreamSub =
            onEventCb == null ? null : sharedWatcher.onEventStream.listen(onEventCb),
        super(sharedWatcher);

  /// Call this method to close the handler.
  @override
  Future<void> close() async {
    await _onMsgStreamSub.cancel();
    await _onEventStreamSub?.cancel();
    await super.close();
  }
}
