// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';

/// Emitted at the initialisation
class InitTbTelemetriesUiEvent extends BlocEventForMixin {
  /// Class constructor
  const InitTbTelemetriesUiEvent() : super();
}

/// Emitted after an error to retry the initialisation
class RetryInitTbTelemetriesUiEvent extends BlocEventForMixin {
  /// Class constructor
  const RetryInitTbTelemetriesUiEvent() : super();
}

/// Emitted when new time series values are received
class NewTbTimeSeriesValuesUiEvent extends BlocEventForMixin {
  /// The list of time series values updated
  final Map<String, TbTsValue> tsValues;

  /// Class constructor
  const NewTbTimeSeriesValuesUiEvent({
    required this.tsValues,
  }) : super();

  @override
  List<Object?> get props => [...super.props, tsValues];
}

/// Emitted when new attributes values are received
class NewTbAttributesValuesUiEvent extends BlocEventForMixin {
  /// The list of attributes values updated
  final Map<String, TbExtAttributeData> attributesValues;

  /// Class constructor
  const NewTbAttributesValuesUiEvent({
    required this.attributesValues,
  }) : super();

  @override
  List<Object?> get props => [...super.props, attributesValues];
}
