// SPDX-FileCopyrightText: 2023, 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/act_thingsboard_client_ui.dart';

/// This bloc is used to get and display telemetries in views
///
/// It can be used as it is (when you don't need other BloC process in your view) or with another
/// BLoC, using the MixinTbTelemetriesUiBloc mixin
class TbTelemetriesUiBloc extends BlocForMixin<TbTelemetriesUiState>
    with MixinTbTelemetriesUiBloc<TbTelemetriesUiState> {
  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.clientAttributesKeys}
  @override
  final List<MixinTelemetriesKeys> clientAttributesKeys;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.sharedAttributesKeys}
  @override
  final List<MixinTelemetriesKeys> sharedAttributesKeys;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.serverAttributesKeys}
  @override
  final List<MixinTelemetriesKeys> serverAttributesKeys;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.timeSeriesKeys}
  @override
  final List<MixinTelemetriesKeys> timeSeriesKeys;

  /// {@macro act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.getDeviceInfo}
  @override
  final GetDeviceInfo getDeviceInfo;

  /// Class constructor
  TbTelemetriesUiBloc({
    required this.getDeviceInfo,
    this.clientAttributesKeys = const [],
    this.sharedAttributesKeys = const [],
    this.serverAttributesKeys = const [],
    this.timeSeriesKeys = const [],
  }) : super(TbTelemetriesUiState.init());
}
