// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_consent_manager/src/mixins/mixin_consent_options.dart';
import 'package:act_consent_manager/src/models/consent_options_model.dart';
import 'package:act_consent_manager/src/types/consent_state_enum.dart';
import 'package:equatable/equatable.dart';

/// This class is a model to store the consent data which includes the version
/// of the consent and the options.
class ConsentDataModel<T extends MixinConsentOptions> extends Equatable {
  /// The options of the consent
  final ConsentOptionsModel<T> options;

  /// The version of the consent that the user has accepted
  final String? version;

  /// Class constructor
  const ConsentDataModel({
    required this.version,
    required this.options,
  });

  /// Class constructor which init the option map with the given [values] to the status not
  /// accepted.
  ConsentDataModel.init({
    required List<T> values,
  })  : version = null,
        options = ConsentOptionsModel<T>.fromKeys(
          values,
          ConsentStateEnum.notAccepted,
        );

  /// Merge the current consent data with another one
  /// If an option present in [other] is not present in the current consent data,
  /// it will be ignored.
  ConsentDataModel<T> merge({
    required ConsentDataModel<T>? other,
  }) {
    if (other == null) {
      return this;
    }

    return ConsentDataModel(
      version: other.version,
      options: options.merge(options: other.options),
    );
  }

  /// Get the properties of the class
  @override
  List<Object?> get props => [
        version,
        options,
      ];
}
