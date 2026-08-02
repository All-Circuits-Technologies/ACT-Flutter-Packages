// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloErrorType", () {
    test("says it makes sense to retry after a transient error", () {
      expect(
        [
          HaloErrorType.serviceBusyError,
          HaloErrorType.commError,
          HaloErrorType.genericError,
        ].map((error) => error.isMakingSensToRetry),
        everyElement(isTrue),
      );
    });

    test("says it makes no sense to retry after an error which would happen again", () {
      expect(
        [
          HaloErrorType.noError,
          HaloErrorType.formatError,
          HaloErrorType.protocolError,
          HaloErrorType.notImplementedYet,
          HaloErrorType.unknown,
        ].map((error) => error.isMakingSensToRetry),
        everyElement(isFalse),
      );
    });

    test("gives a distinct raw value to each error", () {
      final rawValues = HaloErrorType.values.map((error) => error.rawValue).toSet();

      expect(rawValues.length, HaloErrorType.values.length);
    });
  });

  group("HaloErrorType.parseValue", () {
    test("returns the error which carries the raw value given", () {
      expect(HaloErrorType.parseValue(0xFE), HaloErrorType.commError);
    });

    test("returns every error from its own raw value", () {
      for (final error in HaloErrorType.values) {
        expect(HaloErrorType.parseValue(error.rawValue), error);
      }
    });

    test("returns unknown when no error carries the raw value given", () {
      expect(HaloErrorType.parseValue(0x42), HaloErrorType.unknown);
    });
  });
}
