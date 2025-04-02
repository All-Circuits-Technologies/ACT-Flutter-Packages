// SPDX-FileCopyrightText: 2023, 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_error.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_state.dart';
import 'package:flutter/material.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Help to keep [TbTelemetriesUiState] in your bloc state, and regenerate the view if one element
/// has changed
mixin MixinTbTelemetriesUiState<S extends BlocStateForMixin<S>> on BlocStateForMixin<S> {
  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiState.device}
  /// The device linked to the page
  /// {@endtemplate}
  DeviceInfo? get device;

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiState.telemetryLoading}
  /// True when the page is loading
  /// {@endtemplate}
  bool get telemetryLoading;

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiState.genericError}
  /// The current generic process error
  /// {@endtemplate}
  TbTelemetriesUiError get genericError;

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiState.tsValues}
  /// The time series values
  /// {@endtemplate}
  Map<String, TbTsValue> get tsValues;

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiState.attributesValues}
  /// The attributes values
  /// {@endtemplate}
  Map<String, TbExtAttributeData> get attributesValues;

  /// Test if the current error offers the possibility to retry the request to server
  bool get canRetryRequest => (genericError == TbTelemetriesUiError.serverError);

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiState.copyWithTbTelemetriesState}
  /// Default copy with for managing telemetry ui state
  /// {@endtemplate}
  @protected
  S copyWithTbTelemetriesState({
    DeviceInfo? device,
    bool forceDeviceValue = false,
    bool? telemetryLoading,
    TbTelemetriesUiError? genericError,
    Map<String, TbTsValue>? tsValues,
    Map<String, TbExtAttributeData>? attributesValues,
  });

  /// Represents the error state of the device telemetries page
  S copyWithErrorUiState({
    required TbTelemetriesUiError genericError,
  }) =>
      copyWithTbTelemetriesState(
        genericError: genericError,
        telemetryLoading: false,
      );

  /// Represents the loading state of the device telemetries page
  ///
  /// and get timeseries and attribute values
  S copyWithTelemetryInit({
    DeviceInfo? device,
    Map<String, TbTsValue>? tsValues,
    Map<String, TbExtAttributeData>? attributesValues,
  }) =>
      copyWithTbTelemetriesState(
        genericError: TbTelemetriesUiError.noError,
        attributesValues: attributesValues,
        tsValues: tsValues,
        device: device,
      );

  /// Represents a state for managing the telemetries reception
  S copyWithNewValuesUiState({
    Map<String, TbTsValue>? tsValues,
    Map<String, TbExtAttributeData>? attributesValues,
  }) {
    bool? loading;
    if (telemetryLoading &&
        ((tsValues != null && tsValues.isNotEmpty) ||
            (attributesValues != null && attributesValues.isNotEmpty))) {
      loading = false;
    }

    return copyWithTbTelemetriesState(
      telemetryLoading: loading,
      tsValues: MapUtility.copyAndMergeOrNull(this.tsValues, tsValues),
      attributesValues: MapUtility.copyAndMergeOrNull(this.attributesValues, attributesValues),
    );
  }

  /// Helpful method to get the a time series value thanks to its [key].
  ///
  /// This returns null, if the value hasn't been set on the server, if the value is null or if a
  /// problem occurred when parsing the value
  T? getTsValue<T>(MixinTelemetriesKeys key) =>
      TbTelemetriesHelper.getTsValue<T>(tsValues[key.tbKey]);

  /// Get the last reception time of time series, found thanks to the [key] given.
  ///
  /// This returns null, if the value hasn't been set on the server, if we haven't received it, if
  /// the value is null or if a problem occurred when parsing the value
  DateTime? getTsLastUtcReceptionTime(MixinTelemetriesKeys key) =>
      TbTelemetriesHelper.getTsLastUtcReceptionTime(tsValues[key.tbKey]);

  /// Helpful method to get the an attribute value thanks to its [key].
  ///
  /// This returns null, if the value hasn't been set on the server, if the value is null or if a
  /// problem occurred when parsing the value
  T? getAttributeValue<T>(MixinTelemetriesKeys key) =>
      TbTelemetriesHelper.getAttributeValue<T>(attributesValues[key.tbKey]);

  /// Get the last reception time of attribute, found thanks to the [key] given.
  ///
  /// This returns null, if the value hasn't been set on the server, if we haven't received it, if
  /// the value is null or if a problem occurred when parsing the value
  DateTime? getAttributeLastUtcReceptionTime(MixinTelemetriesKeys key) =>
      TbTelemetriesHelper.getAttributeLastUtcReceptionTime(attributesValues[key.tbKey]);

  /// State properties
  @override
  List<Object?> get props => [
        device,
        telemetryLoading,
        genericError,
        tsValues,
        attributesValues,
      ];
}
