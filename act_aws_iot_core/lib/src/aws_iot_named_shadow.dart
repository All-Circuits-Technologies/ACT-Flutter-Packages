// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_aws_iot_core/src/aws_iot_mqtt_sub_watcher.dart';
import 'package:act_aws_iot_core/src/models/aws_iot_shadow_state_model.dart';
import 'package:act_aws_iot_core/src/services/aws_iot_mqtt_service.dart';
import 'package:act_aws_iot_core/src/types/aws_iot_mqtt_sub_event.dart';
import 'package:act_aws_iot_core/src/types/shadow_topics_enum.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// This class is used to interact with a named shadow on the aws iot core service.
class AwsIotNamedShadow {
  /// This is duration to wait for the shadow to respond to a request
  static const _shadowRequestTimeout = Duration(seconds: 10);

  /// This is the duration to wait for a subscription to be done
  static const _subscriptionTimeout = Duration(seconds: 5);

  /// This is the mqtt client that will be used to interact with the shadow
  final AwsIotMqttService _mqttService;

  /// LogsHelper instance to use for logging
  final LogsHelper _logsHelper;

  /// This map contains all the topic names for the shadow
  final Map<ShadowTopicsEnum, String> topicNames;

  /// This map contains all the [AwsIotMqttSubWatcher] instances for the shadow
  final Map<ShadowTopicsEnum, AwsIotMqttSubWatcher> _topicWatchers;

  /// This stream controller publishes the reported state of the shadow when it changes
  final StreamController<Map<String, dynamic>> _reportedStateStreamController;

  /// This stream controller publishes the desired state of the shadow when it changes
  final StreamController<Map<String, dynamic>> _desiredStateStreamController;

  /// This handler is used to handle "update/accepted" and update
  /// the shadow state according to the message content.
  /// It is late because we obtain it asynchronously thefore it is created in the [init] method
  late final AwsIotMqttSubHandler _updateAcceptedHandler;

  /// Same as [_updateAcceptedHandler] but for "get/accepted"
  late final AwsIotMqttSubHandler _getAcceptedHandler;

  /// This is the state of the shadow. It must only be modified through the [_updateState] method
  AwsIotShadowStateModel _state;

  /// This getter provides the current reported state of the shadow
  Map<String, dynamic> get reportedState => _state.reportedState;

  /// This getter provides the current desired state of the shadow
  Map<String, dynamic> get desiredState => _state.desiredState;

  /// This getter provides the current version of the shadow
  int get version => _state.version;

  /// This getter provides the stream of the reported state of the shadow
  Stream<Map<String, dynamic>> get reportedStateStream => _reportedStateStreamController.stream;

  /// This getter provides the stream of the desired state of the shadow
  Stream<Map<String, dynamic>> get desiredStateStream => _desiredStateStreamController.stream;

  /// This is the factory method to create a new instance of the shadow for a given [thingName] and
  /// [shadowName]. It will create the shadow topics, subscribe to them and initialize the shadow
  /// state.
  factory AwsIotNamedShadow({
    required AwsIotMqttService mqttService,
    required LogsHelper logsHelper,
    required String thingName,
    required String shadowName,
  }) {
    // Build the map of topics names from the thing and shadow names
    final topicNames = ShadowTopicsEnum.buildAllTopicsName(thingName, shadowName);

    // Build the map of [AwsIotMqttSubWatcher] instances for the shadow
    final topicWatchers = <ShadowTopicsEnum, AwsIotMqttSubWatcher>{};
    for (final topicKey in topicNames.keys) {
      topicWatchers[topicKey] = mqttService.getSubscriptionWatcher(topicNames[topicKey]!);
    }

    // Create a new LogsHelper instance for the shadow based on it's name
    final sublogerSuffix = '${thingName.toLowerCase()}-${shadowName.toLowerCase()}';
    final shadowLogger = logsHelper.createASubLogsHelper(sublogerSuffix);

    return AwsIotNamedShadow._(
      topicNames: topicNames,
      mqttService: mqttService,
      logsHelper: shadowLogger,
      topicsStream: topicWatchers,
    );
  }

