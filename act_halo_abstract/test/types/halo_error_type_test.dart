// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloErrorType", () {
    test("can be retried after a transient error", () {
      expect(
        [
          HaloErrorType.serviceBusyError,
          HaloErrorType.commError,
          HaloErrorType.genericError,
        ].map((error) => error.canBeRetried),
        everyElement(isTrue),
      );
    });

    test("can be retried after a success, like the other result statuses", () {
      expect(HaloErrorType.noError.canBeRetried, isTrue);
    });

    test("can't be retried after an error which would happen again", () {
      expect(
        [
          HaloErrorType.formatError,
          HaloErrorType.protocolError,
          HaloErrorType.notImplementedYet,
          HaloErrorType.unknown,
        ].map((error) => error.canBeRetried),
        everyElement(isFalse),
      );
    });

    test("is a success only for noError", () {
      expect(HaloErrorType.noError.isSuccess, isTrue);
      expect(HaloErrorType.noError.isError, isFalse);
    });

    test("is an error for every value except noError", () {
      final errors = HaloErrorType.values.where((error) => error != HaloErrorType.noError);

      expect(errors.map((error) => error.isError), everyElement(isTrue));
      expect(errors.map((error) => error.isSuccess), everyElement(isFalse));
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
