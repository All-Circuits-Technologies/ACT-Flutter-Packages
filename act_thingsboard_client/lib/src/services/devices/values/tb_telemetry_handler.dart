// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_thingsboard_client/src/mixins/mixin_telemetries_keys.dart';
import 'package:act_thingsboard_client/src/models/tb_ext_attribute_data.dart';
import 'package:act_thingsboard_client/src/services/devices/values/a_tb_telemetry.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_device_attributes.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_device_values.dart';
import 'package:mutex/mutex.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Useful class to use by bloc or manager, to observe particular telemetry values linked to a
/// particular device
class TbTelemetryHandler {
  /// Protect the adding, removing of elements observation
  final Mutex _mutex;

  /// The [TbDeviceValues] parent attached to this handler
  final TbDeviceValues _deviceValues;

  /// The list of client attributes listened by this handler
  final List<String> clientAttrKeys;

  /// The list of shared attributes listened by this handler
  final List<String> sharedAttrKeys;

  /// The list of server attributes listened by this handler
  final List<String> serverAttrKeys;

  /// The list of time series listened by this handler
  final List<String> timeSeriesKeys;

  /// Returns true if this handler is currently listening telemetries
  bool get areWeListeningTelemetries =>
      clientAttrKeys.isNotEmpty ||
      sharedAttrKeys.isNotEmpty ||
      serverAttrKeys.isNotEmpty ||
      timeSeriesKeys.isNotEmpty;

  /// The attribute controller used to emit messages when scrutinise attributes are updated on
  /// thingsboard
  final StreamController<Map<String, TbExtAttributeData>> _attrCtrl;

  /// Stream linked to the [_attrCtrl] attribute controller
  Stream<Map<String, TbExtAttributeData>> get attributesStream => _attrCtrl.stream;

  /// The attribute controller used to emit messages when scrutinise time series are updated on
  /// thingsboard
  final StreamController<Map<String, TsValue>> _tsCtrl;

  /// Stream linked to the [_tsCtrl] time series controller
  Stream<Map<String, TsValue>> get timeSeriesStream => _tsCtrl.stream;

  /// Subscription to the client attributes
  late final StreamSubscription _clientAttrSub;

  /// Subscription to the shared attributes
  late final StreamSubscription _sharedAttrSub;

  /// Subscription to the server attributes
  late final StreamSubscription _serverAttrSub;

  /// Subscription to the time series
  late final StreamSubscription _timeSeriesSub;

  /// Class constructor
  TbTelemetryHandler({
    required TbDeviceValues deviceValues,
  })  : _deviceValues = deviceValues,
        clientAttrKeys = [],
        sharedAttrKeys = [],
        serverAttrKeys = [],
        timeSeriesKeys = [],
        _attrCtrl = StreamController.broadcast(),
        _tsCtrl = StreamController.broadcast(),
        _mutex = Mutex() {
    _clientAttrSub =
        _deviceValues.clientAttributes.telemetryStream.listen((values) => _onReceivedAttribute(
              values,
              AttributeScope.CLIENT_SCOPE,
            ));
    _sharedAttrSub =
        _deviceValues.sharedAttributes.telemetryStream.listen((values) => _onReceivedAttribute(
              values,
              AttributeScope.SHARED_SCOPE,
            ));
    _serverAttrSub =
        _deviceValues.serverAttributes.telemetryStream.listen((values) => _onReceivedAttribute(
              values,
              AttributeScope.SERVER_SCOPE,
            ));
    _timeSeriesSub = _deviceValues.timeSeries.telemetryStream.listen(_onReceivedTimeSeries);
  }

