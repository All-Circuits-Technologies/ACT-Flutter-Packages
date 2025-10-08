// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_web_local_storage_manager/src/models/cookie_session_item.dart';
import 'package:act_web_local_storage_manager/src/services/cookie_session_singleton.dart';

/// This is the cookie session item
///
/// Use this class to store data in session cookies
///
/// {@macro act_local_storage_manager.MixinStringStorageSingleton.supportedTypes}
///
/// If you want to parse one of the supported types, please use `CookieSessionItem` instead.
class CookieSessionItemWithParser<ParsedType, StoredType> extends CookieSessionItem<ParsedType>
    with MixinParserStorageItem<ParsedType, StoredType> {
  /// {@macro act_local_storage_manager.AbsParserStorageItem.parser}
  @override
  final ParsedType? Function(StoredType value) parser;

  /// {@macro act_local_storage_manager.AbsParserStorageItem.castTo}
  @override
  final StoredType? Function(ParsedType value) castTo;

  /// Class constructor
  const CookieSessionItemWithParser(super.key, {required this.parser, required this.castTo});

  /// {@macro act_local_storage_manager.AbsParserStorageItem.loadFromStorage}
  @override
  Future<StoredType?> loadFromStorage() =>
      CookieSessionSingleton.instance.load<StoredType>(key: key);

  /// {@macro act_local_storage_manager.AbsParserStorageItem.storeToStorage}
  @override
  Future<bool> storeToStorage(StoredType value) =>
      CookieSessionSingleton.instance.store<StoredType>(key: key, value: value);
}
