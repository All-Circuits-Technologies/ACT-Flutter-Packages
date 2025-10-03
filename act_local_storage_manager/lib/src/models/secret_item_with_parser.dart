// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/src/mixins/mixin_parser_storage_item.dart';
import 'package:act_local_storage_manager/src/models/secret_item.dart';
import 'package:act_local_storage_manager/src/services/secrets_singleton.dart';

/// [SecretItemWithParser] wraps a single secret of type T, providing strongly-typed read
/// and write helpers.
///
/// If you don't want to keep those data secret, please consider to use `SharedPreferencesItem`.
///
/// This is is used to support more types than the ones already supported by the system, see:
///
/// {@macro act_local_storage_manager.MixinStringStorageSingleton.supportedTypes}
///
/// If you want to parse one of the supported types, please use `SecretItem` instead.
class SecretItemWithParser<ParsedType, StoredType> extends SecretItem<ParsedType>
    with MixinParserStorageItem<ParsedType, StoredType> {
  /// {@macro act_local_storage_manager.AbsParserStorageItem.parser}
  @override
  final ParsedType? Function(StoredType value) parser;

  /// {@macro act_local_storage_manager.AbsParserStorageItem.castTo}
  @override
  final StoredType? Function(ParsedType value) castTo;

  /// Class constructor
  const SecretItemWithParser(
    super.key, {
    required this.parser,
    required this.castTo,
    super.doNotMigrate,
  });

  /// {@macro act_local_storage_manager.AbsParserStorageItem.loadFromStorage}
  @override
  Future<StoredType?> loadFromStorage() => SecretsSingleton.instance.load<StoredType>(key: key);

  /// {@macro act_local_storage_manager.AbsParserStorageItem.storeToStorage}
  @override
  Future<bool> storeToStorage(StoredType value) => SecretsSingleton.instance
      .store<StoredType>(key: key, value: value, doNotMigrate: doNotMigrate);
}
