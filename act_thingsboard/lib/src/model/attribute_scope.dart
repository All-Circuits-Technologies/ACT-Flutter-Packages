// Copyright (c) 2020. BMS Circuits

import 'package:act_thingsboard/src/tb_global_manager.dart';

/// Defines the scope of the [AttributeName]
///
/// Attributes scoped [AttributeScope.client] is set by the device and can only
/// be read by the mobile app
/// Attributes scoped [AttributeScope.sharedTwoWays] is set by the mobile app
/// and the device. When you modify an attribute [AttributeScope.sharedTwoWays],
/// the device analyze the asking and returns the new value by the same
/// attribute
/// [AttributeScope.client]
enum AttributeScope {
  client,
  sharedTwoWays,
  sharedOneWay,
  serverReadWrite,
  serverReadOnly,
}

/// Extension of the [AttributeScope] class
extension AttributeScopeExtension on AttributeScope {
  /// Return the prefix linked to the [AttributeScope]
  ///
  /// The [fromDevice] parameter is only used for [AttributeScope.sharedTwoWays]
  /// parameters.
  /// If [AttributeScope.sharedTwoWays] and [fromDevice] is equal to true, it
  /// means that we want the attribute prefix of an attribute got from device
  /// If [AttributeScope.sharedTwoWays] and [fromDevice] is equal to false, it
  /// means that we want the attribute prefix of an attribute to send to device
  String getPrefix({bool fromDevice = true}) {
    switch (this) {
      case AttributeScope.client:
        return AttributeScopeHelper.prefixClientSideOnly;

      case AttributeScope.serverReadWrite:
        return AttributeScopeHelper.prefixServerRwSideApplication;

      case AttributeScope.sharedTwoWays:
        if (fromDevice) {
          return AttributeScopeHelper.prefixClientSideModifiable;
        }

        return AttributeScopeHelper.prefixServerSharedModifiable;

      case AttributeScope.sharedOneWay:
        return AttributeScopeHelper.prefixServerSharedOnly;

      case AttributeScope.serverReadOnly:
        return AttributeScopeHelper.prefixServerRoSideApplication;
    }

    AppLogger().w("A case is not managed for getting the prefix of: "
        "$this");
    return "";
  }

  /// Get the scope to write in server request depending of the [AttributeScope]
  String get requestScope {
    switch (this) {
      case AttributeScope.client:
        return AttributeScopeHelper.requestScopeClient;
      case AttributeScope.sharedOneWay:
      case AttributeScope.sharedTwoWays:
        return AttributeScopeHelper.requestScopeShared;
      case AttributeScope.serverReadWrite:
      case AttributeScope.serverReadOnly:
        return AttributeScopeHelper.requestScopeServer;
    }

    AppLogger().w("A case is not managed for getting the request scope "
        "of: $this");
    return "";
  }
}

/// Helper class for [AttributeScope] enum
class AttributeScopeHelper {
  static const String prefixClientSideOnly = "cso";
  static const String prefixClientSideModifiable = "csm";
  static const String prefixServerSharedOnly = "sho";
  static const String prefixServerSharedModifiable = "shm";
  static const String prefixServerRwSideApplication = "ssa";
  static const String prefixServerRoSideApplication = "";

  static const String requestScopeServer = "SERVER_SCOPE";
  static const String requestScopeClient = "CLIENT_SCOPE";
  static const String requestScopeShared = "SHARED_SCOPE";
}
