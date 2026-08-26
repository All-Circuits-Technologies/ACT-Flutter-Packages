// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_halo_ble.dart';

void main() {
  group("HaloBleConfig", () {
    test("knows the thirteen characteristics of the protocol", () {
      final config = aHaloConfig();

      expect(config.allHaloCharacteristics.length, 13);
      expect(
        config.allHaloCharacteristics.map((char) => char.uuid),
        haloCharUuids,
      );
    });

    test("names each characteristic after what is exchanged over it", () {
      final config = aHaloConfig();

      expect(config.charAAttrNotify.name, "attribute_notification");
      expect(config.charBAttrCmd.name, "attribute_command_and_result");
      expect(config.charCAttrTmp.name, "attribute_exchange_zone");
      expect(config.charJRequestToDeviceCmd.name, "request_to_device_command_and_result");
      expect(config.charKRequestToDeviceTmp.name, "request_to_device_exchange_zone");
    });

    test("says which characteristics the device notifies over", () {
      final config = aHaloConfig();

      expect(
        config.notifiableHaloCharacteristics.map((char) => char.name),
        [
          "attribute_notification",
          "attribute_command_and_result",
          "instant_data_notification",
          "instant_data_command_and_result",
          "record_data_notification",
          "record_data_command_and_result",
          "request_to_device_command_and_result",
          "request_to_device_exchange_zone",
          "request_to_client_command_and_result",
          "request_to_client_exchange_zone",
        ],
      );
    });

    test("says that the exchange zones of the attributes and of the data notify nothing", () {
      final config = aHaloConfig();

      expect(config.charCAttrTmp.hasNotification, isFalse);
      expect(config.charFInstTmp.hasNotification, isFalse);
      expect(config.charIRecordTmp.hasNotification, isFalse);
    });

    test("says which way each characteristic is read and written", () {
      final config = aHaloConfig();

      expect(config.charAAttrNotify.scope, CharacteristicScope.readOnly);
      expect(config.charBAttrCmd.scope, CharacteristicScope.readWrite);
      expect(config.charIRecordTmp.scope, CharacteristicScope.readOnly);
    });

    test("exchanges bytes over the characteristics which are written to", () {
      final config = aHaloConfig();

      expect(config.charJRequestToDeviceCmd.receiveType, Uint8List);
      expect(config.charJRequestToDeviceCmd.sendType, Uint8List);
    });

    test("says that a characteristic which is only read is never written to", () {
      final config = aHaloConfig();

      expect(config.charAAttrNotify.sendType, isNull);
    });

    test("holds the largest payload the device takes in one packet", () {
      expect(aHaloConfig(maxCharacteristicByteSize: 64).maxCharacteristicByteSize, 64);
    });

    test("refuses a payload size which is not a size", () {
      expect(() => aHaloConfig(maxCharacteristicByteSize: -1), throwsAssertionError);
    });

    test("tells two configurations of the same characteristics apart", () {
      // The characteristics of a configuration are told apart by instance rather than by the
      // identifier they carry, so two configurations are never the same one
      expect(aHaloConfig(), isNot(aHaloConfig()));
    });
  });
}
