// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_manager/act_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_halo.dart';

void main() {
  setUp(FakeGlobalManager.install);

  /// The configuration of an application which reaches its device over one way.
  HaloManagerConfig<FakeHwType> aConfig({int? retryNbBeforeReturningError}) => HaloManagerConfig(
    hardwareLayer: FakeHwTypeHelper.only(
      type: FakeHwType.ble,
      requestToDevice: FakeRequestToDeviceHardware(),
    ),
    requestIdHelper: FakeRequestIdHelper(),
    retryNbBeforeReturningError:
        retryNbBeforeReturningError ?? HaloManagerConfig.defaultRetryNumber,
  );

  group("HaloManagerConfig", () {
    test("asks the device twice before it gives up, unless the application says otherwise", () {
      expect(aConfig().retryNbBeforeReturningError, 2);
    });

    test("asks the device as many times as the application says", () {
      expect(aConfig(retryNbBeforeReturningError: 5).retryNbBeforeReturningError, 5);
    });

    test("gives every configuration a lock of its own", () {
      expect(aConfig().actionMutex, isNot(same(aConfig().actionMutex)));
    });
  });
}
