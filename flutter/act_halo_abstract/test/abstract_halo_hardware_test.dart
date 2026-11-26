// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_hardware.dart';

void main() {
  group("AbstractHaloHardware.close", () {
    test("closes every component of the layer", () async {
      final hardware = FakeHaloHardware();

      await hardware.close();

      expect(hardware.fakeAttributes.isClosed, isTrue);
      expect(hardware.fakeInstantData.isClosed, isTrue);
      expect(hardware.fakeRecordData.isClosed, isTrue);
      expect(hardware.fakeRequestsFromDevice.isClosed, isTrue);
      expect(hardware.fakeRequestsToDevice.isClosed, isTrue);
    });
  });

  group("AbstractHaloHardware", () {
    test("is a component of a hardware layer itself", () {
      expect(FakeHaloHardware(), isA<AbstractHaloComponentHardware>());
    });
  });
}
