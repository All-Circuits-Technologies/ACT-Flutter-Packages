// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_request_ids.dart';

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("AbstractHaloRequestIdHelper", () {
    test("keeps the requests of the application, keyed by their unique id", () {
      final helper = _RequestIdHelper({
        FakeRequestId.readTemperature.uniqueId: FakeRequestId.readTemperature,
      });

      expect(
        helper.requestIds[FakeRequestId.readTemperature.uniqueId],
        FakeRequestId.readTemperature,
      );
    });

    test("overrides no execution timeout unless the application asks for it", () {
      final helper = _RequestIdHelper(const {});

      expect(helper.overriddenExecutionTimeout, isEmpty);
      expect(helper.defaultRequestTimeout, isNull);
    });
  });

  group("AbstractHaloRequestIdHelper.mergeRequestElement", () {
    test("returns the requests of both maps", () {
      final merged = AbstractHaloRequestIdHelper.mergeRequestElement(
        elementRequests: {FakeRequestId.readTemperature.uniqueId: FakeRequestId.readTemperature},
        toOverwriteWith: {FakeRequestId.reboot.uniqueId: FakeRequestId.reboot},
      );

      expect(merged.length, 2);
    });

    test("keeps the request of the map which overwrites when a unique id is in both", () {
      final merged = AbstractHaloRequestIdHelper.mergeRequestElement(
        elementRequests: {FakeRequestId.readTemperature.uniqueId: FakeRequestId.readTemperature},
        toOverwriteWith: {
          OtherFakeRequestId.readTemperature.uniqueId: OtherFakeRequestId.readTemperature,
        },
      );

      expect(
        merged[OtherFakeRequestId.readTemperature.uniqueId],
        OtherFakeRequestId.readTemperature,
      );
    });

    test("warns about the request it loses when a unique id is in both maps", () {
      AbstractHaloRequestIdHelper.mergeRequestElement(
        elementRequests: {FakeRequestId.readTemperature.uniqueId: FakeRequestId.readTemperature},
        toOverwriteWith: {
          OtherFakeRequestId.readTemperature.uniqueId: OtherFakeRequestId.readTemperature,
        },
      );

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("warns about nothing when the maps have no unique id in common", () {
      AbstractHaloRequestIdHelper.mergeRequestElement(
        elementRequests: {FakeRequestId.readTemperature.uniqueId: FakeRequestId.readTemperature},
        toOverwriteWith: {FakeRequestId.reboot.uniqueId: FakeRequestId.reboot},
      );

      expect(logger.recordsAtLevel(LogsLevel.warn), isEmpty);
    });

    test("leaves the maps it merges untouched", () {
      final elementRequests = {
        FakeRequestId.readTemperature.uniqueId: FakeRequestId.readTemperature,
      };

      AbstractHaloRequestIdHelper.mergeRequestElement(
        elementRequests: elementRequests,
        toOverwriteWith: {FakeRequestId.reboot.uniqueId: FakeRequestId.reboot},
      );

      expect(elementRequests.length, 1);
    });
  });
}

/// The requests of the application under test.
class _RequestIdHelper extends AbstractHaloRequestIdHelper {
  /// Class constructor
  _RequestIdHelper(Map<int, MixinHaloRequestId> requestIds) : super(requestIds: requestIds);
}
