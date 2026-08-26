// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

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
  FakePlatformManager({this.isAndroid = false, this.isIos = false, this.version});

  /// The platform of an Android device running the given [version] of the system.
  factory FakePlatformManager.android({int? version}) =>
      FakePlatformManager(isAndroid: true, version: version);

  /// The platform of an iOS device.
  factory FakePlatformManager.ios() => FakePlatformManager(isIos: true, version: 17);
}

/// The life cycle of an application under test, driven by the test.
///
/// A real manager reads the life cycle from the binding of the application; this one is told when
/// the application is left and when it comes back.
class FakeAppLifeCycleManager extends AppLifeCycleManager {
  /// The stream the life cycle of the application is told over.
  final StreamController<AppLifecycleState?> _ctrl =
      StreamController<AppLifecycleState?>.broadcast();

  /// The number of times the application was asked to wait for its own return.
  int waitCount = 0;

  /// {@macro act_app_life_cycle_manager.AppLifeCycleManager.lifeCycleStream}
  @override
  Stream<AppLifecycleState?> get lifeCycleStream => _ctrl.stream;

  /// Tells the application that it is now in [state].
  Future<void> goTo(AppLifecycleState state) async {
    _ctrl.add(state);

    return Future.delayed(Duration.zero);
  }

  /// {@macro act_app_life_cycle_manager.AppLifeCycleManager.waitForegroundApp}
  ///
  /// The application is told that it was left and that it came back, which is what a real manager
  /// waits for and what has the permissions read again.
  @override
  Future<void> waitForegroundApp({required Future<bool> Function() leaveTheApp}) async {
    waitCount++;
    await goTo(AppLifecycleState.paused);
    await leaveTheApp();
    await goTo(AppLifecycleState.resumed);
  }

  /// Stops telling the application about its life cycle.
  Future<void> close() => _ctrl.close();
}

/// The permissions of the device, answered by the test.
///
/// This is what the plugin of the permissions reads and writes; the test decides the status of each
/// permission and reads back which ones were requested.
class FakePermissionsPlatform extends PermissionHandlerPlatform {
  /// The status of each permission, the ones which are absent being denied.
  final Map<Permission, PermissionStatus> statuses = {};

  /// The status a permission takes once it has been requested, per permission.
  ///
  /// A permission which is absent is granted once it has been requested.
  final Map<Permission, PermissionStatus> answersToRequest = {};

  /// The permissions the user has already refused once.
  final Set<Permission> rationales = {};

  /// The permissions which were requested, in the order they were.
  final List<Permission> requested = [];

  /// The permissions whose status was read, in the order they were.
  final List<Permission> checked = [];

  /// The number of times the settings of the application were opened.
  int settingsCount = 0;

  /// What the settings of the application become when they are opened.
  Map<Permission, PermissionStatus> settingsAnswer = {};

  /// Installs this platform as the one the plugin of the permissions reads.
  static FakePermissionsPlatform install() {
    final platform = FakePermissionsPlatform();
    PermissionHandlerPlatform.instance = platform;

    return platform;
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    checked.add(permission);

    return statuses[permission] ?? PermissionStatus.denied;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    final answers = <Permission, PermissionStatus>{};

    for (final permission in permissions) {
      requested.add(permission);
      final answer = answersToRequest[permission] ?? PermissionStatus.granted;
      statuses[permission] = answer;
      answers[permission] = answer;
    }

    return answers;
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async =>
      rationales.contains(permission);

  @override
  Future<bool> openAppSettings() async {
    settingsCount++;
    statuses.addAll(settingsAnswer);

    return true;
  }
}

/// The pages of an application under test.
enum FakePermRoute with MixinRoute {
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
///
/// A real router needs a view to push a page into; the contextual views of the tests answer without
/// one, so the router is only there for the manager to be built.
class FakePermRouterManager extends AbstractRouterManager<FakePermRoute> {
  /// {@macro act_router_manager.AbstractRouterManager.getCurrentTopView}
  @override
  FakePermRoute? getCurrentTopView() => FakePermRoute.home;

  /// {@macro act_router_manager.AbstractRouterManager.createRoutesHelper}
  @override
  Future<AbstractRoutesHelper<FakePermRoute>> createRoutesHelper(LogsHelper logsHelper) =>
      throw UnimplementedError("The router of a test pushes no real page");
}

/// What a view of the application answers when a permission is asked of the user.
typedef PermissionViewAnswer =
    Future<ViewDisplayResult<PermissionStatus>> Function(DoActionDisplayCallback? doAction);

/// The views an application under test displays when a permission is asked of the user.
class FakePermViewBuilder extends AbstractViewBuilder {
  /// What the view of each action answers.
  final Map<PermissionViewAction, PermissionViewAnswer> answers;

  /// The actions the views of which were displayed, in the order they were.
  final List<PermissionViewAction> displayed = [];

  /// The number of times the builder was disposed.
  int disposeCount = 0;

  /// Class constructor
  FakePermViewBuilder({required this.answers});

  /// {@macro act_contextual_views_manager.AbstractViewBuilder.dispose}
  @override
  Future<void> dispose() async => disposeCount++;

  /// {@macro act_contextual_views_manager.AbstractViewBuilder.initProcess}
  @override
  Future<void> initProcess() async {
    for (final element in PermissionElement.values) {
      for (final action in PermissionViewAction.values) {
        registerAbsViewDisplay(
          context: PermissionViewContext(element: element, action: action),
          callback: (context, doAction) async {
            displayed.add(action);

            return answers[action]?.call(doAction) ??
                const ViewDisplayResult<PermissionStatus>.error();
          },
        );
      }
    }
  }

  /// The view which lets the user answer, and which asks the permission itself.
  static PermissionViewAnswer theUserAnswers() => (doAction) async {
    final result = await doAction?.call();

    return ViewDisplayResult<PermissionStatus>(
      status: (result?.$1 ?? false) ? ViewDisplayStatus.yes : ViewDisplayStatus.no,
      customResult: result?.$2 as PermissionStatus?,
    );
  };

  /// The view the user leaves without answering.
  static PermissionViewAnswer theUserLeaves() => (doAction) async =>
      const ViewDisplayResult<PermissionStatus>(status: ViewDisplayStatus.no);
}

/// A service of an application which needs the permissions of [configs].
class FakePermissionsService extends AbsWithLifeCycle with MPermissionsService {
  /// The permissions the service needs.
  final List<PermissionConfig> configs;

  /// Class constructor
  FakePermissionsService(this.configs);

  /// {@macro act_permissions_manager.MPermissionsService.getPermissionsConfig}
  @override
  List<PermissionConfig> getPermissionsConfig() => configs;
}

/// The builder of a service of an application which needs permissions.
class FakePermissionsServiceBuilder extends AbsLifeCycleFactory<FakePermissionsService>
    with MPermissionsServiceBuilder<FakePermissionsService> {
  /// Class constructor
  const FakePermissionsServiceBuilder(super.factory);
}
