// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
// The packets of the protocol are only exchanged inside the package, so they are not part of its
// public interface; there is no other way to read what is sent to a device
// ignore: implementation_imports
import 'package:act_halo_ble_layer/src/packets/halo_ble_request_to_device_cmd_packet.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_halo_ble.dart';

void main() {
  /// The request of an application which asks the device for [nbValues] parameters.
  HaloBleRequestToDeviceCmdPacket aCall({
    MixinHaloRequestId requestId = FakeHaloRequestId.aFunction,
    List<int> nbValues = const [],
  }) => HaloBleRequestToDeviceCmdPacket(
    packetToSend: HaloRequestParamsPacket(
      requestId: requestId,
      nbValues: nbValues,
      parameters: aPayload(const []),
    ),
  );

  group("HaloBleRequestToDeviceCmdPacket.getDataToSend", () {
    test("says which request of the device is called and how", () {
      final data = aCall().getDataToSend();

      expect(data[0], HaloCmdId.call.rawValue);
      expect(data[1], FakeHaloRequestId.aFunction.rawValue);
      expect(data[2], HaloRequestType.function.rawValue);
    });

    test("says that a request without parameters carries none", () {
      final data = aCall().getDataToSend();

      expect(data.length, 4);
      expect(data[3], 0);
    });

    test("says how many values each parameter of the request carries", () {
      final data = aCall(nbValues: const [1, 3]).getDataToSend();

      expect(data[3], 2);
      expect(data.sublist(4), const [1, 3]);
    });

    test("asks the device to start the exchange over", () {
      final data = HaloBleRequestToDeviceCmdPacket.reset(
        requestId: FakeHaloRequestId.anOrder,
      ).getDataToSend();

      expect(data, [
        HaloCmdId.reset.rawValue,
        FakeHaloRequestId.anOrder.rawValue,
        HaloRequestType.order.rawValue,
        0,
      ]);
    });

    test("tells the device that the application is ready to read", () {
      final data = HaloBleRequestToDeviceCmdPacket.readReady(
        requestId: FakeHaloRequestId.aFunction,
      ).getDataToSend();

      expect(data, [
        HaloCmdId.readReady.rawValue,
        FakeHaloRequestId.aFunction.rawValue,
        HaloRequestType.function.rawValue,
        0,
      ]);
    });
  });

  group("HaloBleRequestToDeviceCmdPacket", () {
    test("reads two requests of the same kind as the same one", () {
      final request = HaloRequestParamsPacket.voidParams(requestId: FakeHaloRequestId.aFunction);

      expect(
        HaloBleRequestToDeviceCmdPacket(packetToSend: request),
        HaloBleRequestToDeviceCmdPacket(packetToSend: request),
      );
    });

    test("tells a call and a reset of the same request apart", () {
      final request = HaloRequestParamsPacket.voidParams(requestId: FakeHaloRequestId.aFunction);

      expect(
        HaloBleRequestToDeviceCmdPacket(packetToSend: request),
        isNot(HaloBleRequestToDeviceCmdPacket.reset(requestId: FakeHaloRequestId.aFunction)),
      );
    });
  });
}
