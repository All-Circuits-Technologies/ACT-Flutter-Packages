// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/act_halo_ble_layer.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:reactive_ble_platform_interface/reactive_ble_platform_interface.dart';

/// The asset key of the configuration file the tests serve.
const configKey = "assets/config/default.yaml";

/// The configuration of an application which says nothing of the Bluetooth itself.
const aBleConf = "ble:\n  logs:\n    displayScannedDevice: false";

/// The identifier of the device the tests reach.
const aDeviceId = "a-device";

/// The largest payload the device of the tests takes in one packet.
const aMaxCharacteristicByteSize = 20;

/// The identifier of the service of the device the HALO characteristics are carried by.
final aServiceUuid = Uuid.parse("0000180a-0000-1000-8000-00805f9b34fb");

/// The identifiers of the thirteen HALO characteristics, in the order the protocol names them.
final haloCharUuids = List<String>.generate(
  13,
  (index) => "0000ff${(index + 1).toRadixString(16).padLeft(2, '0')}-0000-1000-8000-00805f9b34fb",
);

/// The requests an application under test asks the device for.
enum FakeHaloRequestId with MixinHaloType, MixinHaloRequestId {
  /// A request which answers a value.
  aFunction(rawValue: 0x01, type: HaloRequestType.function),

  /// A request which only answers whether it went through.
  aProcedure(rawValue: 0x02, type: HaloRequestType.procedure),

  /// A request the device answers nothing about.
  anOrder(rawValue: 0x03, type: HaloRequestType.order);

  /// The value the device knows this request under.
  @override
  final int rawValue;

  /// What the device answers about this request.
  @override
  final HaloRequestType type;

  /// Enum constructor
  const FakeHaloRequestId({required this.rawValue, required this.type});
}

/// The configuration of the HALO characteristics of a device under test.
HaloBleConfig aHaloConfig({int maxCharacteristicByteSize = aMaxCharacteristicByteSize}) =>
    HaloBleConfig(
      charAAttrNotifyUuid: UuidValue.fromString(haloCharUuids[0]),
      charBAttrCmdUuid: UuidValue.fromString(haloCharUuids[1]),
      charCAttrTmpUuid: UuidValue.fromString(haloCharUuids[2]),
      charDInstNotifyUuid: UuidValue.fromString(haloCharUuids[3]),
      charEInstCmdUuid: UuidValue.fromString(haloCharUuids[4]),
      charFInstTmpUuid: UuidValue.fromString(haloCharUuids[5]),
      charGRecordNotifyUuid: UuidValue.fromString(haloCharUuids[6]),
      charHRecordCmdUuid: UuidValue.fromString(haloCharUuids[7]),
      charIRecordTmpUuid: UuidValue.fromString(haloCharUuids[8]),
      charJRequestToDeviceCmdUuid: UuidValue.fromString(haloCharUuids[9]),
      charKRequestToDeviceTmpUuid: UuidValue.fromString(haloCharUuids[10]),
      charLRequestToClientCmdUuid: UuidValue.fromString(haloCharUuids[11]),
      charMRequestToClientTmpUuid: UuidValue.fromString(haloCharUuids[12]),
      maxCharacteristicByteSize: maxCharacteristicByteSize,
    );

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
}

/// The life cycle of an application under test.
class FakeAppLifeCycleManager extends AppLifeCycleManager {
  final StreamController<AppLifecycleState?> _ctrl =
      StreamController<AppLifecycleState?>.broadcast();

  /// {@macro act_app_life_cycle_manager.AppLifeCycleManager.lifeCycleStream}
  @override
  Stream<AppLifecycleState?> get lifeCycleStream => _ctrl.stream;

  /// {@macro act_app_life_cycle_manager.AppLifeCycleManager.waitForegroundApp}
  @override
  Future<void> waitForegroundApp({required Future<bool> Function() leaveTheApp}) async {
    _ctrl.add(AppLifecycleState.paused);
    await leaveTheApp();
    _ctrl.add(AppLifecycleState.resumed);
  }

  /// Stops telling the application about its life cycle.
  Future<void> close() => _ctrl.close();
}

