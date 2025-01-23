// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/models/abs_parser_config_var.dart';

/// [NotNullableConfigVar] wraps a single config variable of type T, providing strongly-typed
/// read helper.
///
/// If the config variable isn't defined in the environment, [load] method returns [defaultValue].
///
/// The value is parsed thanks to the [parser] method before it's returned.
class NotNullParserConfigVar<ParsedType, StoredType>
    extends AbsParserConfigVar<ParsedType, StoredType> {
  /// The default value to use when nothing is retrieved from config
  final ParsedType defaultValue;

  /// Class constructor
  /// If [defaultValue] isn't null, this value will be returned when null is retrieved from config.
  const NotNullParserConfigVar(
    super.key, {
    required this.defaultValue,
    required super.parser,
  });

  /// Load value from config variable.
  ///
  /// If the config variable isn't defined in the environment, the method will return the
  /// [defaultValue]
  ParsedType load() => loadAndParse() ?? defaultValue;

  @override
  List<Object?> get props => [...super.props, defaultValue];
}
