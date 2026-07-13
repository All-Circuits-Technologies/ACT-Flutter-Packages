// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:equatable/equatable.dart';

/// This class represents the information of a license text, it contains the license key and the
/// license text.
class LicensesTextModel extends Equatable {
  /// The licenses text of elements (which can be packages, images, the application, fonts, etc.)
  ///
  /// The key of the map is the license key and the value is the license text.
  final Map<String, String> licensesText;

  /// Class constructor
  const LicensesTextModel({required this.licensesText});

  /// This constructor creates an empty instance of the class.
  const LicensesTextModel.empty() : licensesText = const {};

  /// This method creates a copy of the current instance with the given parameters.
  LicensesTextModel copyWith({Map<String, String>? licensesText}) =>
      LicensesTextModel(licensesText: licensesText ?? this.licensesText);

  /// This method parses a json object to create an instance of the class
  static LicensesTextModel fromJson(Map<String, dynamic> json) {
    final licensesText = <String, String>{};

    for (final entry in json.entries) {
      final key = entry.key;
      final tmpText = JsonUtility.getNotNullOnePrimaryElement<String>(
        json: json,
        key: key,
        logger: appLogger(),
      );

      if (tmpText == null) {
        appLogger().w("The license text of the license $key is not valid, skipping it.");
        continue;
      }

      licensesText[key] = tmpText;
    }

    return LicensesTextModel(licensesText: licensesText);
  }

  /// Class properties
  @override
  List<Object?> get props => [licensesText];
}