/// The permissions of the device, which the tests grant.
class FakePermissionsPlatform extends PermissionHandlerPlatform {
  /// Installs this platform as the one the plugin of the permissions reads.
  static FakePermissionsPlatform install() {
    final platform = FakePermissionsPlatform();
    PermissionHandlerPlatform.instance = platform;

    return platform;
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      PermissionStatus.granted;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async => {for (final permission in permissions) permission: PermissionStatus.granted};

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async => false;

  @override
  Future<bool> openAppSettings() async => true;
}

/// The Bluetooth of the device, answered by the test.
///
/// This is what the plugin of the Bluetooth reads. The plugin keeps one instance for the whole
/// application, so the same platform serves every test of a file and [reset] is what puts it back
/// to where a test starts from.
class FakeBlePlatform extends ReactiveBlePlatform {
  final StreamController<BleStatus> _statusCtrl = StreamController<BleStatus>.broadcast();

  final StreamController<ConnectionStateUpdate> _connectionCtrl =
      StreamController<ConnectionStateUpdate>.broadcast();

  final StreamController<CharacteristicValue> _valueCtrl =
      StreamController<CharacteristicValue>.broadcast();

  /// The services the device answers when it is discovered.
  List<DiscoveredService> services = [];

  /// The values which were written, in the order they were.
  final List<({Uuid characteristic, List<int> value, bool withResponse})> written = [];

  /// The characteristics which were subscribed to, in the order they were.
  final List<Uuid> subscribed = [];

  /// The characteristics which are no longer subscribed to, in the order they were given up.
  final List<Uuid> unsubscribed = [];

  /// The error a write or a subscription raises, if it raises any.
  Exception? error;

  /// Installs this platform as the one the plugin of the Bluetooth reads.
  static FakeBlePlatform install() {
    final platform = FakeBlePlatform();
    ReactiveBlePlatform.instance = platform;

    return platform;
  }

  /// Forgets what the tests before this one asked of the device.
  void reset() {
    written.clear();
    subscribed.clear();
    unsubscribed.clear();
    services = [aDiscoveredService()];
    error = null;
  }

  /// Tells the application that the Bluetooth of the device is now [status].
  Future<void> tellStatus(BleStatus status) async {
    _statusCtrl.add(status);

    return pumpHalo();
  }

  /// Tells the application that the device is now [state].
  Future<void> tellConnection(DeviceConnectionState state, {String id = aDeviceId}) async {
    _connectionCtrl.add(ConnectionStateUpdate(deviceId: id, connectionState: state, failure: null));

    return pumpHalo();
  }

  /// Tells the application that the characteristic [uuid] of the device notified [value].
  Future<void> tellNotification(String uuid, List<int> value, {String id = aDeviceId}) async {
    _valueCtrl.add(
      CharacteristicValue(
        characteristic: CharacteristicInstance(
          characteristicId: Uuid.parse(uuid),
          serviceId: aServiceUuid,
          deviceId: id,
          characteristicInstanceId: "0",
          serviceInstanceId: "0",
        ),
        result: Result<List<int>, GenericFailure<CharacteristicValueUpdateError>?>.success(value),
      ),
    );

    return pumpHalo();
  }

  @override
  Stream<BleStatus> get bleStatusStream => _statusCtrl.stream;

  /// Nothing is ever scanned: the tests reach a device they hold already.
  @override
  Stream<ScanResult> get scanStream => const Stream<ScanResult>.empty();

  @override
  Stream<ConnectionStateUpdate> get connectionUpdateStream => _connectionCtrl.stream;

  @override
  Stream<CharacteristicValue> get charValueUpdateStream => _valueCtrl.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> deinitialize() async {}

  @override
  Stream<void> scanForDevices({
    required List<Uuid> withServices,
    required ScanMode scanMode,
    required bool requireLocationServicesEnabled,
  }) => const Stream<void>.empty();

  @override
  Stream<void> connectToDevice(
    String id,
    Map<Uuid, List<Uuid>>? servicesWithCharacteristicsToDiscover,
    Duration? connectionTimeout,
  ) => const Stream<void>.empty();

  @override
  Future<void> disconnectDevice(String deviceId) async {}

  @override
  Future<List<DiscoveredService>> discoverServices(String deviceId) async => services;