  /// Class constructor
  AwsIotNamedShadow._({
    required this.topicNames,
    required AwsIotMqttService mqttService,
    required LogsHelper logsHelper,
    required Map<ShadowTopicsEnum, AwsIotMqttSubWatcher> topicsStream,
  })  : _mqttService = mqttService,
        _logsHelper = logsHelper,
        _topicWatchers = topicsStream,
        _state = AwsIotShadowStateModel.empty(),
        _reportedStateStreamController = StreamController.broadcast(),
        _desiredStateStreamController = StreamController.broadcast();

  /// This method initializes the shadow by subscribing to the shadow topics
  Future<void> init() async {
    _updateAcceptedHandler =
        _getHandler(ShadowTopicsEnum.updateAccepted, onMsgCb: _onGetUpdateAccepted);
    _getAcceptedHandler = _getHandler(
      ShadowTopicsEnum.getAccepted,
      onMsgCb: _onGetUpdateAccepted,
      onSubscriptionEventCb: _onUpdateAcceptedSubscriptionEvent,
    );

    // Try to sync the shadow state with the aws shadow service
    unawaited(requestGet());
  }

  /// Ask the aws shadows service to publish the update request
  Future<bool> requestGet() async {
    _logsHelper.d('Requesting the shadow state');

    return _requestWithResponse(
      requestTopic: ShadowTopicsEnum.get,
      acceptedTopic: ShadowTopicsEnum.getAccepted,
      rejectedTopic: ShadowTopicsEnum.getRejected,
      stringJsonPayload: '', // The get request has an empty payload
      onAccepted: (_) => true,
      onRejected: (message) {
        _logsHelper.e('Get request was rejected with msg: $message');
        return false;
      },
    );
  }

  /// Request un update of the shadow's desired state
  Future<bool> requestUpdate(Map<String, dynamic> desiredState) async {
    _logsHelper.d('Requesting an update of the shadow desired state');

    final clientToken = _generateClientToken();

    final jsonPayload = _state.getJsonForUpdateRequest(desiredState, clientToken);
    if (jsonPayload == null) {
      _logsHelper.e('There is no change in the requested new desired state');
      return false;
    }

    return _requestWithResponse(
      requestTopic: ShadowTopicsEnum.update,
      acceptedTopic: ShadowTopicsEnum.updateAccepted,
      rejectedTopic: ShadowTopicsEnum.updateRejected,
      stringJsonPayload: jsonPayload,
      onAccepted: (message) {
        final isClientTokenValid = AwsIotShadowStateModel.isClientTokenValid(
          message,
          clientToken,
        );

        if (!isClientTokenValid) {
          _logsHelper.w('Update answer was ignored since the client token doesnt match');
          return null;
        }

        _logsHelper.d('Update request was accepted');
        return true;
      },
      onRejected: (message) {
        _logsHelper.e('Update request was rejected with msg: $message');
        return false;
      },
    );
  }

  /// This method performs a request on the provided [requestTopic] with a [stringJsonPayload] and
  /// waits for a response on the [acceptedTopic] or [rejectedTopic]. When a response is received on
  /// one of the response topics, the [onAccepted] or [onRejected] callbacks are called with the
  /// message content. They must return a boolean indicating if the request was successful or not
  /// allowing the method to return the result.
  Future<bool> _requestWithResponse({
    required ShadowTopicsEnum requestTopic,
    required ShadowTopicsEnum acceptedTopic,
    required ShadowTopicsEnum rejectedTopic,
    required String stringJsonPayload,
    required bool? Function(String) onAccepted,
    required bool? Function(String) onRejected,
  }) async {
    final requestResultCompleter = Completer<bool>();

    final handlerAccepted = _getHandler(
      acceptedTopic,
      onMsgCb: (message) {
        final result = onAccepted(message);
        if (result != null) {
          requestResultCompleter.complete(result);
        }
      },
    );
    final handlerRejected = _getHandler(
      rejectedTopic,
      onMsgCb: (message) {
        final result = onRejected(message);
        if (result != null) {
          requestResultCompleter.complete(result);
        }
      },
    );

    // We try to wait for the subscriptions to be done but we don't check the result because even
    // if one of them fails, we might still get an answer on the other one
    // Anyways, we will timeout on requestResultCompleter.future so it's not a big deal
    await Future.wait([
      _waitSubscribed(acceptedTopic),
      _waitSubscribed(rejectedTopic),
    ]);

    final isRequestPublished = await _publish(
      requestTopic,
      stringJsonPayload,
    );
    if (!isRequestPublished) {
      // If we failed to publish (likely because the mqtt client is not connected), we don't need
      // to wait for the shadow to respond
      _logsHelper.e('Failed to publish the get request');

      // Check if the completer is still waiting for a result
      // In some case the request might have been completed by the subscription event
      // before we could complete it here
      if (!requestResultCompleter.isCompleted) {
        requestResultCompleter.complete(false);
      }
    }

    final result = await requestResultCompleter.future.timeout(
      _shadowRequestTimeout,
      onTimeout: () {
        _logsHelper.e('Request update timed out');
        return false;
      },
    );

    await Future.wait([
      handlerAccepted.close(),
      handlerRejected.close(),
    ]);

    return result;
  }

