// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_error.dart';
import 'package:equatable/equatable.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This is the abstract state for the [TbTelemetriesUiBloc]
abstract class TbTelemetriesUiState extends Equatable {
  /// The device linked to the page
  final DeviceInfo? device;

  /// True when the page is loading
  final bool telemetryLoading;

  /// The current generic process error
  final TbTelemetriesUiError genericError;

  /// The time series values
  final Map<String, TsValue> tsValues;

  /// The attributes values
  final Map<String, TbExtAttributeData> attributesValues;

  /// Test if the current error offers the possibility to retry the request to server
  bool get canRetryRequest => (genericError == TbTelemetriesUiError.serverError);

  /// Class constructor
  TbTelemetriesUiState({
    required TbTelemetriesUiState previousState,
    DeviceInfo? device,
    bool? telemetryLoading,
    TbTelemetriesUiError? genericError,
    Map<String, TsValue>? tsValues,
    Map<String, TbExtAttributeData>? attributesValues,
  })  : device = device ?? previousState.device,
        telemetryLoading = telemetryLoading ?? previousState.telemetryLoading,
        genericError = genericError ?? previousState.genericError,
        tsValues = previousState.tsValues,
        attributesValues = previousState.attributesValues,
        super() {
    if (tsValues != null) {
      this.tsValues.addAll(tsValues);
    }

    if (attributesValues != null) {
      this.attributesValues.addAll(attributesValues);
    }
  }

  /// Factory initializer
  TbTelemetriesUiState.initState()
      : device = null,
        telemetryLoading = true,
        genericError = TbTelemetriesUiError.noError,
        tsValues = {},
        attributesValues = {},
        super();

  /// Helpful method to get the a time series value thanks to its [key].
  ///
  /// This returns null, if the value hasn't been set on the server, if the value is null or if a
  /// problem occurred when parsing the value
  T? getTsValue<T>(MixinTelemetriesKeys key) =>
      TbTelemetriesHelper.getTsValue<T>(tsValues[key.getTbKey()]);

  /// Get the last reception time of time series, found thanks to the [key] given.
  ///
  /// This returns null, if the value hasn't been set on the server, if we haven't received it, if
  /// the value is null or if a problem occurred when parsing the value
  DateTime? getTsLastUtcReceptionTime(MixinTelemetriesKeys key) =>
      TbTelemetriesHelper.getTsLastUtcReceptionTime(tsValues[key.getTbKey()]);

  /// Helpful method to get the an attribute value thanks to its [key].
  ///
  /// This returns null, if the value hasn't been set on the server, if the value is null or if a
  /// problem occurred when parsing the value
  T? getAttributeValue<T>(MixinTelemetriesKeys key) =>
      TbTelemetriesHelper.getAttributeValue<T>(attributesValues[key.getTbKey()]);

  /// Get the last reception time of attribute, found thanks to the [key] given.
  ///
  /// This returns null, if the value hasn't been set on the server, if we haven't received it, if
  /// the value is null or if a problem occurred when parsing the value
  DateTime? getAttributeLastUtcReceptionTime(MixinTelemetriesKeys key) =>
      TbTelemetriesHelper.getAttributeLastUtcReceptionTime(attributesValues[key.getTbKey()]);

  @override
  List<Object?> get props => [
        device,
        telemetryLoading,
        tsValues,
        attributesValues,
      ];
}

/// Represents the initialize state of device telemetries page
class TbTelemetriesInitUiState extends TbTelemetriesUiState {
  /// Class constructor
  TbTelemetriesInitUiState() : super.initState();
}

/// Represents the error state of the device telemetries page
class TbTelemetriesErrorUiState extends TbTelemetriesUiState {
  /// Class constructor
  TbTelemetriesErrorUiState({
    required super.previousState,
    required TbTelemetriesUiError super.genericError,
  }) : super(telemetryLoading: false);
}

/// Represents the loading state of the device telemetries page
///
/// and get timeseries and attribute values
class TbTelemetriesLoadingUiState extends TbTelemetriesUiState {
  /// Class constructor
  TbTelemetriesLoadingUiState({
    required super.previousState,
    super.telemetryLoading,
    super.device,
    super.tsValues,
    super.attributesValues,
  }) : super(genericError: TbTelemetriesUiError.noError);
}

/// Abstract state for managing the telemetries reception
abstract class ATbTelemetriesNewValuesUiState extends TbTelemetriesUiState {
  /// The date time when we received the telemetries
  /// Used to force a rebuild of the view
  final DateTime dateTime;

  /// Class constructor
  ATbTelemetriesNewValuesUiState({
    required super.previousState,
    super.telemetryLoading,
    super.tsValues,
    super.attributesValues,
  })  : dateTime = DateTime.now().toUtc(),
        super();

  @override
  List<Object?> get props => [dateTime, ...super.props];
}

/// Represents a state when we receive new time series values
class TbTimeSeriesNewValuesUiState extends ATbTelemetriesNewValuesUiState {
  /// Class constructor
  TbTimeSeriesNewValuesUiState({
    required super.previousState,
    required Map<String, TsValue> super.tsValues,
  }) : super(telemetryLoading: false);
}

/// Represents a state when we receive new attributes values
class TbAttributesNewValuesUiState extends ATbTelemetriesNewValuesUiState {
  /// Class constructor
  TbAttributesNewValuesUiState({
    required super.previousState,
    required Map<String, TbExtAttributeData> super.attributesValues,
  }) : super(telemetryLoading: false);
}
