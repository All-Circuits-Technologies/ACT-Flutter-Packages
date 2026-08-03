// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ViewDisplayResult", () {
    test("carries no value of its own when the view answered none", () {
      const result = ViewDisplayResult<String>(status: ViewDisplayStatus.ok);

      expect(result.customResult, isNull);
    });

    test("is an error when the view could not be displayed", () {
      const result = ViewDisplayResult<String>.error();

      expect(result.status, ViewDisplayStatus.error);
      expect(result.customResult, isNull);
    });

    test("is the same result as another one which says the same", () {
      expect(
        const ViewDisplayResult<String>(status: ViewDisplayStatus.yes, customResult: "a name"),
        const ViewDisplayResult<String>(status: ViewDisplayStatus.yes, customResult: "a name"),
      );
    });

    test("is another result as soon as the status differs", () {
      expect(
        const ViewDisplayResult<String>(status: ViewDisplayStatus.yes),
        isNot(const ViewDisplayResult<String>(status: ViewDisplayStatus.no)),
      );
    });
  });

  group("ViewDisplayResult.toCast", () {
    test("gives back the value of the view as the type the caller asked for", () {
      const result = ViewDisplayResult<Object>(
        status: ViewDisplayStatus.ok,
        customResult: "a name",
      );

      final cast = result.toCast<String>();

      expect(cast.status, ViewDisplayStatus.ok);
      expect(cast.customResult, "a name");
    });

    test("gives back nothing for a view which answered no value", () {
      const result = ViewDisplayResult<Object>(status: ViewDisplayStatus.ok);

      expect(result.toCast<String>().customResult, isNull);
    });

    test("refuses a value which is not of the type the caller asked for", () {
      const result = ViewDisplayResult<Object>(status: ViewDisplayStatus.ok, customResult: 42);

      expect(result.toCast<String>, throwsA(isA<TypeError>()));
    });
  });

  group("ViewDisplayStatus", () {
    test("says which answers of a view are the ones which go further", () {
      expect(
        ViewDisplayStatus.values.where((status) => status.isPositiveResult),
        [ViewDisplayStatus.ok, ViewDisplayStatus.yes],
      );
    });
  });
}
