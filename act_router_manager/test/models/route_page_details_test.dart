// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_router_manager/src/models/page_arguments.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_routes.dart';

/// The widget a page of the test displays.
const _aWidget = SizedBox();

void main() {
  group("RoutePageDetails", () {
    test("overrides neither the transition nor the orientation unless it is told to", () {
      const details = RoutePageDetails(widget: _aWidget);

      expect(details.transition, isNull);
      expect(details.screenOrientation, isNull);
    });

    test("equals other details which carry the same widget and the same overrides", () {
      expect(
        const RoutePageDetails(widget: _aWidget, transition: RouteTransition.fade),
        const RoutePageDetails(widget: _aWidget, transition: RouteTransition.fade),
      );
    });

    test("differs from details which carry another transition", () {
      expect(
        const RoutePageDetails(widget: _aWidget, transition: RouteTransition.fade),
        isNot(const RoutePageDetails(widget: _aWidget, transition: RouteTransition.slide)),
      );
    });
  });

  group("PageArguments", () {
    test("equals other arguments which carry the same route and the same orientation", () {
      expect(
        const PageArguments(
          route: FakeRoute.home,
          screenOrientation: ScreenOrientationOption.mayRotate,
        ),
        const PageArguments(
          route: FakeRoute.home,
          screenOrientation: ScreenOrientationOption.mayRotate,
        ),
      );
    });

    test("differs from arguments which carry another orientation", () {
      expect(
        const PageArguments(
          route: FakeRoute.home,
          screenOrientation: ScreenOrientationOption.mayRotate,
        ),
        isNot(
          const PageArguments(
            route: FakeRoute.home,
            screenOrientation: ScreenOrientationOption.portrayOnly,
          ),
        ),
      );
    });
  });

  group("ScreenOrientationOption", () {
    test("locks the application in portrait", () {
      expect(ScreenOrientationOption.portrayOnly.orientations, [DeviceOrientation.portraitUp]);
    });

    test("locks the application in landscape, in both directions", () {
      expect(ScreenOrientationOption.landscapeOnly.orientations, [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });

    test("lets the application rotate between portrait and landscape", () {
      expect(
        ScreenOrientationOption.mayRotate.orientations,
        containsAll([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
    });
  });
}
