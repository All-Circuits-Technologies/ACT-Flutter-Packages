// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:equatable/equatable.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This is the abstract event for the [TbTelemetriesUiBloc]
abstract class TbTelemetriesUiEvent extends Equatable {
  const TbTelemetriesUiEvent();
}

/// Emitted at the initialisation
class InitTbTelemetriesUiEvent extends TbTelemetriesUiEvent {
  /// Class constructor
  const InitTbTelemetriesUiEvent() : super();

  @override
  List<Object> get props => [];
}

/// Emitted after an error to retry the initialisation
class RetryInitTbTelemetriesUiEvent extends TbTelemetriesUiEvent {
  /// Class constructor
  const RetryInitTbTelemetriesUiEvent() : super();

  @override
  List<Object> get props => [];
}

/// Emitted when new time series values are received
class NewTbTimeSeriesValuesUiEvent extends TbTelemetriesUiEvent {
  /// The list of time series values updated
  final Map<String, TsValue> tsValues;

  /// Class constructor
  const NewTbTimeSeriesValuesUiEvent({
    required this.tsValues,
  }) : super();

  @override
  List<Object> get props => [tsValues];
}

/// Emitted when new attributes values are received
class NewTbAttributesValuesUiEvent extends TbTelemetriesUiEvent {
  /// The list of attributes values updated
  final Map<String, TbExtAttributeData> attributesValues;

  /// Class constructor
  const NewTbAttributesValuesUiEvent({
    required this.attributesValues,
  }) : super();

  @override
  List<Object> get props => [attributesValues];
}
