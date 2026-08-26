// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The element the services of the tests enable.
const anElement = EnableServiceElement.ble;

/// The life cycle of an application under test, driven by the test.
///
/// A real manager reads the life cycle from the binding of the application; this one tells the
/// application that it was left and that it came back as soon as it is asked to wait for it.
class FakeAppLifeCycleManager extends AppLifeCycleManager {
  /// The stream the life cycle of the application is told over.
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
enum FakeServiceRoute with MixinRoute {
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
class FakeServiceRouterManager extends AbstractRouterManager<FakeServiceRoute> {
  /// {@macro act_router_manager.AbstractRouterManager.getCurrentTopView}
  @override
  FakeServiceRoute? getCurrentTopView() => FakeServiceRoute.home;

  /// {@macro act_router_manager.AbstractRouterManager.createRoutesHelper}
  @override
  Future<AbstractRoutesHelper<FakeServiceRoute>> createRoutesHelper(LogsHelper logsHelper) =>
      throw UnimplementedError("The router of a test pushes no real page");
}

/// The views an application under test displays when a service has to be enabled.
class FakeServiceViewBuilder extends AbstractViewBuilder {
  /// Whether the user agrees to enable the service.
  bool userAgrees;

  /// The reasons the views of which were displayed, in the order they were.
  final List<AbstractViewContext> displayed = [];

  /// Class constructor
  FakeServiceViewBuilder({this.userAgrees = true});

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
  }

  /// {@macro act_contextual_views_manager.AbstractViewBuilder.dispose}
  @override
  Future<void> dispose() async {}
}

/// A service of an application which asks the user to enable a system service.
class FakeEnableService extends AbsWithLifeCycle with MEnableService {
  /// The element the service enables.
  final EnableServiceElement element;

  /// Whether the enabling the service does itself succeeds.
  bool enablingWorks;

  /// The number of times the service was asked to enable itself.
  int askCount = 0;

  /// Class constructor
  FakeEnableService({this.element = anElement, this.enablingWorks = true});

  /// Tells the application that the system service is now enabled or not.
  void tellEnabled({required bool isEnabled}) => setEnabled(isEnabled);

  /// Asks the user through the pages of the application, and answers what the view answered.
  Future<ViewDisplayResult<bool>> ask({
    EnableServiceViewContext? overrideContext,
    bool isAcceptanceCompulsory = false,
    bool displayContextualIfNeeded = true,
    bool withEnabling = true,
  }) => requestUser<bool>(
    overrideContext: overrideContext,
    isAcceptanceCompulsory: isAcceptanceCompulsory,
    displayContextualIfNeeded: displayContextualIfNeeded,
    manageEnabling: withEnabling
        ? () async {
            askCount++;
            setEnabled(enablingWorks);

            return (enablingWorks, enablingWorks);
          }
        : null,
  );

  /// Opens the settings of the device and waits for the service to be enabled.
  Future<bool> openSettings({
    AppSettingsType settingsType = AppSettingsType.bluetooth,
    Duration timeout = const Duration(milliseconds: 200),
  }) => MEnableService.openAppSettingAndWaitForUpdate<bool>(
    isExpectedStatus: (status) => status,
    valueGetter: () => isEnabled,
    statusEmitter: enabledStream,
    settingsType: settingsType,
    timeout: timeout,
  );

  /// {@macro act_enable_service_utility.MEnableService.askForEnabling}
  @override
  Future<bool> askForEnabling({
    bool isAcceptanceCompulsory = false,
    bool displayContextualIfNeeded = true,
  }) async {
    askCount++;
    setEnabled(enablingWorks);

    return enablingWorks;
  }

  /// {@macro act_enable_service_utility.MEnableService.getElement}
  @override
  EnableServiceElement getElement() => element;
}
