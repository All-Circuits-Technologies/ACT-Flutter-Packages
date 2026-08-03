// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_ocsigen.dart';

void main() {
  setUp(FakeGlobalManager.install);

  /// The manager of an application whose device answers [result].
  Future<FakeOcsigenManager> aManager({HaloPayloadPacket? result}) async {
    final manager = FakeOcsigenManager(device: FakeOcsigenDevice(result: result));
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("AbstractOcsigenHaloManager", () {
    test("speaks to its device through the requests OCSIGEN devices answer", () async {
      final packet = HaloPayloadPacket()..addString("a serial number");
      final manager = await aManager(result: packet);

      final serialNumber = await manager.ocsigenRequestToDevice.getSerialNumber(
        hardwareType: FakeHwType.ble,
      );

      expect(serialNumber, "a serial number");
    });

    test("builds the feature which knows the OCSIGEN requests", () async {
      final manager = await aManager();

      expect(manager.requestToDeviceFeature, isA<OcsigenRequestToDeviceFeature<FakeHwType>>());
      expect(manager.ocsigenRequestToDevice, manager.requestToDeviceFeature);
    });
  });

  group("AbstractOcsigenHaloBuilder", () {
    test("builds the manager of an application", () async {
      final device = FakeOcsigenDevice();

      final builder = FakeOcsigenBuilder(() => FakeOcsigenManager(device: device));

      expect(builder.factory(), isA<FakeOcsigenManager>());
    });
  });
}
