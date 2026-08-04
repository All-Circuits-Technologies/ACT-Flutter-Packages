// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/act_thingsboard_client_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

import '../../fakes/fake_tb_telemetries_ui.dart';

/// An attribute of a device, read in the scope the tests use.
TbExtAttributeData _anAttribute({int ts = 42, String? value = "20.5"}) => TbExtAttributeData(
  data: AttributeData(key: "temp", lastUpdateTs: ts, value: value),
  scope: AttributeScope.SHARED_SCOPE,
);

void main() {
  group("TbTelemetriesUiState.init", () {
    test("shows a page which knows nothing yet as loading", () {
      final state = TbTelemetriesUiState.init();

      expect(state.device, isNull);
      expect(state.telemetryLoading, isTrue);
      expect(state.genericError, TbTelemetriesUiError.noError);
      expect(state.tsValues, isEmpty);
      expect(state.attributesValues, isEmpty);
    });
  });

  group("MixinTbTelemetriesUiState.canRetryRequest", () {
    test("says that a page which failed on the server can be tried again", () {
      final state = TbTelemetriesUiState.init().copyWithErrorUiState(
        genericError: TbTelemetriesUiError.serverError,
      );

      expect(state.canRetryRequest, isTrue);
    });

    test("says that a page which found no device cannot be tried again", () {
      final state = TbTelemetriesUiState.init().copyWithErrorUiState(
        genericError: TbTelemetriesUiError.unknownDevice,
      );

      expect(state.canRetryRequest, isFalse);
    });
  });

  group("MixinTbTelemetriesUiState.copyWithErrorUiState", () {
    test("stops the loading of the page", () {
      final state = TbTelemetriesUiState.init().copyWithErrorUiState(
        genericError: TbTelemetriesUiError.noInternetAtStart,
      );

      expect(state.telemetryLoading, isFalse);
      expect(state.genericError, TbTelemetriesUiError.noInternetAtStart);
    });
  });

  group("MixinTbTelemetriesUiState.copyWithTelemetryInit", () {
    test("holds the device and the values which were already received", () {
      final state = TbTelemetriesUiState.init().copyWithTelemetryInit(
        device: aDeviceInfo(name: "a named device"),
        tsValues: const {"temp": TbTsValue(ts: 42, value: "20.5")},
        attributesValues: {"temp": _anAttribute()},
      );

      expect(state.device?.name, "a named device");
      expect(state.tsValues.keys, ["temp"]);
      expect(state.attributesValues.keys, ["temp"]);
      expect(state.genericError, TbTelemetriesUiError.noError);
    });

    test("leaves the page loading while nothing was received", () {
      final state = TbTelemetriesUiState.init().copyWithTelemetryInit(device: aDeviceInfo());

      expect(state.telemetryLoading, isTrue);
    });
  });

  group("MixinTbTelemetriesUiState.copyWithNewValuesUiState", () {
    test("stops the loading once a value is received", () {
      final state = TbTelemetriesUiState.init().copyWithNewValuesUiState(
        tsValues: const {"temp": TbTsValue(ts: 42, value: "20.5")},
      );

      expect(state.telemetryLoading, isFalse);
    });

    test("leaves the page loading when nothing was received", () {
      final state = TbTelemetriesUiState.init().copyWithNewValuesUiState(tsValues: const {});

      expect(state.telemetryLoading, isTrue);
    });

    test("keeps the values it already holds", () {
      final state = TbTelemetriesUiState.init()
          .copyWithNewValuesUiState(tsValues: const {"temp": TbTsValue(ts: 42, value: "20.5")})
          .copyWithNewValuesUiState(tsValues: const {"hum": TbTsValue(ts: 43, value: "60")});

      expect(state.tsValues.keys, ["temp", "hum"]);
    });

    test("takes the new value of a key it already holds", () {
      final state = TbTelemetriesUiState.init()
          .copyWithNewValuesUiState(tsValues: const {"temp": TbTsValue(ts: 42, value: "20.5")})
          .copyWithNewValuesUiState(tsValues: const {"temp": TbTsValue(ts: 43, value: "21.0")});

      expect(state.tsValues["temp"], const TbTsValue(ts: 43, value: "21.0"));
    });

    test("keeps the attributes it already holds", () {
      final state = TbTelemetriesUiState.init()
          .copyWithNewValuesUiState(attributesValues: {"temp": _anAttribute()})
          .copyWithNewValuesUiState(tsValues: const {"hum": TbTsValue(ts: 43, value: "60")});

      expect(state.attributesValues.keys, ["temp"]);
    });
  });

  group("MixinTbTelemetriesUiState.getTsValue", () {
    test("reads the value of a time series as the type which is asked for", () {
      final state = TbTelemetriesUiState.init().copyWithNewValuesUiState(
        tsValues: const {"temp": TbTsValue(ts: 42, value: "20.5")},
      );

      expect(state.getTsValue<double>(FakeTelemetryKeys.temperature), 20.5);
    });

    test("answers nothing of a key which was never received", () {
      final state = TbTelemetriesUiState.init();

      expect(state.getTsValue<double>(FakeTelemetryKeys.temperature), isNull);
    });

    test("answers the moment the value was received", () {
      final state = TbTelemetriesUiState.init().copyWithNewValuesUiState(
        tsValues: const {"temp": TbTsValue(ts: 1700000000000, value: "20.5")},
      );

      expect(
        state.getTsLastUtcReceptionTime(FakeTelemetryKeys.temperature),
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
    });
  });

  group("MixinTbTelemetriesUiState.getAttributeValue", () {
    test("reads the value of an attribute as the type which is asked for", () {
      final state = TbTelemetriesUiState.init().copyWithNewValuesUiState(
        attributesValues: {"temp": _anAttribute()},
      );

      expect(state.getAttributeValue<double>(FakeTelemetryKeys.temperature), 20.5);
    });

    test("answers nothing of an attribute which holds no value", () {
      final state = TbTelemetriesUiState.init().copyWithNewValuesUiState(
        attributesValues: {"temp": _anAttribute(value: null)},
      );

      expect(state.getAttributeValue<double>(FakeTelemetryKeys.temperature), isNull);
    });

    test("answers the moment the attribute was updated", () {
      final state = TbTelemetriesUiState.init().copyWithNewValuesUiState(
        attributesValues: {"temp": _anAttribute(ts: 1700000000000)},
      );

      expect(
        state.getAttributeLastUtcReceptionTime(FakeTelemetryKeys.temperature),
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
    });
  });

  group("TbTelemetriesUiError", () {
    test("says which of its values are errors", () {
      expect(TbTelemetriesUiError.noError.isError, isFalse);
      expect(TbTelemetriesUiError.noInternetAtStart.isError, isTrue);
      expect(TbTelemetriesUiError.unknownDevice.isError, isTrue);
      expect(TbTelemetriesUiError.serverError.isError, isTrue);
    });
  });
}
