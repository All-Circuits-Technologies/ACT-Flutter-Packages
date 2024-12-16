// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/models/abs_parser_config_var.dart';

/// [ConfigVar] wraps a single config variable of type T, providing strongly-typed read helper.
///
/// If the config variable isn't defined in the environment, [load] method returns null
///
/// The value is parsed thanks to the [parser] method before it's returned.
class ParserConfigVar<ParsedType, StoredType> extends AbsParserConfigVar<ParsedType, StoredType> {
  /// Class constructor
  const ParserConfigVar(
    super.key, {
    required super.parser,
  });

  /// Load value from config variable.
  ///
  /// If the env variable isn't defined in the environment, the method will return null.
  ParsedType? load() => loadAndParse();
}
