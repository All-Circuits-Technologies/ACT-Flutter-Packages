// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_halo_manager/act_halo_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_halo.dart';

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  /// The configuration of an application which reaches its device over one way.
  ({HaloManagerConfig<FakeHwType> config, FakeRequestToDeviceHardware device}) aConfig() {
    final device = FakeRequestToDeviceHardware();

    return (
      config: HaloManagerConfig<FakeHwType>(
        hardwareLayer: FakeHwTypeHelper.only(type: FakeHwType.ble, requestToDevice: device),
        requestIdHelper: FakeRequestIdHelper(),
      ),
      device: device,
    );
  }

  group("AbstractHaloBuilder", () {
    test("depends on the logger manager", () {
      expect(FakeHaloBuilder(FakeHaloManager.new).dependsOn(), [LoggerManager]);
    });
  });

  group("AbstractHaloManager.initLifeCycle", () {
    test("keeps the configuration the application built", () async {
      final (:config, device: _) = aConfig();
      final manager = FakeHaloManager(config: config);

      await manager.initLifeCycle();

      expect(manager.haloManagerConfig, config);
    });

    test("builds the feature which asks the device", () async {
      final (:config, device: _) = aConfig();
      final manager = FakeHaloManager(config: config);

      await manager.initLifeCycle();

      expect(manager.requestToDeviceFeature?.haloManagerConfig, config);
    });

    test("uses the feature the application built when it built one", () async {
      final (:config, device: _) = aConfig();
      final feature = HaloRequestToDeviceFeature<FakeHwType>(haloManagerConfig: config);
      final manager = FakeHaloManager(config: config, ownFeature: feature);

      await manager.initLifeCycle();

      expect(manager.requestToDeviceFeature, feature);
    });

    test("keeps no configuration when the application could not build one", () async {
      final manager = FakeHaloManager();

      await manager.initLifeCycle();

      expect(manager.haloManagerConfig, isNull);
    });

    test("warns when the application could not build a configuration", () async {
      final manager = FakeHaloManager();

      await manager.initLifeCycle();

      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
    });

    test("builds no feature when the application could not build a configuration", () async {
      final manager = FakeHaloManager();

      await manager.initLifeCycle();

      // The feature is never built, and reading it is a mistake of an application which did not
      // check that the manager has a configuration.
      expect(() => manager.requestToDeviceFeature, throwsA(isA<Error>()));
    });
  });

  group("AbstractHaloManager.disposeLifeCycle", () {
    test("closes the way the application reaches its device", () async {
      final (:config, :device) = aConfig();
      final manager = FakeHaloManager(config: config);
      await manager.initLifeCycle();

      await manager.disposeLifeCycle();

      expect(device.isClosed, isTrue);
    });

    test("closes nothing when the application could not build a configuration", () async {
      final manager = FakeHaloManager();
      await manager.initLifeCycle();

      await expectLater(manager.disposeLifeCycle(), completes);
    });
  });
}