  /// This method handles the "update/accepted" and "get/accepted" topic messages and updates the
  /// shadow state accordingly.
  Future<void> _onGetUpdateAccepted(String message) async {
    final newState = _state.copyAfterAcceptedGetUpdate(message);

    if (newState == null) {
      _logsHelper.e('Received an invalid shadow state');
      return;
    }

    if (newState == _state) {
      // Nothing to do
      return;
    }

    _logsHelper.d('Accepted new shadow state');
    _updateState(newState);
  }

  /// This method handles the "update/accepted" topic subscription events (subscribed, unsubscribed,
  /// failed). It will refresh the shadow if a [AwsIotMqttSubEvent.subscribed] event is received.
  Future<void> _onUpdateAcceptedSubscriptionEvent(AwsIotMqttSubEvent event) async {
    switch (event) {
      case AwsIotMqttSubEvent.subscribed:
        await requestGet();
        break;
      case AwsIotMqttSubEvent.unsubscribed:
      case AwsIotMqttSubEvent.subscriptionFailed:
        break;
    }
  }

  /// This method generates a client token for the shadow requests
  String _generateClientToken() => const Uuid().v1();

  /// This method returns a [AwsIotMqttSubHandler] for a given [topic]. It will also set the
  /// [onMsgCb] and [onSubscriptionEventCb] callbacks if provided.
  AwsIotMqttSubHandler _getHandler(
    ShadowTopicsEnum topic, {
    required Function(String) onMsgCb,
    Function(AwsIotMqttSubEvent)? onSubscriptionEventCb,
  }) =>
      _topicWatchers[topic]!.getHandler(
        onMsgCb: onMsgCb,
        onEventCb: onSubscriptionEventCb,
      );

  /// This is utility method to publish a message to a given [topic] with a given [payload]
  Future<bool> _publish(
    ShadowTopicsEnum topic,
    String payload,
  ) =>
      _mqttService.publish(
        topicNames[topic]!,
        payload,
      );

  /// This method waits for the shadow to be subscribed to a given [topic]
  Future<bool> _waitSubscribed(ShadowTopicsEnum topic) async {
    final watcher = _topicWatchers[topic]!;
    return watcher.isSubscribed().timeout(
      _subscriptionTimeout,
      onTimeout: () {
        _logsHelper.e('Timed out waiting to subscribe to the $topic topic');
        return false;
      },
    );
  }

  /// This method must be used to modify the [_state] of the shadow. It will check for changes
  /// between the new state and the current state and will update the streams accordingly
  void _updateState(AwsIotShadowStateModel newState) {
    final previousState = _state;
    _state = newState;

    if (!mapEquals(_state.reportedState, previousState.reportedState)) {
      _logsHelper.d('Reported state changed');
      _reportedStateStreamController.add(_state.reportedState);
    }

    if (!mapEquals(_state.desiredState, previousState.desiredState)) {
      _logsHelper.d('Desired state changed');
      _desiredStateStreamController.add(_state.desiredState);
    }
  }

  /// This method disposes the shadow by unsubscribing from the shadow topics
  Future<void> dispose() async {
    await Future.wait([
      _updateAcceptedHandler.close(),
      _getAcceptedHandler.close(),
      _reportedStateStreamController.close(),
      _desiredStateStreamController.close(),
    ]);
  }
}
