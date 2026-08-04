// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_location_manager/act_location_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    hide ServiceStatus;

/// A position of the device, at the given [latitude] and [longitude].
Position aPosition({double latitude = 48.1, double longitude = -1.7}) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime.utc(2026),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// The platform the tests say the application runs on.
class FakePlatformManager extends PlatformManager {
  /// Whether the application runs on Android.
  @override
  final bool isAndroid;

  /// Whether the application runs on iOS.
  @override
  final bool isIos;

  /// The version of the system the application runs on.
  @override
  final int? version;

  /// Class constructor
  FakePlatformManager({this.isAndroid = true, this.isIos = false, this.version = 34});

  /// The platform of an iOS device.
  factory FakePlatformManager.ios() =>
      FakePlatformManager(isAndroid: false, isIos: true, version: 17);
}

/// The life cycle of an application under test.
class FakeAppLifeCycleManager extends AppLifeCycleManager {
  final StreamController<AppLifecycleState?> _ctrl =
      StreamController<AppLifecycleState?>.broadcast();

  /// The number of times the application was asked to wait for its own return.
  int waitCount = 0;

  /// {@macro act_app_life_cycle_manager.AppLifeCycleManager.lifeCycleStream}
  @override
  Stream<AppLifecycleState?> get lifeCycleStream => _ctrl.stream;

  /// {@macro act_app_life_cycle_manager.AppLifeCycleManager.waitForegroundApp}
  @override
  Future<void> waitForegroundApp({required Future<bool> Function() leaveTheApp}) async {
    waitCount++;
    _ctrl.add(AppLifecycleState.paused);
    await leaveTheApp();
    _ctrl.add(AppLifecycleState.resumed);
  }

  /// Stops telling the application about its life cycle.
  Future<void> close() => _ctrl.close();
}

/// The permissions of the device, answered by the test.
class FakePermissionsPlatform extends PermissionHandlerPlatform {
  /// The status of each permission, the ones which are absent being denied.
  final Map<Permission, PermissionStatus> statuses = {};

  /// The status a permission takes once it has been requested.
  PermissionStatus answerToRequest = PermissionStatus.granted;

  /// Installs this platform as the one the plugin of the permissions reads.
  static FakePermissionsPlatform install() {
    final platform = FakePermissionsPlatform();
    PermissionHandlerPlatform.instance = platform;

    return platform;
  }

  /// Says that the device granted every permission the location asks for.
  void grantEverything() {
    statuses[Permission.locationWhenInUse] = PermissionStatus.granted;
    statuses[Permission.locationAlways] = PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      statuses[permission] ?? PermissionStatus.denied;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      statuses[permission] = answerToRequest;
    }

    return {for (final permission in permissions) permission: answerToRequest};
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async => false;

  @override
  Future<bool> openAppSettings() async => true;
}

/// The location of the device, answered by the test.
///
/// This is what the plugin of the location reads; the test says whether the service is switched on
/// and which position the device answers.
class FakeGeolocatorPlatform extends GeolocatorPlatform {
  /// The stream the service of the location is told over.
  final StreamController<ServiceStatus> _statusCtrl = StreamController<ServiceStatus>.broadcast();

  /// Whether the service of the location is switched on.
  bool serviceEnabled = true;

  /// The position the device answers, if it answers any.
  Position? position;

  /// The error the device raises rather than answering a position, if it raises any.
  Exception? error;

  /// The settings the device was asked for a position with, in the order they were.
  final List<LocationSettings?> asked = [];

  /// Installs this platform as the one the plugin of the location reads.
  static FakeGeolocatorPlatform install() {
    final platform = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = platform;

    return platform;
  }

  /// Tells the application that the service of the location is now [status].
  Future<void> tellService(ServiceStatus status) async {
    serviceEnabled = status == ServiceStatus.enabled;
    _statusCtrl.add(status);

    return Future.delayed(Duration.zero);
  }

  /// Tells the application that the service of the location raised an error.
  Future<void> tellError(Object raised) async {
    _statusCtrl.addError(raised);

    return Future.delayed(Duration.zero);
  }

  /// Stops telling the application about the service of the location.
  Future<void> close() => _statusCtrl.close();

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Stream<ServiceStatus> getServiceStatusStream() => _statusCtrl.stream;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    asked.add(locationSettings);

    if (error != null) {
      throw error!;
    }

