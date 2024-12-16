// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Model to store the consent options of a given enum [T] that implements the
/// [MixinConsentOptions] mixin. Not that even if [ConsentOptionsModel] extends [Equatable],
/// the equality operator is overridden to compare the [_optionMap] using the [mapEquals] function.
class ConsentOptionsModel<T extends MixinConsentOptions> extends Equatable {
  /// Map of [ConsentStateEnum] values for each [option] of the consent.
  final Map<T, ConsentStateEnum> _optionMap;

  /// Get the [_optionMap].
  Map<T, ConsentStateEnum> get optionMap => _optionMap;

  /// Class constructor
  const ConsentOptionsModel({
    required Map<T, ConsentStateEnum> options,
  }) : _optionMap = options;

  /// Class constructor which copies a [ConsentOptionsModel].
  ConsentOptionsModel.copy(ConsentOptionsModel<T> options)
      : _optionMap = Map<T, ConsentStateEnum>.from(options._optionMap);

  /// Class constructor which init the option map with the given [keys] to the given [state].
  ConsentOptionsModel.fromKeys(
    List<T> keys,
    ConsentStateEnum state,
  ) : _optionMap = {for (var key in keys) key: state};

  /// Get the [ConsentStateEnum] value of a given [option] or [ConsentStateEnum.unknown] when
  /// [option] is not yet in [_optionMap].
  ConsentStateEnum getOptionState(T option) => _optionMap[option] ?? ConsentStateEnum.unknown;

  /// Merge the current consent options with another one. If an option present in [options] is not
  /// present in the current consent options, it will be ignored.
  ConsentOptionsModel<T> merge({
    required ConsentOptionsModel options,
  }) {
    final values = <T, ConsentStateEnum>{};

    for (final key in _optionMap.keys) {
      values[key] = options._optionMap[key] ?? _optionMap[key]!;
    }

    return ConsentOptionsModel(options: values);
  }

  /// Set the [ConsentStateEnum] value of a given [option].
  void setOptionState(T option, ConsentStateEnum state) {
    _optionMap[option] = state;
  }

  /// Check if the consent is accepted, i.e. are all options either accepted or optional ?
  bool get isAccepted =>
      _optionMap.entries.every((entry) => (entry.value.isAccepted || entry.key.isOptional));

  /// Override the equality operator using the [mapEquals] function to compare the [_optionMap].
  /// This override the [Equatable] equality operator which is not suitable for this class since it
  /// would compare the [_optionMap] reference and not its content.
  @override
  bool operator ==(Object other) =>
      other is ConsentOptionsModel<T> &&
      other.runtimeType == runtimeType &&
      mapEquals(_optionMap, other._optionMap);

  /// Override the [hashCode] to use the [_optionMap] hash code.
  @override
  int get hashCode => _optionMap.hashCode;

  /// Override the [props] getter expected by the [Equatable] class but since we override the
  /// equality operator, this getter won't be used.
  @override
  List<Object> get props => [_optionMap];
}
