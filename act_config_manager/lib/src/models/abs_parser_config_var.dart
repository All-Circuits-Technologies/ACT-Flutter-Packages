// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/models/abs_config_var.dart';
import 'package:flutter/foundation.dart';

/// The function to parse a config value to a new type.
/// The StoredType can be:
///
/// - boolean,
/// - string,
/// - number,
/// - Map<string, dynamic>
/// - List<dynamic>
typedef ParserFunc<ParsedType, StoredType> = ParsedType? Function(StoredType value);

/// This class allows to access a config variable value which needs to be parsed before being got.
/// This class has to be used, when you want to get enum, class or other complex objects from the
/// conf variables.
abstract class AbsParserConfigVar<ParsedType, StoredType> extends AbsConfigVar<StoredType> {
  /// The parser method to use
  final ParserFunc<ParsedType, StoredType> parser;

  /// Class constructor
  const AbsParserConfigVar(
    super.key, {
    required this.parser,
  });

  /// This method is used to load the config variable and parse it.
  ///
  /// Returns null if the variable hasn't been found or if the parsing has failed
  @protected
  ParsedType? loadAndParse() {
    final storedValue = configs.tryToGet<StoredType>(key);

    if (storedValue == null) {
      return null;
    }
    return parser(storedValue);
  }
}
