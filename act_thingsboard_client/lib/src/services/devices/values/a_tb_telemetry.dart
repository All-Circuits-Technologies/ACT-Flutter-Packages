// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_thingsboard_client/src/services/tb_request_service.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Abstract class to manage the subscription and getting of telemetry linked to a device
abstract class ATbTelemetry<T> {
  /// This is the separator of keys when asking for subscription to Thingsboard
  static const _keysSeparator = ",";

  /// When an user asked for unsubscribe to telemetry, we keep the subscription during this timeout
  /// in case he subscribes again to it just after
  static const _thresholdTimeout = Duration(seconds: 10);

  /// The logs helper linked to the telemetry
  final LogsHelper _logsHelper;

  /// The thingsboard request service
  final TbRequestService _requestService;

  /// The list of keys of the currently subscribed telemetry
  final List<String> _currentlySubscribed;

  /// The telemetry elements the user wants to listen
  final Map<String, _TelemetryInfo<T>> _values;

  /// The stream controller linked to the telemetry keys update
  final StreamController<Map<String, T>> _updatedTelemetry;

  /// Mutex used to protect the update of subscriptions
  final Mutex _updateMutex;

  /// The id of the device currently listened
  final String deviceId;

  /// When telemetry elements are updated, this stream emits the list of their keys
  Stream<Map<String, T>> get telemetryStream => _updatedTelemetry.stream;

  /// The current subscriber to the list of listened telemetries
  TelemetrySubscriber? _subscriber;

  /// The subscription of telemetry update
  StreamSubscription? _subscription;

  /// The timer used to test if some telemetry elements have to be unsubscribed
  Timer? _testTimer;

  /// Class constructor
  ATbTelemetry({
    required TbRequestService requestService,
    required LogsHelper logsHelper,
    required String telemetryName,
    required this.deviceId,
  })  : _values = {},
        _currentlySubscribed = [],
        _updateMutex = Mutex(),
        _logsHelper = logsHelper.createASubLogsHelper(telemetryName),
        _updatedTelemetry = StreamController.broadcast(),
        _requestService = requestService;

  /// Get the telemetry value linked to the given key. If one of the elements is already listened,
  /// this element won't be subscribed twice.
  ///
  /// Returns null if the telemetry isn't listened or if the value hasn't already been received
  T? getTelemetryValue(String key) => _values[key]?.value;

  /// Subscribe to elements thanks to their [keys]
  ///
  /// Returns true if no problem occurred
  Future<bool> subscribeElements({required List<String> keys}) => _manageElementsSub(() async {
        for (final key in keys) {
          if (!_values.containsKey(key)) {
            _values[key] = _TelemetryInfo<T>();
          }

          final element = _values[key]!;

          element.nbHandler++;
          element.noMoreNeededTs = null;
        }

        return true;
      });

  /// Unsubscribe from elements thanks to their [keys], if on of the elements isn't subscribed,
  /// nothing is done with it
  Future<bool> unSubscribeElements({required List<String> keys}) => _manageElementsSub(() async {
        for (final key in keys) {
          final element = _values[key];

          if (element == null) {
            // Nothing to do
            continue;
          }

          if (element.nbHandler > 0) {
            element.nbHandler--;
          }

          if (element.nbHandler == 0) {
            element.noMoreNeededTs = DateTime.now().toUtc().add(_thresholdTimeout);
          }
        }

        return true;
      });

  /// Manage the elements subscription and unSubscription by protecting them with the [_updateMutex]
  /// It also manages the [_testTimer]
  Future<bool> _manageElementsSub(Future<bool> Function() criticalSection) =>
      _updateMutex.protect(() async {
        _testTimer?.cancel();

        if (!(await criticalSection())) {
          return false;
        }

        final result = await _manageNeededSubOrUnSub();

        _testTimer = Timer(_thresholdTimeout, _onTimeout);

        return result;
      });

  /// Called when the timer timeout is raised to call [_manageNeededSubOrUnSub]
  ///
  /// This callback is used to verify if some elements have to be unsubscribed
  Future<void> _onTimeout() async {
    _testTimer?.cancel();
    _testTimer = null;
    await _manageNeededSubOrUnSub();
  }

