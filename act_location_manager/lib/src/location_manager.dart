// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abs_peripherals_manager/act_abs_peripherals_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_location_manager/src/models/location_init_config.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

/// Manager builder
class LocationBuilder extends DerivedLocationBuilder<LocationManager> {
  /// Class constructor with the class construction
  LocationBuilder() : super(LocationManager.new);
}

/// Builder used to create derived [LocationManager]
class DerivedLocationBuilder<T extends LocationManager> extends AbstractPeriphBuilder<T> {
  /// Class constructor
  DerivedLocationBuilder(super.factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [...super.dependsOn(), LoggerManager];
}

/// The location manager is useful to manage the location functionalities
///
/// Beware that to make it works, some elements have to be added in the iOS plist and android
/// manifest files, depending of what accuracy you want and if you want to get always position
class LocationManager extends AbstractPeriphManager {
  /// This is the logs category for the location manager
  static const logsCategory = "location";

  /// Location enabled stream subscription
  late final StreamSubscription _enabledSub;

  /// The manager configuration
  late final LocationInitConfig _initConfig;

  /// This is the logs helper of location manager
  late final LogsHelper _logsHelper;

  /// Class constructor
  LocationManager() : super();

  /// Initialize the manager
  @override
  Future<void> initLifeCycle() async {
    _initConfig = await getInitConfig();

    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: logsCategory,
    );

    // We get init config before calling super init manager, because [_initConfig] is used in
    // the [getPermissionsConfig] method. And this method is called in the super initLifeCycle
    // method.
    await super.initLifeCycle();

    // Initialize location service enabled status
    _enabledSub = Geolocator.getServiceStatusStream().listen(
      onServiceEnabled,
      onError: onLocationError,
    );
    setEnabled(await Geolocator.isLocationServiceEnabled());
  }

  /// Allows to get the init config
  ///
  /// If needed to change the default config, just override this method in the derived class
  @protected
  Future<LocationInitConfig> getInitConfig() async => const LocationInitConfig.defaultConfig();

  /// Get the permissions configuration linked to this mixin permissions service
  @override
  @mustCallSuper
  List<PermissionConfig> getPermissionsConfig() => [
        if (_initConfig.isLocationUsageAlways)
          PermissionConfig(
            element: PermissionElement.locationAlways,
            whenAskingForceGoToSettings: globalGetIt().get<PlatformManager>().isIos,
            whenAskingDependsOn: const [PermissionElement.locationWhenInUse],
          ),
        const PermissionConfig(
          element: PermissionElement.locationWhenInUse,
          whenAskingCheckRationale: true,
        ),
      ];

  /// This allow to return the enable service element type
  @override
  EnableServiceElement getElement() => EnableServiceElement.location;

  /// Manage the enabled asking by other managers or user
  /// Returns true if we successfully enable the service
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the service is not enabled, the method
  /// will ask to display a HMI to inform the user of the necessity to enable the service. If false,
  /// no HMI displayed is and we redirect the user to the system activation page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the service is disabled
  @override
  @mustCallSuper
  Future<bool> askForEnabling({
    bool isAcceptanceCompulsory = false,
    bool displayContextualIfNeeded = true,
  }) async {
    if (await Geolocator.isLocationServiceEnabled()) {
      // Nothing to do more
      // We set to true, in case the status hasn't been received correctly
      setEnabled(true);
      return true;
    }

    final result = await requestUser(
      isAcceptanceCompulsory: isAcceptanceCompulsory,
      displayContextualIfNeeded: displayContextualIfNeeded,
      manageEnabling: () async {
        final locationStatus = await MEnableService.openAppSettingAndWaitForUpdate<ServiceStatus>(
          isExpectedStatus: (status) => status == ServiceStatus.enabled,
          valueGetter: () async {
            final enabled = await Geolocator.isLocationServiceEnabled();

            return enabled ? ServiceStatus.enabled : ServiceStatus.disabled;
          },
          statusEmitter: Geolocator.getServiceStatusStream(),
          settingsType: AppSettingsType.location,
        );

        final isLocationEnabled = (locationStatus == ServiceStatus.enabled);

        return (isLocationEnabled, isLocationEnabled);
      },
    );

    if (!result.status.isPositiveResult || result.customResult == null) {
      // User has refuse to continue
      return false;
    }

    return result.customResult!;
  }

  /// Callback on location service enabled
  @protected
  @mustCallSuper
  Future<void> onServiceEnabled(ServiceStatus status) async {
    setEnabled(status == ServiceStatus.enabled);
  }

  /// Call when an error occurred in the stream of the library location status
  @protected
  @mustCallSuper
  Future<void> onLocationError(Object error) async {
    _logsHelper.e("An error occurred in the location library: $error");
  }

  /// Get the current position of the phone
  Future<Position?> getCurrentPosition({
    LocationAccuracy? overrideDefaultAccuracy,
    Duration? overrideDefaultTimeLimit,
    bool askPermissionToUser = true,
  }) async {
    if (!(await checkAndAskForPermissionsAndServices(
      askActionsToUser: askPermissionToUser,
    ))) {
      _logsHelper.w("We can't get the current location: the permissions and services aren't "
          "activated");
      return null;
    }

    Position? position;

    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: overrideDefaultAccuracy ?? _initConfig.accuracy,
          timeLimit: overrideDefaultTimeLimit ?? _initConfig.timeLimitWhenGettingPosition,
        ),
      );
    } catch (error) {
      _logsHelper.e('We failed to get the current position: $error');
      if (error is LocationServiceDisabledException) {
        setEnabled(false);
      }
    }

    return position;
  }

  /// Get the last known position of the phone
  ///
  /// If the location is disabled in the phone, this will return null (even if you retrieved
  /// positions before)
  Future<Position?> getLastKnownPosition({
    bool askPermissionToUser = true,
  }) async {
    if (!(await checkAndAskForPermissionsAndServices(
      askActionsToUser: askPermissionToUser,
    ))) {
      _logsHelper.w("We can't get the last known location: the permissions and services aren't "
          "activated");
      return null;
    }

    Position? position;

    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (error) {
      _logsHelper.e('We failed to get the last known position: $error');
      if (error is LocationServiceDisabledException) {
        setEnabled(false);
      }
    }

    return position;
  }

  /// Dispose method of the manager
  @override
  Future<void> disposeLifeCycle() async {
    final futuresList = <Future>[
      _enabledSub.cancel(),
    ];

    await Future.wait(futuresList);

    return super.disposeLifeCycle();
  }
}
