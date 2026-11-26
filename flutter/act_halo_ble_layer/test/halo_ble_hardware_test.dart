// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/act_halo_ble_layer.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_halo_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeBlePlatform ble;
  late BleManager manager;
  late FakeBleConfigManager config;
  late HaloBleHardware hardware;

  setUpAll(() => ble = FakeBlePlatform.install());

  setUp(() async {
    ble.reset();
    globalManager = FakeGlobalManager.install();

    config = await FakeBleConfigManager.withContent(aBleConf);
    manager = BleManager(confGetter: () => config);
    globalGetIt().registerSingleton<BleManager>(manager);

    hardware = HaloBleHardware(
      bleCompanion: HaloBleCompanion(haloBleConfig: aHaloConfig(), bleManager: manager),
    );
  });

  tearDown(() async {
    FakeAssets.stop();
    await config.disposeLifeCycle();
    await globalManager.reset();
  });

  /// A datum of the device an application reads.
  const aDataId = HaloDataId<int>(id: 1, value: 1);

  group("HaloBleHardware", () {
    test("hands over one layer per part of the protocol", () {
      expect(hardware.attributeHardware, isNotNull);
      expect(hardware.instantDataHardware, isNotNull);
      expect(hardware.recordDataHardware, isNotNull);
      expect(hardware.requestFromDeviceHardware, isNotNull);
      expect(hardware.requestToDeviceHardware, isNotNull);
    });

    test("asks the device for the requests of the application", () async {
      final result = await hardware.requestToDeviceHardware.callOrder(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeHaloRequestId.anOrder),
      );

      // There is no device to write to, which is as far as a request goes without one
      expect(result, HaloErrorType.commError);
    });

    test("carries nothing of the attributes, of the data and of the requests of a device yet", () {
      expect(
        () => hardware.attributeHardware.readAttribute(dataId: aDataId),
        throwsUnimplementedError,
      );
      expect(
        () => hardware.instantDataHardware.subInstantData(dataId: aDataId),
        throwsUnimplementedError,
      );
      expect(
        () => hardware.recordDataHardware.getAllRecordDataKeys(dataId: aDataId),
        throwsUnimplementedError,
      );
    });
  });
}
