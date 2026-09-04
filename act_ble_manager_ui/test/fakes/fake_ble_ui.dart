// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:reactive_ble_platform_interface/reactive_ble_platform_interface.dart';

/// The asset key of the configuration file the tests serve.
const configKey = "assets/config/default.yaml";

/// The configuration of an application which says nothing of the Bluetooth itself.
const aBleConf = "ble:\n  logs:\n    displayScannedDevice: false";

/// The identifier of the device the tests reach.
const aDeviceId = "a-device";

/// The identifier of the service of the device the tests read.
final aServiceUuid = Uuid.parse("0000180a-0000-1000-8000-00805f9b34fb");

/// The identifier of the characteristic the tests read.
final aCharacteristicUuid = Uuid.parse("00002a29-0000-1000-8000-00805f9b34fb");

/// The configuration which says what the Bluetooth of an application under test logs.
class FakeBleConfigManager extends AbstractConfigManager with MixinBleConf {
  /// Class constructor
  FakeBleConfigManager() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  static Future<FakeBleConfigManager> withContent(String content) async {
    FakeAssets.serve({configKey: content});

    final manager = FakeBleConfigManager();
    await manager.initLifeCycle();

    return manager;
  }
}

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
  /// The status of each permission, the ones which are absent being granted.
  final Map<Permission, PermissionStatus> statuses = {};

  /// The status a permission takes once it has been requested.
  PermissionStatus answerToRequest = PermissionStatus.granted;

  /// Installs this platform as the one the plugin of the permissions reads.
  static FakePermissionsPlatform install() {
    final platform = FakePermissionsPlatform();
    PermissionHandlerPlatform.instance = platform;

    return platform;
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      statuses[permission] ?? PermissionStatus.granted;

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

/// The settings of the device, answered by the test.
sealed class FakeAppSettings {
  /// The channel the plugin of the settings talks over.
  static const channel = MethodChannel("com.spencerccf.app_settings/methods");

  /// The pages of the settings which were asked for, in the order they were.
  static final List<String> opened = [];

  /// What the user does once the settings are open, if the test says that it does anything.
  static Future<void> Function()? onOpened;

  /// Answers on the channel of the settings, and forgets the pages of a previous test.
  static void serve() {
    opened.clear();
    onOpened = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        opened.add(call.method);
        await onOpened?.call();

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
    onOpened = null;
  }
}

/// The Bluetooth of the device, answered by the test.
///
/// This is what the plugin of the Bluetooth reads. The plugin keeps one instance for the whole
/// application, so the same platform serves every test of a file and [reset] is what puts it back
/// to where a test starts from.
class FakeBlePlatform extends ReactiveBlePlatform {
  /// The stream the state of the Bluetooth of the device is told over.
  final StreamController<BleStatus> _statusCtrl = StreamController<BleStatus>.broadcast();

  /// The stream the devices which are scanned are told over.
  final StreamController<ScanResult> _scanCtrl = StreamController<ScanResult>.broadcast();

  /// The stream the connections of the devices are told over.
  final StreamController<ConnectionStateUpdate> _connectionCtrl =
      StreamController<ConnectionStateUpdate>.broadcast();

  /// The stream the values of the characteristics are told over.
  final StreamController<CharacteristicValue> _valueCtrl =
      StreamController<CharacteristicValue>.broadcast();

  /// The number of times the Bluetooth was initialized.
  int initCount = 0;

  /// The number of times the Bluetooth was given up.
  int deinitCount = 0;

  /// The scans which were asked for, in the order they were.
  final List<({ScanMode mode, List<Uuid> services})> scans = [];

  /// The number of scans which are still running.
  int runningScans = 0;

  /// The devices which were connected to, in the order they were.
  final List<String> connected = [];

  /// The devices which were disconnected from, in the order they were.
  final List<String> disconnected = [];

  /// The services the device answers when it is discovered.
  List<DiscoveredService> services = [];

  /// The values which were written, in the order they were.
  final List<({Uuid characteristic, List<int> value, bool withResponse})> written = [];

  /// The characteristics which were subscribed to, in the order they were.
  final List<Uuid> subscribed = [];

  /// The error a read, a write or a subscription raises, if it raises any.
  Exception? error;

  /// The value a read answers.
  List<int> readAnswer = [1, 2, 3];

  /// Installs this platform as the one the plugin of the Bluetooth reads.
  static FakeBlePlatform install() {
    final platform = FakeBlePlatform();
    ReactiveBlePlatform.instance = platform;

    return platform;
  }

  /// Forgets what the tests before this one asked of the device.
  void reset() {
    scans.clear();
    connected.clear();
    disconnected.clear();
    written.clear();
    subscribed.clear();
    services = [];
    error = null;
    runningScans = 0;
  }

  /// Tells the application that the Bluetooth of the device is now [status].
  Future<void> tellStatus(BleStatus status) async {
    _statusCtrl.add(status);

    return Future.delayed(Duration.zero);
  }

  /// Tells the application that a device of the given [id] and [name] was scanned.
  Future<void> tellScanned({String id = aDeviceId, String name = "a device"}) async {
    _scanCtrl.add(
      ScanResult(
        result: Result<DiscoveredDevice, GenericFailure<ScanFailure>?>.success(
          DiscoveredDevice(
            id: id,
            name: name,
            serviceData: const {},
            manufacturerData: Uint8List(0),
            rssi: -50,
            serviceUuids: const [],
          ),
        ),
      ),
    );

    return Future.delayed(Duration.zero);
  }

  /// Tells the application that the device is now [state].
  Future<void> tellConnection(DeviceConnectionState state, {String id = aDeviceId}) async {
    _connectionCtrl.add(ConnectionStateUpdate(deviceId: id, connectionState: state, failure: null));

    return Future.delayed(Duration.zero);
  }

  /// Tells the application that a characteristic answered [value].
  Future<void> tellValue(List<int> value, {String id = aDeviceId}) async {
    _valueCtrl.add(
      CharacteristicValue(
        characteristic: CharacteristicInstance(
          characteristicId: aCharacteristicUuid,
          serviceId: aServiceUuid,
          deviceId: id,
          characteristicInstanceId: "0",
          serviceInstanceId: "0",
        ),
        result: const Result<List<int>, GenericFailure<CharacteristicValueUpdateError>?>.success([]),
      ),
    );

    return Future.delayed(Duration.zero);
  }

  @override
  Stream<BleStatus> get bleStatusStream => _statusCtrl.stream;

  @override
  Stream<ScanResult> get scanStream => _scanCtrl.stream;

  @override
  Stream<ConnectionStateUpdate> get connectionUpdateStream => _connectionCtrl.stream;

  @override
  Stream<CharacteristicValue> get charValueUpdateStream => _valueCtrl.stream;

  @override
  Future<void> initialize() async => initCount++;

  @override
  Future<void> deinitialize() async => deinitCount++;

  @override
  Stream<void> scanForDevices({
    required List<Uuid> withServices,
    required ScanMode scanMode,
    required bool requireLocationServicesEnabled,
  }) {
    scans.add((mode: scanMode, services: withServices));

    return StreamController<void>(
      onListen: () => runningScans++,
      onCancel: () => runningScans--,
    ).stream;
  }

  @override
  Stream<void> connectToDevice(
    String id,
    Map<Uuid, List<Uuid>>? servicesWithCharacteristicsToDiscover,
    Duration? connectionTimeout,
  ) {
    connected.add(id);

    return const Stream<void>.empty();
  }

  @override
  Future<void> disconnectDevice(String deviceId) async => disconnected.add(deviceId);

  @override
  Future<List<DiscoveredService>> discoverServices(String deviceId) async => services;

  @override
  Future<List<DiscoveredService>> getDiscoverServices(String deviceId) async => services;

  @override
  Stream<void> readCharacteristic(CharacteristicInstance characteristic) {
    if (error != null) {
      return Stream<void>.error(error!);
    }

    // The value of a read is answered on the stream of the values, and only once the reading itself
    // was answered: the package listens to that stream when it hears that the reading started.
    return Stream<void>.multi((controller) {
      controller.add(null);

      unawaited(
        Future<void>.delayed(Duration.zero).then((_) {
          _valueCtrl.add(
            CharacteristicValue(
              characteristic: characteristic,
              result: Result<List<int>, GenericFailure<CharacteristicValueUpdateError>?>.success(
                readAnswer,
              ),
            ),
          );

          return controller.close();
        }),
      );
    });
  }

  @override
  Future<WriteCharacteristicInfo> writeCharacteristicWithResponse(
    CharacteristicInstance characteristic,
    List<int> value,
  ) async {
    if (error != null) {
      throw error!;
    }

    written.add((characteristic: characteristic.characteristicId, value: value, withResponse: true));

    return WriteCharacteristicInfo(
      characteristic: characteristic,
      result: const Result<Unit, GenericFailure<WriteCharacteristicFailure>?>.success(Unit()),
    );
  }

  @override
  Future<WriteCharacteristicInfo> writeCharacteristicWithoutResponse(
    CharacteristicInstance characteristic,
    List<int> value,
  ) async {
    if (error != null) {
      throw error!;
    }

    written.add((
      characteristic: characteristic.characteristicId,
      value: value,
      withResponse: false,
    ));

    return WriteCharacteristicInfo(
      characteristic: characteristic,
      result: const Result<Unit, GenericFailure<WriteCharacteristicFailure>?>.success(Unit()),
    );
  }

  @override
  Stream<void> subscribeToNotifications(CharacteristicInstance characteristic) {
    if (error != null) {
      return Stream<void>.error(error!);
    }

    subscribed.add(characteristic.characteristicId);

    return Stream<void>.fromIterable([null]);
  }

  @override
  Future<void> stopSubscribingToNotifications(CharacteristicInstance characteristic) async {}

  @override
  Future<int> requestMtuSize(String deviceId, int? mtu) async => mtu ?? 23;
}

/// The devices of an application under test, answered by the test.
///
/// A real service reaches a device over the Bluetooth, which takes as long as the device answers.
/// This one answers what the test decided and records what it was asked.
class FakeGattService extends BleGattService {
  /// The stream the device which is connected is told over.
  final StreamController<BleDevice?> _lastCtrl = StreamController<BleDevice?>.broadcast();

  /// Whether the connection to a device works.
  bool connectAnswer = true;

  /// The devices the service was asked to connect to, in the order it was.
  final List<String> connected = [];

  /// The number of times the connection told the caller that the device answered.
  int lowLevelCalls = 0;

  /// The device which is connected, if there is one.
  BleDevice? lastDevice;

  /// Class constructor
  FakeGattService({required super.flutterReactiveBle, required super.bleManager});

  /// {@macro act_ble_manager.BleGattService.lastConnectedDevice}
  @override
  BleDevice? get lastConnectedDevice => lastDevice;

  /// {@macro act_ble_manager.BleGattService.lastConnectedDeviceStream}
  @override
  Stream<BleDevice?> get lastConnectedDeviceStream => _lastCtrl.stream;

  @override
  Future<bool> connect(BleDevice device, {VoidCallback? onLowLevelConnect}) async {
    connected.add(device.id);

    if (onLowLevelConnect != null) {
      lowLevelCalls++;
      onLowLevelConnect();
    }

    if (connectAnswer) {
      lastDevice = device;
      _lastCtrl.add(device);
    }

    return connectAnswer;
  }

  @override
  Future<void> disconnect() async {
    lastDevice = null;
    _lastCtrl.add(null);
  }

  @override
  Future<void> disposeLifeCycle() async {
    await _lastCtrl.close();

    return super.disposeLifeCycle();
  }
}

/// The Bluetooth manager of an application whose devices are answered by the test.
class FakeBleManagerWithGatt extends BleManager {
  /// The devices of the application, answered by the test.
  late final FakeGattService gatt;

  /// Class constructor
  FakeBleManagerWithGatt({required super.confGetter}) {
    gatt = FakeGattService(flutterReactiveBle: FlutterReactiveBle(), bleManager: this);
  }

  /// {@macro act_ble_manager.BleManager.bleGattService}
  @override
  BleGattService get bleGattService => gatt;
}

/// A device as the Bluetooth of the device answers it once it is scanned.
DiscoveredDevice aDiscoveredDevice({String id = aDeviceId, String name = "a device"}) =>
    DiscoveredDevice(
      id: id,
      name: name,
      serviceData: const {},
      manufacturerData: Uint8List(0),
      rssi: -50,
      serviceUuids: const [],
    );

/// The service of a device, as the Bluetooth of the device answers it.
DiscoveredService aDiscoveredService({List<Uuid>? characteristics}) => DiscoveredService(
  serviceId: aServiceUuid,
  serviceInstanceId: "0",
  characteristicIds: characteristics ?? [aCharacteristicUuid],
  characteristics: (characteristics ?? [aCharacteristicUuid])
      .map(
        (uuid) => DiscoveredCharacteristic(
          characteristicId: uuid,
          characteristicInstanceId: "0",
          serviceId: aServiceUuid,
          isReadable: true,
          isWritableWithResponse: true,
          isWritableWithoutResponse: true,
          isNotifiable: true,
          isIndicatable: false,
        ),
      )
      .toList(),
);

/// The pages of an application under test.
enum FakeBleRoute with MixinRoute {
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
class FakeBleRouterManager extends AbstractRouterManager<FakeBleRoute> {
  /// {@macro act_router_manager.AbstractRouterManager.getCurrentTopView}
  @override
  FakeBleRoute? getCurrentTopView() => FakeBleRoute.home;

  /// {@macro act_router_manager.AbstractRouterManager.createRoutesHelper}
  @override
  Future<AbstractRoutesHelper<FakeBleRoute>> createRoutesHelper(LogsHelper logsHelper) =>
      throw UnimplementedError("The router of a test pushes no real page");
}

/// The views an application under test displays when something has to be switched on.
class FakeBleViewBuilder extends AbstractViewBuilder {
  /// Whether the user agrees to switch the service on.
  bool userAgrees;

  /// The services the views of which were displayed, in the order they were.
  final List<EnableServiceElement> displayed = [];

  /// Class constructor
  FakeBleViewBuilder({this.userAgrees = true});

  /// {@macro act_contextual_views_manager.AbstractViewBuilder.initProcess}
  @override
  Future<void> initProcess() async {
    for (final element in EnableServiceElement.values) {
      registerAbsViewDisplay(
        context: EnableServiceViewContext(element: element),
        callback: (context, doAction) async {
          displayed.add(element);

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
