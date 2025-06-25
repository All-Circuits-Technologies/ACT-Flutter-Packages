// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/errors/act_config_null_value_error.dart';
import 'package:act_config_manager/src/models/abs_parser_config_var.dart';
import 'package:act_global_manager/act_global_manager.dart';

/// [NotNullParserConfigVar] wraps a single config variable of type T, providing strongly-typed
/// read helper.
///
/// If the config variable isn't defined in the environment, [load] method returns [defaultValue].
///
/// The value is parsed thanks to the [parser] method before it's returned.
class NotNullParserConfigVar<ParsedType, StoredType>
    extends AbsParserConfigVar<ParsedType, StoredType> {
  /// The default value to use when nothing is retrieved from config
  final ParsedType? defaultValue;

  /// Class constructor
  /// When null is retrieved from config, the [defaultValue] is returned.
  const NotNullParserConfigVar(
    super.key, {
    required ParsedType this.defaultValue,
    required super.parser,
  });

  /// Class constructor
  /// When null is retried from config, the [ActConfigNullValueError] is thrown.
  const NotNullParserConfigVar.crashIfNull(
    super.key, {
    required super.parser,
  })  : defaultValue = null,
        super();

  /// Load value from config variable.
  ///
  /// If the config variable isn't defined in the environment, the method will return the
  /// [defaultValue] and if [defaultValue] is null, the [ActConfigNullValueError] is raised.
  ParsedType load() {
    final value = loadAndParse() ?? defaultValue;
    if (value == null) {
      appLogger().e("The value of the config: $key, is null, we can't go further");
      throw ActConfigNullValueError(key: key);
    }

    return value;
  }

  @override
  List<Object?> get props => [...super.props, defaultValue];
}
