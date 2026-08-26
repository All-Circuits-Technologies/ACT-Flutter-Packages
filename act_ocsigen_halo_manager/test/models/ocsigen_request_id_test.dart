// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_ocsigen.dart';

void main() {
  setUp(FakeGlobalManager.install);

  group("OcsigenRequestId", () {
    test("tells a function and a procedure which share a value apart", () {
      expect(OcsigenRequestId.echo.rawValue, OcsigenRequestId.quitCommunication.rawValue);
      expect(
        OcsigenRequestId.echo.uniqueId,
        isNot(OcsigenRequestId.quitCommunication.uniqueId),
      );
    });

    test("says which requests are answered with a value", () {
      expect(OcsigenRequestId.wiFiConnect.type, HaloRequestType.function);
      expect(OcsigenRequestId.quitCommunication.type, HaloRequestType.procedure);
    });
  });

  group("OcsigenRequestIdHelper", () {
    test("knows every request an OCSIGEN device answers", () {
      final helper = OcsigenRequestIdHelper();

      for (final request in OcsigenRequestId.values) {
        expect(helper.requestIds[request.uniqueId], request);
      }
    });

    test("knows the requests an application adds to them", () {
      final helper = OcsigenRequestIdHelper(
        childRequests: {AppRequestId.readTemperature.uniqueId: AppRequestId.readTemperature},
      );

      expect(
        helper.requestIds[AppRequestId.readTemperature.uniqueId],
        AppRequestId.readTemperature,
      );
      expect(helper.requestIds[OcsigenRequestId.echo.uniqueId], OcsigenRequestId.echo);
    });

    test("answers the request of the application over the OCSIGEN one it replaces", () {
      final helper = OcsigenRequestIdHelper(
        childRequests: {AppRequestId.echo.uniqueId: AppRequestId.echo},
      );

      expect(helper.requestIds[OcsigenRequestId.echo.uniqueId], AppRequestId.echo);
    });

    test("keeps the timeouts the application asked for", () {
      final helper = OcsigenRequestIdHelper(
        overriddenExecutionTimeout: {
          OcsigenRequestId.wiFiConnect.uniqueId: const Duration(minutes: 2),
        },
        defaultRequestTimeout: const Duration(seconds: 5),
      );

      expect(
        helper.overriddenExecutionTimeout[OcsigenRequestId.wiFiConnect.uniqueId],
        const Duration(minutes: 2),
      );
      expect(helper.defaultRequestTimeout, const Duration(seconds: 5));
    });
  });
}
