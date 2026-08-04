// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

import '../../fakes/fake_thingsboard.dart';

void main() {
  late FakeTbRequestManager requestManager;
  late FakeDeviceService devices;
  late TbDevicesService service;

  setUpAll(() {
    registerFallbackValue(PageLink(1));
  });

  setUp(() {
    requestManager = FakeTbRequestManager();
    devices = FakeDeviceService();
    when(requestManager.client.getDeviceService).thenReturn(devices);

    service = TbDevicesService(
      requestManager: requestManager,
      logsHelper: FakeExternalLogger().buildHelper(category: "test"),
    );
  });

  /// Has the server answer that the user who is signed in belongs to [customerId].
  void signedInAs({String? customerId = "a-customer"}) =>
      when(requestManager.client.getAuthUser).thenReturn(aCustomerUser(customerId: customerId));

  /// Has the server answer that nobody is signed in.
  void signedOut() => when(requestManager.client.getAuthUser).thenReturn(null);

  group("TbDevicesService.getCurrentCustomerId", () {
    test("answers the customer the user who is signed in belongs to", () async {
      signedInAs();

      expect(await service.getCurrentCustomerId(), "a-customer");
    });

    test("answers nothing when nobody is signed in", () async {
      signedOut();

      expect(await service.getCurrentCustomerId(), isNull);
    });

    test("answers nothing when the user belongs to no customer", () async {
      signedInAs(customerId: null);

      expect(await service.getCurrentCustomerId(), isNull);
    });

    test("answers nothing when the request to the server failed", () async {
      signedInAs();
      requestManager.answers.add(RequestStatus.loginError);

      expect(await service.getCurrentCustomerId(), isNull);
    });
  });

  group("TbDevicesService.getCurrentCustomerDevices", () {
    test("answers the devices of the customer of the user", () async {
      signedInAs();
      final page = aPage([Device("a device", "a type")]);
      when(() => devices.getCustomerDevices(any(), any())).thenAnswer((_) async => page);

      expect(await service.getCurrentCustomerDevices(), same(page));
    });

    test("asks the server for the customer of the user", () async {
      signedInAs();
      when(() => devices.getCustomerDevices(any(), any())).thenAnswer((_) async => aPage([]));

      await service.getCurrentCustomerDevices();

      final customerId = verify(
        () => devices.getCustomerDevices(captureAny(), any()),
      ).captured.single;

      expect(customerId, "a-customer");
    });

    test("reads the devices by pages of fifty unless it is told otherwise", () async {
      signedInAs();
      when(() => devices.getCustomerDevices(any(), any())).thenAnswer((_) async => aPage([]));

      await service.getCurrentCustomerDevices();

      final pageLink = verify(
        () => devices.getCustomerDevices(any(), captureAny()),
      ).captured.single;

      expect((pageLink as PageLink).pageSize, 50);
    });

    test("reads the page it is asked for", () async {
      signedInAs();
      final asked = PageLink(10, 2);
      when(() => devices.getCustomerDevices(any(), any())).thenAnswer((_) async => aPage([]));

      await service.getCurrentCustomerDevices(pageLink: asked);

      final pageLink = verify(
        () => devices.getCustomerDevices(any(), captureAny()),
      ).captured.single;

      expect(pageLink, same(asked));
    });

    test("answers nothing when the customer of the user is unknown", () async {
      signedOut();

      expect(await service.getCurrentCustomerDevices(), isNull);
      verifyNever(() => devices.getCustomerDevices(any(), any()));
    });

    test("answers nothing when the request to the server failed", () async {
      signedInAs();
      requestManager.answers.addAll([RequestStatus.success, RequestStatus.globalError]);

      expect(await service.getCurrentCustomerDevices(), isNull);
    });
  });

  group("TbDevicesService.getCustomerDeviceByName", () {
    test("answers the device which carries the name", () async {
      signedInAs();
      final device = aDeviceInfo("a device");
      when(
        () => devices.getCustomerDeviceInfos(any(), any()),
      ).thenAnswer((_) async => aPage([device]));

      final result = await service.getCustomerDeviceByName(deviceName: "a device");

      expect(result.success, isTrue);
      expect(result.deviceInfo, same(device));
    });

    test("answers no device when the customer has none of that name", () async {
      signedInAs();
      when(
        () => devices.getCustomerDeviceInfos(any(), any()),
      ).thenAnswer((_) async => aPage([aDeviceInfo("another device")]));

      final result = await service.getCustomerDeviceByName(deviceName: "a device");

      expect(result.success, isTrue);
      expect(result.deviceInfo, isNull);
    });

    test("reads the next pages until it finds the device", () async {
      signedInAs();
      final device = aDeviceInfo("a device");
      var page = 0;
      when(() => devices.getCustomerDeviceInfos(any(), any())).thenAnswer(
        (_) async => page++ == 0 ? aPage([aDeviceInfo("a device 2")], hasNext: true) : aPage([device]),
      );

      final result = await service.getCustomerDeviceByName(deviceName: "a device");

      expect(result.deviceInfo, same(device));
      expect(page, 2);
    });

    test("asks for the page which follows the one it read", () async {
      signedInAs();
      var page = 0;
      when(() => devices.getCustomerDeviceInfos(any(), any())).thenAnswer(
        (_) async => page++ == 0 ? aPage([], hasNext: true) : aPage([]),
      );

      await service.getCustomerDeviceByName(deviceName: "a device");

      final pageLinks = verify(
        () => devices.getCustomerDeviceInfos(any(), captureAny()),
      ).captured.cast<PageLink>();

      expect(pageLinks.map((link) => link.page), [0, 1]);
      expect(pageLinks.map((link) => link.textSearch), ["a device", "a device"]);
    });

    test("stops reading the pages once the last one is read", () async {
      signedInAs();
      when(() => devices.getCustomerDeviceInfos(any(), any())).thenAnswer((_) async => aPage([]));

      await service.getCustomerDeviceByName(deviceName: "a device");

      verify(() => devices.getCustomerDeviceInfos(any(), any())).called(1);
    });

    test("says that it failed when the customer of the user is unknown", () async {
      signedOut();

      final result = await service.getCustomerDeviceByName(deviceName: "a device");

      expect(result.success, isFalse);
      expect(result.deviceInfo, isNull);
    });

    test("says that it failed when the request to the server failed", () async {
      signedInAs();
      requestManager.answers.addAll([RequestStatus.success, RequestStatus.globalError]);

      final result = await service.getCustomerDeviceByName(deviceName: "a device");

      expect(result.success, isFalse);
    });
  });

  group("TbDevicesService.createTelemetryHandler", () {
    test("hands over a handler of the telemetry of the device", () {
      expect(service.createTelemetryHandler(aDeviceId), isA<TbTelemetryHandler>());
    });

    test("hands over another handler of the values of a device it already knows", () {
      final first = service.createTelemetryHandler(aDeviceId);

      final second = service.createTelemetryHandler(aDeviceId);

      expect(second, isNot(same(first)));
    });

    test("keeps the values of a device which two handlers watch together", () async {
      final first = service.createTelemetryHandler(aDeviceId);
      final second = service.createTelemetryHandler(aDeviceId);

      await first.add(tsKeys: ["temp"]);
      await second.add(tsKeys: ["temp"]);

      expect(requestManager.client.telemetryService.subscribed.length, 1);
    });
  });

  group("TbDevicesService.disposeLifeCycle", () {
    test("gives up the subscriptions of every device it watched", () async {
      final handler = service.createTelemetryHandler(aDeviceId);
      await handler.add(tsKeys: ["temp"]);

      await service.disposeLifeCycle();

      expect(requestManager.client.telemetryService.current, isNull);
    });
  });
}
