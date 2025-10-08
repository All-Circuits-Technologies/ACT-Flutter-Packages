// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/src/models/abs_storage_item.dart';
import 'package:flutter/foundation.dart';

/// This class allows to access an item value from storage which needs to be parsed before being
/// retrieved.
/// This class has to be used, when you want to get enum, class or other complex objects from the
/// storage.
mixin MixinParserStorageItem<ParsedType, StoredType> on AbsStorageItem<ParsedType> {
  /// {@template act_local_storage_manager.AbsParserStorageItem.parser}
  /// This is used to parse the value stored to the wanted type
  ///
  /// Returns null if the `value` given is null or if the parsing has failed
  /// {@endtemplate}
  ParsedType? Function(StoredType value) get parser;

  /// {@template act_local_storage_manager.AbsParserStorageItem.castTo}
  /// Cast the `value` given to the right type
  ///
  /// A null value can be stored as null, as a class instance or not authorized to be stored;
  /// that's why we return return a tuple here.
  /// {@endtemplate}
  StoredType? Function(ParsedType value) get castTo;

  /// {@macro act_local_storage_manager.AbsStorageItem.load}
  @override
  Future<ParsedType?> load() async {
    final storedValue = await loadFromStorage();
    if (storedValue == null) {
      return null;
    }

    return parser(storedValue);
  }

  /// {@macro act_local_storage_manager.AbsStorageItem.store}
  @override
  Future<bool> store(ParsedType? value) async {
    if (value == null) {
      await delete();
      return true;
    }

    final toStoreResult = castTo(value);
    if (toStoreResult == null) {
      return false;
    }

    return storeToStorage(toStoreResult);
  }

  /// {@template act_local_storage_manager.AbsParserStorageItem.loadFromStorage}
  /// This is used to load value from storage.
  /// {@endtemplate}
  @protected
  Future<StoredType?> loadFromStorage();

  /// {@template act_local_storage_manager.AbsParserStorageItem.storeToStorage}
  /// Store value to storage.
  /// {@endtemplate}
  @protected
  Future<bool> storeToStorage(StoredType value);

  /// {@macro act_local_storage_manager.AbsStorageItem.props}
  @override
  List<Object?> get props => [...super.props, parser, castTo];
}