    return position ?? aPosition();
  }

  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) async {
    if (error != null) {
      throw error!;
    }

    return position;
  }
}

/// The settings of the device, answered by the test.
///
/// The plugin of the settings reads them over a platform channel; this answers on that channel and
/// records which page of the settings was asked for.
sealed class FakeAppSettings {
  /// The channel the plugin of the settings talks over.
  static const channel = MethodChannel("com.spencerccf.app_settings/methods");

  /// The pages of the settings which were asked for, in the order they were.
  static final List<String> opened = [];

  /// Answers on the channel of the settings, and forgets the pages of a previous test.
  static void serve() {
    opened.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        opened.add(call.method);

        return null;
      },
    );
  }

  /// Stops answering on the channel of the settings.
  static void stop() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
    opened.clear();
  }
}

/// The pages of an application under test.
enum FakeLocationRoute with MixinRoute {
  /// The page the application starts on.
  home;

  /// {@macro act_router_manager.MixinRoute.parent}
  @override
  MixinRoute? get parent => null;

  /// {@macro act_router_manager.MixinRoute.transition}
  @override
  RouteTransition? get transition => null;

  /// {@macro act_router_manager.MixinRoute.screenOrientation}
  @override
  ScreenOrientationOption? get screenOrientation => null;
}

/// The router of an application under test.
class FakeLocationRouterManager extends AbstractRouterManager<FakeLocationRoute> {
  /// {@macro act_router_manager.AbstractRouterManager.getCurrentTopView}
  @override
  FakeLocationRoute? getCurrentTopView() => FakeLocationRoute.home;

  /// {@macro act_router_manager.AbstractRouterManager.createRoutesHelper}
  @override
  Future<AbstractRoutesHelper<FakeLocationRoute>> createRoutesHelper(LogsHelper logsHelper) =>
      throw UnimplementedError("The router of a test pushes no real page");
}

/// The views an application under test displays when something has to be switched on.
class FakeLocationViewBuilder extends AbstractViewBuilder {
  /// Whether the user agrees to switch the service on.
  bool userAgrees;

  /// The reasons the views of which were displayed, in the order they were.
  final List<AbstractViewContext> displayed = [];

  /// Class constructor
  FakeLocationViewBuilder({this.userAgrees = true});

  /// {@macro act_contextual_views_manager.AbstractViewBuilder.initProcess}
  @override
  Future<void> initProcess() async {
    for (final element in EnableServiceElement.values) {
      registerAbsViewDisplay(
        context: EnableServiceViewContext(element: element),
        callback: (context, doAction) async {
          displayed.add(context);

          if (!userAgrees) {
            return const ViewDisplayResult<bool>(status: ViewDisplayStatus.no);
          }

          final result = await doAction?.call();

          return ViewDisplayResult<Object?>(
            status: (result?.$1 ?? true) ? ViewDisplayStatus.ok : ViewDisplayStatus.error,
            customResult: result?.$2,
          );
        },
      );
    }

    for (final element in PermissionElement.values) {
      for (final action in PermissionViewAction.values) {
        registerAbsViewDisplay(
          context: PermissionViewContext(element: element, action: action),
          callback: (context, doAction) async {
            displayed.add(context);
            final result = await doAction?.call();

            return ViewDisplayResult<Object?>(
              status: (result?.$1 ?? true) ? ViewDisplayStatus.ok : ViewDisplayStatus.no,
              customResult: result?.$2,
            );
          },
        );
      }
    }
  }

  /// {@macro act_contextual_views_manager.AbstractViewBuilder.dispose}
  @override
  Future<void> dispose() async {}
}

/// A location manager whose configuration is the one of the test.
class FakeLocationManager extends LocationManager {
  /// The configuration the manager reads.
  final LocationInitConfig config;

  /// The errors the service of the location raised, in the order they were raised.
  final List<Object> errors = [];

  /// Class constructor
  FakeLocationManager({this.config = const LocationInitConfig.defaultConfig()});

  /// The permissions the manager needs, which is what it declares to the permissions service.
  List<PermissionConfig> permissions() => getPermissionsConfig();

  /// {@macro act_location_manager.LocationManager.getInitConfig}
  @override
  Future<LocationInitConfig> getInitConfig() async => config;

  /// {@macro act_location_manager.LocationManager.onLocationError}
  @override
  Future<void> onLocationError(Object error) async {
    errors.add(error);

    return super.onLocationError(error);
  }
}
