// Copyright (c) 2020. BMS Circuits

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:location/location.dart';

class LocationBuilder extends ManagerBuilder<LocationManager> {
  /// Class constructor with the class construction
  LocationBuilder() : super(() => LocationManager());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// The location manager is useful to manage the location functionalities
///
/// BEWARE This manager can only be used with Android device
class LocationManager extends AbstractManager {
  Location _location;

  LocationManager() : super();

  /// Test the current location permission
  Future<PermissionStatus> get hasPermission async =>
      _location?.hasPermission();

  @override
  Future<void> initManager() {
    if (Platform.isIOS) {
      AppLogger().i("We don't support the location in IOS for now, if you "
          "want to do so, add the needed permissions in Info.plist: "
          "NSLocationWhenInUseUsageDescription and "
          "NSLocationAlwaysUsageDescription");
      return null;
    }

    _location = Location();
    return null;
  }

  /// This allow to test if the location service is enabled
  Future<bool> get serviceEnabled async {
    assert(
        _location != null,
        "We don't support the location in IOS for now, "
        "can't do this");
    if (_location == null) {
      AppLogger().w("We don't support the location in IOS for now, can't "
          "do this");
      return false;
    }

    // TODO The [serviceEnabled] returns true when the GPS is in battery saving
    // TODO mode; therefore it will always returns true even if the GPS doesn't
    // TODO seem to be switch on.
    // TODO See: https://github.com/Lyokone/flutterlocation/issues/406
    // return _location.serviceEnabled();
    return false;
  }

  /// This allow to enable the precise location service and also to ask the
  /// permission to the user
  Future<bool> startLocation() async {
    assert(
        _location != null,
        "We don't support the location in IOS for now, "
        "can't do this");
    if (_location == null) {
      AppLogger().w("We don't support the location in IOS for now, can't "
          "do this");
      return false;
    }

    var permissionStatus = await _location.hasPermission();

    if (permissionStatus == PermissionStatus.deniedForever) {
      AppLogger().w("The location permission has been denied forever, "
          "can't proceed.");
      return false;
    }

    if (permissionStatus != PermissionStatus.granted) {
      permissionStatus = await _location.requestPermission();

      if (permissionStatus != PermissionStatus.granted) {
        AppLogger().w("The user has denied the permission, can't "
            "proceed");
        return false;
      }
    }

    if (await serviceEnabled) {
      // Already enabled, do nothing
      return true;
    }

    // This will always return false on iOS
    return await _location.requestService();
  }
}
