// Copyright (c) 2020. BMS Circuits

import 'package:act_thingsboard/src/model/attribute_scope.dart';
import 'package:act_thingsboard/src/tb_global_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

/// Name of the device attributes managed by the application
class AttributeName<T> extends Equatable {
  final T value;
  final AttributeScope scope;
  final Type type;

  String get strBase => value.toString().split('.').last;

  bool get readOnly => (scope == AttributeScope.client ||
      scope == AttributeScope.serverReadOnly);

  String get strKeyForServer {
    if (this.readOnly) {
      // Can't set a client attribute or a read only server attribute
      return null;
    }

    String prefix = scope.getPrefix(fromDevice: false);

    String strBase = this.strBase;

    return prefix + strBase[0].toUpperCase() + strBase.substring(1);
  }

  AttributeName({
    @required this.value,
    @required this.scope,
    @required this.type,
  })  : assert(value != null),
        assert(scope != null),
        assert(type != null),
        super();

  @override
  List<Object> get props => [value, scope, type];
}

/// Contains helper methods to manage [AttributeName]
abstract class AbstractAttributeNameHelper<T> {
  final Set<AttributeName<T>> attributes;
  List<AttributeName<T>> _storeInMemory;

  AbstractAttributeNameHelper({
    @required this.attributes,
  }) : assert(attributes != null);

  static Tuple2<String, String> _getAttrPrefixAndName(String attributeName) {
    String prefix = "";

    if (attributeName
        .startsWith(AttributeScopeHelper.prefixServerSharedModifiable)) {
      prefix = AttributeScopeHelper.prefixServerSharedModifiable;
    } else if (attributeName
        .startsWith(AttributeScopeHelper.prefixClientSideOnly)) {
      prefix = AttributeScopeHelper.prefixClientSideOnly;
    } else if (attributeName
        .startsWith(AttributeScopeHelper.prefixClientSideModifiable)) {
      prefix = AttributeScopeHelper.prefixClientSideModifiable;
    } else if (attributeName
        .startsWith(AttributeScopeHelper.prefixServerSharedOnly)) {
      prefix = AttributeScopeHelper.prefixServerSharedOnly;
    } else if (attributeName
        .startsWith(AttributeScopeHelper.prefixServerRwSideApplication)) {
      prefix = AttributeScopeHelper.prefixServerRwSideApplication;
    } else if (attributeName
        .startsWith(AttributeScopeHelper.prefixServerRoSideApplication)) {
      prefix = AttributeScopeHelper.prefixServerRoSideApplication;
    }

    return Tuple2<String, String>(
      prefix,
      attributeName.substring(prefix.length),
    );
  }

  /// Parse an attribute name got from server
  ///
  /// This will test prefix, remove it, to return the right [AttributeName]
  ///
  /// The [AttributeScope.sharedOneWay] attributes aren't read from server
  /// because we only use them to send data to devices (we don't care about
  /// those values)
  AttributeName parseFromServer(String attributeName) {
    Tuple2<String, String> attrNameParts = _getAttrPrefixAndName(attributeName);

    if (attrNameParts.item1 ==
        AttributeScopeHelper.prefixServerSharedModifiable) {
      // Don't read the SHM attributes returned by the server
      return null;
    }

    if (attrNameParts.item1 != AttributeScopeHelper.prefixClientSideOnly &&
        attrNameParts.item1 !=
            AttributeScopeHelper.prefixClientSideModifiable &&
        attrNameParts.item1 != AttributeScopeHelper.prefixServerSharedOnly &&
        attrNameParts.item1 !=
            AttributeScopeHelper.prefixServerRwSideApplication &&
        attrNameParts.item1 !=
            AttributeScopeHelper.prefixServerRoSideApplication) {
      AppLogger().i("Unknown prefix for the attribute name: "
          "$attributeName");
      return null;
    }

    for (AttributeName tmp in attributes) {
      if (tmp.strBase.toLowerCase() == attrNameParts.item2.toLowerCase()) {
        return tmp;
      }
    }

    // We don't log if there is an unknown attribute in case the device FW is
    // more recent than the mobile app and there is an unknown attribute
    return null;
  }

  /// Get the list of [AttributeName] to store in memory
  List<AttributeName> getAttributesStoredInMemory() {
    if (_storeInMemory == null) {
      _storeInMemory = [];
      attributes.forEach((element) {
        if (element.scope == AttributeScope.serverReadWrite) {
          _storeInMemory.add(element);
        }
      });
    }

    return _storeInMemory;
  }
}