  /// Add new subscriptions on specific telemetry elements
  Future<bool> add({
    List<String>? clientKeys,
    List<String>? sharedKeys,
    List<String>? serverKeys,
    List<String>? tsKeys,
  }) async {
    if (clientKeys != null &&
        !(await _toAddValues(
          toAdd: clientKeys,
          currentList: clientAttrKeys,
          telemetry: _deviceValues.clientAttributes,
        ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to add subscription to the client "
          "attribute keys: $clientKeys");
      return false;
    }

    if (sharedKeys != null &&
        !(await _toAddValues(
          toAdd: sharedKeys,
          currentList: sharedAttrKeys,
          telemetry: _deviceValues.sharedAttributes,
        ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to add subscription to the shared "
          "attribute keys: $sharedKeys");
      return false;
    }

    if (serverKeys != null &&
        !(await _toAddValues(
          toAdd: serverKeys,
          currentList: serverAttrKeys,
          telemetry: _deviceValues.serverAttributes,
        ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to add subscription to the server "
          "attribute keys: $serverKeys");
      return false;
    }

    if (tsKeys != null &&
        !(await _toAddValues(
          toAdd: tsKeys,
          currentList: timeSeriesKeys,
          telemetry: _deviceValues.timeSeries,
        ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to add subscription to the time "
          "series keys: $tsKeys");
      return false;
    }

    return true;
  }

  /// Add new subscriptions on specific telemetry elements
  ///
  /// This is useful when using enum in app to list the telemetries keys
  Future<bool> addKeys<Ca extends MixinTelemetriesKeys, Sha extends MixinTelemetriesKeys,
          Sea extends MixinTelemetriesKeys, Ts extends MixinTelemetriesKeys>({
    List<Ca>? clientKeys,
    List<Sha>? sharedKeys,
    List<Sea>? serverKeys,
    List<Ts>? tsKeys,
  }) =>
      add(
        clientKeys: _convertFromTelemetriesKeys(clientKeys),
        sharedKeys: _convertFromTelemetriesKeys(sharedKeys),
        serverKeys: _convertFromTelemetriesKeys(serverKeys),
        tsKeys: _convertFromTelemetriesKeys(tsKeys),
      );

  /// Remove subscriptions on specific telemetry elements
  Future<bool> remove({
    List<String>? clientKeys,
    List<String>? sharedKeys,
    List<String>? serverKeys,
    List<String>? tsKeys,
  }) async {
    if (clientKeys != null &&
        !(await _toRemoveValues(
          toRemove: clientKeys,
          currentList: clientAttrKeys,
          telemetry: _deviceValues.clientAttributes,
        ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to remove subscription from the "
          "client attribute keys: $clientKeys");
      return false;
    }

    if (sharedKeys != null &&
        !(await _toRemoveValues(
          toRemove: sharedKeys,
          currentList: sharedAttrKeys,
          telemetry: _deviceValues.sharedAttributes,
        ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to remove subscription from the "
          "shared attribute keys: $sharedKeys");
      return false;
    }

    if (serverKeys != null &&
        !(await _toRemoveValues(
          toRemove: serverKeys,
          currentList: serverAttrKeys,
          telemetry: _deviceValues.serverAttributes,
        ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to remove subscription from the "
          "server attribute keys: $serverKeys");
      return false;
    }

    if (tsKeys != null &&
        !(await _toRemoveValues(
          toRemove: tsKeys,
          currentList: timeSeriesKeys,
          telemetry: _deviceValues.timeSeries,
        ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to remove subscription from the "
          "time series keys: $tsKeys");
      return false;
    }

    return true;
  }

  /// Remove subscriptions on specific telemetry elements
  ///
  /// This is useful when using enum in app to list the telemetries keys
  Future<bool> removeKeys<Ca extends MixinTelemetriesKeys, Sha extends MixinTelemetriesKeys,
          Sea extends MixinTelemetriesKeys, Ts extends MixinTelemetriesKeys>({
    List<Ca>? clientKeys,
    List<Sha>? sharedKeys,
    List<Sea>? serverKeys,
    List<Ts>? tsKeys,
  }) =>
      remove(
        clientKeys: _convertFromTelemetriesKeys(clientKeys),
        sharedKeys: _convertFromTelemetriesKeys(sharedKeys),
        serverKeys: _convertFromTelemetriesKeys(serverKeys),
        tsKeys: _convertFromTelemetriesKeys(tsKeys),
      );

  /// Remove all the subscriptions on specific telemetry elements
  ///
  /// If you want to remove all, this method is more performant than calling [remove] unitary
  Future<bool> removeAll() async {
    if (!(await _toRemoveAll(
      currentList: clientAttrKeys,
      telemetry: _deviceValues.clientAttributes,
    ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to remove all the subscription to "
          "client attribute keys: $clientAttrKeys");
      return false;
    }

    if (!(await _toRemoveAll(
      currentList: serverAttrKeys,
      telemetry: _deviceValues.serverAttributes,
    ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to remove all the subscription to "
          "server attribute keys: $serverAttrKeys");
      return false;
    }

    if (!(await _toRemoveAll(
      currentList: sharedAttrKeys,
      telemetry: _deviceValues.sharedAttributes,
    ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to remove all the subscription to "
          "shared attribute keys: $sharedAttrKeys");
      return false;
    }

    if (!(await _toRemoveAll(
      currentList: timeSeriesKeys,
      telemetry: _deviceValues.timeSeries,
    ))) {
      _deviceValues.logsHelper.w("A problem occurred when tried to remove all the subscription to "
          "time series keys: $timeSeriesKeys");
      return false;
    }

    return true;
  }

  /// Get timeseries values called on loading state
  Map<String, TsValue> getTsValues() {
    final tsValues = <String, TsValue>{};

    for (final tsKey in timeSeriesKeys) {
      final value = _deviceValues.timeSeries.getTelemetryValue(tsKey);

      if (value == null) {
        // Nothing to add
        continue;
      }

      tsValues[tsKey] = value;
    }

    return tsValues;
  }

  /// Get all attributes scope values called on loading state
  Map<String, TbExtAttributeData> getAttributeValues() {
    final attributeValues = <String, TbExtAttributeData>{};

    attributeValues.addAll(getAttributeValuesByScope(scope: AttributeScope.CLIENT_SCOPE));
    attributeValues.addAll(getAttributeValuesByScope(scope: AttributeScope.SHARED_SCOPE));
    attributeValues.addAll(getAttributeValuesByScope(scope: AttributeScope.SERVER_SCOPE));

    return attributeValues;
  }

  /// Get attribute values by scope
  Map<String, TbExtAttributeData> getAttributeValuesByScope({
    required AttributeScope scope,
  }) {
    final attributeValues = <String, TbExtAttributeData>{};
    final attributeKeys = _getAttrKeysList(scope);
    final tbDeviceAttributes = _getTbDeviceAttributesByScope(scope);

    for (final attrKey in attributeKeys) {
      final value = tbDeviceAttributes.getTelemetryValue(attrKey);

      if (value == null) {
        continue;
      }

      attributeValues[attrKey] = TbExtAttributeData(data: value, scope: scope);
    }

    return attributeValues;
  }

  /// Called to manage the adding of telemetry subscription
  Future<bool> _toAddValues({
    required List<String> toAdd,
    required List<String> currentList,
    required ATbTelemetry telemetry,
  }) =>
      _mutex.protect(() async {
        final tmpToAdd = ListUtility.copyWithoutValues(toAdd, currentList, growable: false);

        if (tmpToAdd.isEmpty) {
          // Nothing to do
          return true;
        }

        if (!(await telemetry.subscribeElements(keys: tmpToAdd))) {
          return false;
        }

        currentList.addAll(tmpToAdd);

        return true;
      });

  /// Called to manage the removing of telemetry subscription
  Future<bool> _toRemoveValues({
    required List<String> toRemove,
    required List<String> currentList,
    required ATbTelemetry telemetry,
  }) =>
      _mutex.protect(() async {
        final tmpToRemove = ListUtility.getListsIntersection([toRemove, currentList]);

        if (tmpToRemove.isEmpty) {
          // Nothing to do
          return true;
        }

        if (!(await telemetry.unSubscribeElements(keys: tmpToRemove))) {
          return false;
        }

        currentList.removeWhere(tmpToRemove.contains);

        return true;
      });

  /// Called to manage the removing of all telemetry subscriptions
  Future<bool> _toRemoveAll({
    required List<String> currentList,
    required ATbTelemetry telemetry,
  }) =>
      _mutex.protect(() async {
        if (currentList.isEmpty) {
          // Nothing to do
          return true;
        }

        if (!(await telemetry.unSubscribeElements(keys: currentList))) {
          return false;
        }

        currentList.clear();

        return true;
      });

  /// Get all the attribute keys listened and linked to the [scope] given
  List<String> _getAttrKeysList(AttributeScope scope) {
    switch (scope) {
      case AttributeScope.CLIENT_SCOPE:
        return clientAttrKeys;
      case AttributeScope.SHARED_SCOPE:
        return sharedAttrKeys;
      case AttributeScope.SERVER_SCOPE:
        return serverAttrKeys;
    }
  }

  /// Get all the attributes listened and linked to the [scope] given
  TbDeviceAttributes _getTbDeviceAttributesByScope(AttributeScope scope) {
    switch (scope) {
      case AttributeScope.CLIENT_SCOPE:
        return _deviceValues.clientAttributes;
      case AttributeScope.SHARED_SCOPE:
        return _deviceValues.sharedAttributes;
      case AttributeScope.SERVER_SCOPE:
        return _deviceValues.serverAttributes;
    }
  }

  /// Called when new attribute values are received
  void _onReceivedAttribute(Map<String, AttributeData> values, AttributeScope scope) {
    final attributes = <String, TbExtAttributeData>{};

    for (final value in values.entries) {
      if (_getAttrKeysList(scope).contains(value.key)) {
        attributes[value.key] = TbExtAttributeData(data: value.value, scope: scope);
      }
    }

    if (attributes.isNotEmpty) {
      _attrCtrl.add(attributes);
    }
  }

  /// Called when new time series values are received
  void _onReceivedTimeSeries(Map<String, TsValue> values) {
    final tsValues = <String, TsValue>{};

    for (final value in values.entries) {
      if (timeSeriesKeys.contains(value.key)) {
        tsValues[value.key] = value.value;
      }
    }

    if (tsValues.isNotEmpty) {
      _tsCtrl.add(tsValues);
    }
  }

  /// Convert a [telemetriesKeys] list with the type [MixinTelemetriesKeys] to a string list
  List<String>? _convertFromTelemetriesKeys(List<MixinTelemetriesKeys>? telemetriesKeys) {
    if (telemetriesKeys == null) {
      return null;
    }

    return MixinTelemetriesKeys.parseTelemetryKeyList(telemetriesKeys);
  }

  /// Call to close the handler and remove all the subscriptions
  Future<void> close() async {
    final futures = <Future>[
      removeAll(),
      _attrCtrl.close(),
      _tsCtrl.close(),
      _clientAttrSub.cancel(),
      _sharedAttrSub.cancel(),
      _serverAttrSub.cancel(),
      _timeSeriesSub.cancel(),
    ];

    await Future.wait(futures);
  }
}
