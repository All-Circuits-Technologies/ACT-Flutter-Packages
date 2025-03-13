// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_thingsboard_client_ui/act_thingsboard_client_ui.dart';

/// This is the abstract state for the [TbTelemetriesUiBloc]
class TbTelemetriesUiState extends BlocStateForMixin<TbTelemetriesUiState>
    with MixinTbTelemetriesUiState<TbTelemetriesUiState> {
  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiState.device}
  @override
  final DeviceInfo? device;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiState.telemetryLoading}
  @override
  final bool telemetryLoading;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiState.genericError}
  @override
  final TbTelemetriesUiError genericError;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiState.tsValues}
  @override
  final Map<String, TsValue> tsValues;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiState.attributesValues}
  @override
  final Map<String, TbExtAttributeData> attributesValues;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiState.dateTime}
  @override
  final DateTime dateTime;

  /// Class constructor
  const TbTelemetriesUiState({
    required this.device,
    required this.telemetryLoading,
    required this.genericError,
    required this.tsValues,
    required this.attributesValues,
    required this.dateTime,
  });

  /// Factory initializer
  TbTelemetriesUiState.init()
      : device = null,
        telemetryLoading = true,
        genericError = TbTelemetriesUiError.noError,
        tsValues = {},
        attributesValues = {},
        dateTime = DateTime.now().toUtc(),
        super();

  /// {@macro act_flutter_utility.BlocStateForMixin.copyWith}
  @override
  TbTelemetriesUiState copyWith({
    DeviceInfo? device,
    bool forceDeviceValue = false,
    bool? telemetryLoading,
    TbTelemetriesUiError? genericError,
    Map<String, TsValue>? tsValues,
    Map<String, TbExtAttributeData>? attributesValues,
    DateTime? dateTime,
  }) =>
      TbTelemetriesUiState(
        device: device ?? (forceDeviceValue ? null : this.device),
        telemetryLoading: telemetryLoading ?? this.telemetryLoading,
        genericError: genericError ?? this.genericError,
        tsValues: tsValues ?? this.tsValues,
        attributesValues: attributesValues ?? this.attributesValues,
        dateTime: dateTime ?? this.dateTime,
      );

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiState.copyWithTbTelemetriesState}
  @override
  TbTelemetriesUiState copyWithTbTelemetriesState({
    DeviceInfo? device,
    bool forceDeviceValue = false,
    bool? telemetryLoading,
    TbTelemetriesUiError? genericError,
    Map<String, TsValue>? tsValues,
    Map<String, TbExtAttributeData>? attributesValues,
    DateTime? dateTime,
  }) =>
      copyWith(
        device: device,
        forceDeviceValue: forceDeviceValue,
        telemetryLoading: telemetryLoading,
        genericError: genericError,
        tsValues: tsValues,
        attributesValues: attributesValues,
        dateTime: dateTime,
      );
}
