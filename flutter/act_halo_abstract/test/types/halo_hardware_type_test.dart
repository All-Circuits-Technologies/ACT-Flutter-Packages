// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_hardware.dart';

/// The hardware layers an application can talk to its device through.
enum _Transport { ble, serial }

void main() {
  group("HaloHardwareType", () {
    test("equals another type which carries the same transport and the same layer", () {
      final hardware = FakeHaloHardware();

      expect(
        HaloHardwareType(type: _Transport.ble, haloHardware: hardware),
        HaloHardwareType(type: _Transport.ble, haloHardware: hardware),
      );
    });

    test("differs from a type which carries another transport", () {
      final hardware = FakeHaloHardware();

      expect(
        HaloHardwareType(type: _Transport.ble, haloHardware: hardware),
        isNot(HaloHardwareType(type: _Transport.serial, haloHardware: hardware)),
      );
    });
  });

  group("AbstractHaloHwTypeHelper.close", () {
    test("closes the layer of every transport", () async {
      final ble = FakeHaloHardware();
      final serial = FakeHaloHardware();
      final helper = _HwTypeHelper({
        _Transport.ble: HaloHardwareType(type: _Transport.ble, haloHardware: ble),
        _Transport.serial: HaloHardwareType(type: _Transport.serial, haloHardware: serial),
      });

      await helper.close();

      expect(ble.fakeAttributes.isClosed, isTrue);
      expect(serial.fakeAttributes.isClosed, isTrue);
    });

    test("accepts to close a helper which knows no transport", () async {
      await expectLater(_HwTypeHelper(const {}).close(), completes);
    });
  });
}

/// The hardware layers of the application under test.
class _HwTypeHelper extends AbstractHaloHwTypeHelper<_Transport> {
  /// Class constructor
  _HwTypeHelper(Map<_Transport, HaloHardwareType<_Transport>> hardwareServices)
    : super(hardwareServices: hardwareServices);
}
