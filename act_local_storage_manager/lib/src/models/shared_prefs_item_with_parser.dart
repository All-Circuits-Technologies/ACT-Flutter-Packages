// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/src/mixins/mixin_parser_storage_item.dart';
import 'package:act_local_storage_manager/src/models/shared_preferences_item.dart';
import 'package:act_local_storage_manager/src/services/properties_singleton.dart';

/// [SecretItemWithParser] wraps a single secret of type T, providing strongly-typed read
/// and write helpers.
///
/// If you don't want to keep those data secret, please consider to use `SharedPreferencesItem`.
///
/// This is is used to support more types than the ones already supported by the system, see:
///
/// {@macro act_local_storage_manager.SecretsSingleton.supportedTypes}
///
/// If you want to parse one of the supported types, please use `SecretItem` instead.
class SharedPrefsItemWithParser<ParsedType, StoredType> extends SharedPreferencesItem<ParsedType>
    with MixinParserStorageItem<ParsedType, StoredType> {
  /// {@macro act_local_storage_manager.AbsParserStorageItem.parser}
  @override
  final ParsedType? Function(StoredType value) parser;

  /// {@macro act_local_storage_manager.AbsParserStorageItem.castTo}
  @override
  final StoredType? Function(ParsedType value) castTo;

  /// Class constructor
  SharedPrefsItemWithParser(
    super.key, {
    required this.parser,
    required this.castTo,
  });

  /// {@macro act_local_storage_manager.AbsParserStorageItem.loadFromStorage}
  @override
  Future<StoredType?> loadFromStorage() async =>
      PropertiesSingleton.instance.load<StoredType>(key: key);

  /// {@macro act_local_storage_manager.AbsParserStorageItem.storeToStorage}
  @override
  Future<bool> storeToStorage(StoredType value) async =>
      PropertiesSingleton.instance.store<StoredType>(key: key, value: value);

  /// {@macro act_local_storage_manager.AbsStorageItem.store}
  @override
  Future<bool> store(ParsedType? value) async {
    final success = await super.store(value);
    if (!success) {
      return false;
    }

    emitEventIfNecessary(value);
    return true;
  }
}