  @override
  Future<List<DiscoveredService>> getDiscoverServices(String deviceId) async => services;

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
  Future<void> stopSubscribingToNotifications(CharacteristicInstance characteristic) async =>
      unsubscribed.add(characteristic.characteristicId);

  @override
  Future<int> requestMtuSize(String deviceId, int? mtu) async => mtu ?? 23;
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

/// The service of a device which carries the thirteen HALO characteristics.
DiscoveredService aDiscoveredService() {
  final characteristics = haloCharUuids.map(Uuid.parse).toList();

  return DiscoveredService(
    serviceId: aServiceUuid,
    serviceInstanceId: "0",
    characteristicIds: characteristics,
    characteristics: characteristics
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
}

/// The device of the application whose HALO characteristics were discovered.
///
/// The device is left disconnected when [connected] says so.
Future<BleDevice> aHaloDevice({bool connected = true}) async {
  final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
  device.updateServicesAndChar(await FlutterReactiveBle().getDiscoveredServices(aDeviceId));

  if (connected) {
    await device.setConnectionStream(
      Stream.value(
        const ConnectionStateUpdate(
          deviceId: aDeviceId,
          connectionState: DeviceConnectionState.connected,
          failure: null,
        ),
      ),
    );
    await pumpHalo();
  }

  return device;
}

/// The companion of a device whose writings and readings are answered by the test.
///
/// The real companion reaches a device over the Bluetooth; this one records what it was asked and
/// answers what the test lined up.
class FakeHaloCompanion extends HaloBleCompanion {
  /// What was written, in the order it was, and whether an answer was waited for.
  final List<({String characteristic, Uint8List data, bool waited})> writes = [];

  /// The answers the device gives, one per writing which waits for one, in order.
  ///
  /// Once the list is empty, every writing is acknowledged for [ackFor].
  final List<(HaloErrorType, Uint8List?)> answers = [];

  /// The request the acknowledgments of the device are for.
  MixinHaloRequestId ackFor;

  /// What the device answers to a writing which waits for nothing.
  HaloErrorType writeAnswer;

  /// Class constructor
  FakeHaloCompanion({
    required super.haloBleConfig,
    required super.bleManager,
    this.ackFor = FakeHaloRequestId.aFunction,
    this.writeAnswer = HaloErrorType.noError,
  });

  /// Records what was written and answers what the test decided.
  @override
  Future<HaloErrorType> onlyWrite({
    required AbstractHaloCharacteristic toWriteInto,
    required Uint8List dataToWrite,
  }) async {
    writes.add((characteristic: toWriteInto.uuid, data: dataToWrite, waited: false));

    return writeAnswer;
  }

  /// Records what was written and answers what the test lined up for the device.
  @override
  Future<(HaloErrorType, Uint8List?)> writeAndWaitNotifResult({
    required AbstractHaloCharacteristic toWriteInto,
    required Uint8List dataToWrite,
    required MixCharNotification toWaitNotifyFrom,
    Duration? timeout,
  }) async {
    writes.add((characteristic: toWriteInto.uuid, data: dataToWrite, waited: true));

    if (answers.isEmpty) {
      return (HaloErrorType.noError, anAck(requestId: ackFor));
    }

    return answers.removeAt(0);
  }

  /// The writings which went into the characteristic [uuid].
  Iterable<Uint8List> writesInto(String uuid) =>
      writes.where((write) => write.characteristic == uuid).map((write) => write.data);
}

/// The answer of a device to a request which went through.
Uint8List anAck({
  required MixinHaloRequestId requestId,
  HaloCmdId cmdId = HaloCmdId.ack,
  HaloErrorType error = HaloErrorType.noError,
  int nbValues = 0,
}) => Uint8List.fromList([cmdId.rawValue, error.rawValue, nbValues, requestId.rawValue]);

/// The payload of a device which holds the strings [values].
HaloPayloadPacket aPayload(List<String> values) {
  final payload = HaloPayloadPacket();
  payload.addStringList(values);

  return payload;
}

/// The packets a device answers to hand over the payload of [values].
List<Uint8List> aPayloadFromDevice(List<String> values, {int maxPacketSize = -1}) =>
    aPayload(values).getDataToSend(maxPacketSize: maxPacketSize);

/// Lets the streams of the packages carry what was just told on them.
Future<void> pumpHalo() => Future.delayed(Duration.zero);