  /// Call to manage the sub and unsub to telemetry
  ///
  /// Each time, we need to add or remove a subscription, the method will unsubscribe the current
  /// subscription and then creates a new one. This prevents to have multiple active subscription
  /// to the same device
  ///
  /// Returns true if no problem occurred
  Future<bool> _manageNeededSubOrUnSub() async {
    final now = DateTime.now().toUtc();

    // Remove the values which are no more needed
    _values.removeWhere((key, value) => value.noMoreNeededTs?.isBefore(now) ?? false);

    final elementsToSub = _getSortedElementsToSubscribe();

    if (listEquals(elementsToSub, _currentlySubscribed)) {
      // Nothing to do
      return true;
    }

    if (_subscriber != null) {
      if (!(await _requestService.safeRequest((tbClient) async => _subscriber?.unsubscribe()))
          .isOk) {
        _logsHelper.w("A problem occurred when tried to unsubscribe from the telemetry");
        return false;
      }

      _logsHelper.d("Unsubscribed to current sub");

      _subscriber = null;
      await _subscription?.cancel();
      _subscription = null;
      _currentlySubscribed.clear();
    }

    if (elementsToSub.isEmpty) {
      // Nothing to do
      return true;
    }

    final telemetryService = _requestService.tbClient.getTelemetryService();

    final subscriber = TelemetrySubscriber(
      telemetryService,
      [createSubCmd(elementsToSub.join(_keysSeparator))],
    );

    final subscription = subscriber.dataStream.listen(_onUpdateValues);

    if (!(await _requestService.safeRequest((tbClient) async => subscriber.subscribe())).isOk) {
      _logsHelper.w("A problem occurred when tried to subscribe to telemetry");
      await subscription.cancel();
      return false;
    }

    _logsHelper.d("Subscribed to: $elementsToSub");
    _subscription = subscription;
    _subscriber = subscriber;
    _currentlySubscribed.addAll(elementsToSub);

    return true;
  }

  /// Get the timestamp linked to the given value
  ///
  /// Returns null if the value is null or if the timestamp isn't known
  @protected
  int? getTimestamp(T? value);

  /// This allows to create the right sub command linked to the telemetries we want to listen
  @protected
  SubscriptionCmd createSubCmd(String keys);

  /// Called to parse the [SubscriptionUpdate] received to key, value map
  @protected
  Future<Map<String, T>> onUpdateValuesImpl(SubscriptionUpdate subUpdate);

  /// Called when new values linked to the subscribed telemetry elements are received
  Future<void> _onUpdateValues(SubscriptionUpdate subUpdate) async {
    if (subUpdate.errorCode != 0) {
      _logsHelper.d("A problem occurred when receiving telemetries from thingsboard, error "
          "message: ${subUpdate.errorMsg}");
      return;
    }

    final modifiedList = <String, T>{};

    final values = await onUpdateValuesImpl(subUpdate);

    for (final value in values.entries) {
      final current = _values[value.key];

      if (current == null) {
        // Nothing to do, we only update values if it was expected to receive them
        continue;
      }

      final currentTs = getTimestamp(current.value);
      final newTs = getTimestamp(value.value);

      if (currentTs == null || (newTs != null && newTs > currentTs)) {
        current.value = value.value;
        modifiedList[value.key] = value.value;
      }
    }

    _logsHelper.d("Telemetries update received: $values");

    _updatedTelemetry.add(modifiedList);
  }

  /// Get the list of elements to subscribe and sort the list
  List<String> _getSortedElementsToSubscribe() {
    final elements = <String>[];

    for (final info in _values.entries) {
      elements.add(info.key);
    }

    elements.sort();

    return elements;
  }

  /// Called to dispose the class
  @mustCallSuper
  Future<void> dispose() async {
    await _manageNeededSubOrUnSub();

    final futures = <Future>[
      _updatedTelemetry.close(),
    ];

    await Future.wait(futures);
  }
}

/// This class contains the information linked to telemetry
class _TelemetryInfo<T> {
  /// The current value got from server
  /// When null, it means either the value hasn't been got from server yet, the value is null in the
  /// server or the telemetry element doesn't exist in the server
  T? value;

  /// This is different of null when no more class instances need to get values from this telemetry
  /// This datetime represents a threshold and starting from this date, the telemetry may be
  /// unsubscribed
  DateTime? noMoreNeededTs;

  /// Represents the number of external classes which need to listen this telemetry element
  int nbHandler;

  /// Class constructor
  _TelemetryInfo()
      : noMoreNeededTs = null,
        value = null,
        nbHandler = 0;
}
