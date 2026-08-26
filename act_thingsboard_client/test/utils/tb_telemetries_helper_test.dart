// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_thingsboard.dart';

/// An attribute of a device, read in the scope the tests use.
TbExtAttributeData _attribute({int ts = 42, String? value}) => TbExtAttributeData(
  data: anAttribute(key: "a key", ts: ts, value: value),
  scope: AttributeScope.SHARED_SCOPE,
);

void main() {
  group("TbTelemetriesHelper.getAttributeValue", () {
    test("reads the value of an attribute as the type which is asked for", () {
      expect(TbTelemetriesHelper.getAttributeValue<int>(_attribute(value: "12")), 12);
      expect(TbTelemetriesHelper.getAttributeValue<double>(_attribute(value: "1.5")), 1.5);
      expect(TbTelemetriesHelper.getAttributeValue<bool>(_attribute(value: "true")), isTrue);
      expect(TbTelemetriesHelper.getAttributeValue<String>(_attribute(value: "a value")), "a value");
    });

    test("answers nothing when the value cannot be read as the type which is asked for", () {
      expect(TbTelemetriesHelper.getAttributeValue<int>(_attribute(value: "a value")), isNull);
    });

    test("answers nothing when the attribute holds no value", () {
      expect(TbTelemetriesHelper.getAttributeValue<int>(_attribute()), isNull);
    });

    test("answers nothing when there is no attribute at all", () {
      expect(TbTelemetriesHelper.getAttributeValue<int>(null), isNull);
    });

    test("raises when the type which is asked for is one it cannot read", () {
      expect(
        () => TbTelemetriesHelper.getAttributeValue<DateTime>(_attribute(value: "a value")),
        throwsA(isA<ActUnsupportedTypeError<DateTime>>()),
      );
    });
  });

  group("TbTelemetriesHelper.getTsValue", () {
    test("reads the value of a time series as the type which is asked for", () {
      expect(TbTelemetriesHelper.getTsValue<int>(const TbTsValue(ts: 42, value: "12")), 12);
      expect(TbTelemetriesHelper.getTsValue<double>(const TbTsValue(ts: 42, value: "1.5")), 1.5);
      expect(TbTelemetriesHelper.getTsValue<bool>(const TbTsValue(ts: 42, value: "false")), isFalse);
    });

    test("answers nothing when the value cannot be read as the type which is asked for", () {
      expect(TbTelemetriesHelper.getTsValue<int>(const TbTsValue(ts: 42, value: "a value")), isNull);
    });

    test("answers nothing when there is no value at all", () {
      expect(TbTelemetriesHelper.getTsValue<int>(null), isNull);
    });
  });

  group("TbTelemetriesHelper.getTsLastUtcReceptionTime", () {
    test("reads the timestamp of a time series as a date in UTC", () {
      final time = TbTelemetriesHelper.getTsLastUtcReceptionTime(
        const TbTsValue(ts: 1700000000000, value: "a value"),
      );

      expect(time, DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
      expect(time?.isUtc, isTrue);
    });

    test("answers nothing when there is no value at all", () {
      expect(TbTelemetriesHelper.getTsLastUtcReceptionTime(null), isNull);
    });
  });

  group("TbTelemetriesHelper.getAttributeLastUtcReceptionTime", () {
    test("reads the moment an attribute was updated as a date in UTC", () {
      final time = TbTelemetriesHelper.getAttributeLastUtcReceptionTime(
        _attribute(ts: 1700000000000, value: "a value"),
      );

      expect(time, DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
      expect(time?.isUtc, isTrue);
    });

    test("answers nothing when there is no attribute at all", () {
      expect(TbTelemetriesHelper.getAttributeLastUtcReceptionTime(null), isNull);
    });
  });
}
