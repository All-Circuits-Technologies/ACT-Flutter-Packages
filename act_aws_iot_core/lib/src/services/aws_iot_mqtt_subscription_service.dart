// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_aws_iot_core/src/aws_iot_mqtt_sub_watcher.dart';
import 'package:act_aws_iot_core/src/services/abs_aws_iot_service.dart';
import 'package:act_aws_iot_core/src/services/aws_iot_mqtt_service.dart';
import 'package:act_aws_iot_core/src/types/aws_iot_mqtt_sub_event.dart';
import 'package:act_dart_utility/act_dart_utility.dart';

/// This class is the service that manages the MQTT subscriptions.
class AwsIotMqttSubcriptionService extends AbsAwsIotService {
  /// This is the log category for this service.
  static const _logsCategory = 'mqtt_sub';

  /// This is the map of all the subscription watchers.
  final Map<String, AwsIotMqttSubWatcher> _watchers;

  /// This is the [AwsIotMqttService] to use.
  ///
  /// It will be used to create the subscription watchers.
  final AwsIotMqttService _mqttService;

  /// This is the stream subscription for the connection status changes events.
  final List<StreamSubscription> _streamSubscriptions;

  /// Class constructor
  AwsIotMqttSubcriptionService({
    required AwsIotMqttService mqttService,
    required super.iotManagerLogsHelper,
  })  : _mqttService = mqttService,
        _watchers = <String, AwsIotMqttSubWatcher>{},
        _streamSubscriptions = <StreamSubscription>[],
        super(
          logsCategory: _logsCategory,
        ) {
    _streamSubscriptions.add(
      mqttService.connectionStatusStream.listen(_onConnectionStatusChanged),
    );
    _streamSubscriptions.add(
      mqttService.onSubEventStream.listen(_onSubEvent),
    );
    _streamSubscriptions.add(
      mqttService.onMessageReceivedStream.listen(_onMsgReceived),
    );
  }

  /// Initialize the service but there is nothing to do here.
  @override
  Future<void> initService() async {}

  /// Test if we are subscribed to all the current topic.
  ///
  /// This doesn't wait if a subscription is processing.
  Future<bool> isAllSubscribed() => FutureUtility.waitGlobalBooleanSuccess(
      _watchers.values.map((value) => value.isSubscribed(defaultValue: false)));

  /// Get a subscription watcher for a given topic.
  AwsIotMqttSubWatcher getWatcher(String topic) {
    // Add the watcher if it does not exist.
    if (!_watchers.containsKey(topic)) {
      _watchers[topic] = AwsIotMqttSubWatcher(
        topic: topic,
        awsIotMqttService: _mqttService,
      );
    }

    return _watchers[topic]!;
  }

  /// Handles the connection status changes.
  Future<void> _onConnectionStatusChanged(bool isConnected) async {
    if (isConnected) {
      for (final watcher in _watchers.values) {
        await watcher.onConnected();
      }
    } else {
      for (final watcher in _watchers.values) {
        watcher.onDisconnected();
      }
    }
  }

  /// Handles events related to the subscriptions (subscribed, unsubscribed and sub failed).
  void _onSubEvent(({String topic, AwsIotMqttSubEvent evt}) subEvent) =>
      _watchers[subEvent.topic]?.onSubEvent(subEvent.evt);

  /// Handles the messages received on the topic.
  void _onMsgReceived(({String topic, String msg}) mqttMsg) =>
      _watchers[mqttMsg.topic]?.onMsgCb(mqttMsg.msg);

  /// Dispose the service.
  @override
  Future<void> dispose() async {
    // Close the watchers.
    for (final watcher in _watchers.values) {
      await watcher.close();
    }

    // Dispose the subscriptions.
    for (final sub in _streamSubscriptions) {
      await sub.cancel();
    }

    return super.dispose();
  }
}
