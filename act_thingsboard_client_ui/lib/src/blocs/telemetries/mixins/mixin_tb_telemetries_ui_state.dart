// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_error.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

/// Help to keep [TbTelemetriesUiState] in your bloc state, and regenerate the view if one element
/// has changed
mixin MixinTbTelemetriesUiState on Equatable {
  /// The linked [TbTelemetriesUiState] which contains the listen telemetries
  late final TbTelemetriesUiState telemetriesUiState;

  /// The current generic process error
  TbTelemetriesUiError get tbTelemetriesGenericError => telemetriesUiState.genericError;

  /// "Constructs" the mixin and merge the class members specific to this mixin.
  ///
  /// Has to be called in the constructor body of the main state.
  @protected
  void constructTbTelemetriesUiState({
    required MixinTbTelemetriesUiState previousState,
    required TbTelemetriesUiState? telemetriesUiState,
  }) {
    this.telemetriesUiState = telemetriesUiState ?? previousState.telemetriesUiState;
  }

  /// "Constructs" the mixin and merge the class members specific to this mixin.
  ///
  /// This is the "init constructor" for the mixin
  ///
  /// Has to be called in the init constructor body of the main state.
  @protected
  void initConstructTbTelemetriesUiState() {
    telemetriesUiState = TbTelemetriesInitUiState();
  }

  /// Helpful method to get the a time series value thanks to its [key].
  ///
  /// This returns null, if the value hasn't been set on the server, if the value is null or if a
  /// problem occurred when parsing the value
  T? getTsValue<T>(MixinTelemetriesKeys key) => telemetriesUiState.getTsValue(key);

  /// Get the last reception time of time series, found thanks to the [key] given.
  ///
  /// This returns null, if the value hasn't been set on the server, if we haven't received it, if
  /// the value is null or if a problem occurred when parsing the value
  DateTime? getTsLastUtcReceptionTime(MixinTelemetriesKeys key) =>
      telemetriesUiState.getTsLastUtcReceptionTime(key);

  /// Helpful method to get the an attribute value thanks to its [key].
  ///
  /// This returns null, if the value hasn't been set on the server, if the value is null or if a
  /// problem occurred when parsing the value
  T? getAttributeValue<T>(MixinTelemetriesKeys key) => telemetriesUiState.getAttributeValue(key);

  /// Get the last reception time of attribute, found thanks to the [key] given.
  ///
  /// This returns null, if the value hasn't been set on the server, if we haven't received it, if
  /// the value is null or if a problem occurred when parsing the value
  DateTime? getAttributeLastUtcReceptionTime(MixinTelemetriesKeys key) =>
      telemetriesUiState.getAttributeLastUtcReceptionTime(key);

  @override
  List<Object?> get props => [...super.props, telemetriesUiState];
}
