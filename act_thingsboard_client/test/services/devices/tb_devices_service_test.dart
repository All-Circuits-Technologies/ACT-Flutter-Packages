// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:dio/dio.dart';
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

  /// Has the server answer [data] with the HTTP status [status] to a claim.
  void serverAnswersClaim(Object? data, {int status = 200}) => when(
    () => requestManager.client.post<dynamic>(
      any(),
      data: any(named: "data"),
      options: any(named: "options"),
    ),
  ).thenAnswer((_) async => anAnswer(data, status: status));

  /// Has the server accept the release of a claim.
  void serverAnswersRelease() => when(
    () => requestManager.client.delete<void>(any()),
  ).thenAnswer((_) async => Response<void>(requestOptions: RequestOptions(path: "/")));

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

  group("TbDevicesService.getCurrentCustomerDeviceInfos", () {
    test("answers the devices of the customer of the user", () async {
      signedInAs();
      final page = aPage([aDeviceInfo("a device")]);
      when(() => devices.getCustomerDeviceInfos(any(), any())).thenAnswer((_) async => page);

      expect(await service.getCurrentCustomerDeviceInfos(), same(page));
    });

    test("asks the server for the customer of the user", () async {
      signedInAs();
      when(() => devices.getCustomerDeviceInfos(any(), any())).thenAnswer((_) async => aPage([]));

      await service.getCurrentCustomerDeviceInfos();

      final customerId = verify(
        () => devices.getCustomerDeviceInfos(captureAny(), any()),
      ).captured.single;

      expect(customerId, "a-customer");
    });

    test("reads the devices by pages of fifty unless it is told otherwise", () async {
      signedInAs();
      when(() => devices.getCustomerDeviceInfos(any(), any())).thenAnswer((_) async => aPage([]));

      await service.getCurrentCustomerDeviceInfos();

      final pageLink = verify(
        () => devices.getCustomerDeviceInfos(any(), captureAny()),
      ).captured.single;

      expect((pageLink as PageLink).pageSize, 50);
    });

    test("reads the page it is asked for", () async {
      signedInAs();
      final asked = PageLink(10, 2);
      when(() => devices.getCustomerDeviceInfos(any(), any())).thenAnswer((_) async => aPage([]));

      await service.getCurrentCustomerDeviceInfos(pageLink: asked);

      final pageLink = verify(
        () => devices.getCustomerDeviceInfos(any(), captureAny()),
      ).captured.single;

      expect(pageLink, same(asked));
    });

    test("answers nothing when the customer of the user is unknown", () async {
      signedOut();

      expect(await service.getCurrentCustomerDeviceInfos(), isNull);
      verifyNever(() => devices.getCustomerDeviceInfos(any(), any()));
    });

    test("answers nothing when the request to the server failed", () async {
      signedInAs();
      requestManager.answers.addAll([RequestStatus.success, RequestStatus.globalError]);

      expect(await service.getCurrentCustomerDeviceInfos(), isNull);
    });
  });

  group("TbDevicesService.claimDevice", () {
    test("sends the secret to the claim endpoint of the device", () async {
      serverAnswersClaim({"response": "SUCCESS"});

      await service.claimDevice(deviceName: "a device", secretKey: "a secret");

      final call = verify(
        () => requestManager.client.post<dynamic>(
          captureAny(),
          data: captureAny(named: "data"),
          options: any(named: "options"),
        ),
      ).captured;

      expect(call.first, "/api/customer/device/a%20device/claim");
      expect(call.last, {"secretKey": "a secret"});
    });

    test("answers what the server said and the device it bound", () async {
      serverAnswersClaim({
        "response": "SUCCESS",
        "device": {
          "id": {"id": "a-device-id"},
        },
      });

      final attempt = await service.claimDevice(deviceName: "a device", secretKey: "a secret");

      expect(attempt.status, RequestStatus.success);
      expect(attempt.response, ClaimResponse.SUCCESS);
      expect(attempt.deviceId, "a-device-id");
      expect(attempt.httpStatus, 200);
    });

    test("reads the refusal the server answers as a bare string", () async {
      serverAnswersClaim("CLAIMED");

      final attempt = await service.claimDevice(deviceName: "a device", secretKey: "a secret");

      expect(attempt.response, ClaimResponse.CLAIMED);
      expect(attempt.deviceId, isNull);
    });

    test("answers the status the server refused the claim with", () async {
      serverAnswersClaim("FAILURE", status: 400);

      final attempt = await service.claimDevice(deviceName: "a device", secretKey: "a secret");

      expect(attempt.response, ClaimResponse.FAILURE);
      expect(attempt.httpStatus, 400);
    });

    test("reads the refusals of the server and leaves the session errors throwing", () async {
      serverAnswersClaim("FAILURE");

      await service.claimDevice(deviceName: "a device", secretKey: "a secret");

      final options =
          verify(
                () => requestManager.client.post<dynamic>(
                  any(),
                  data: any(named: "data"),
                  options: captureAny(named: "options"),
                ),
              ).captured.single
              as Options;

      expect(options.validateStatus?.call(400), isTrue);
      expect(options.validateStatus?.call(404), isTrue);
      expect(options.validateStatus?.call(401), isFalse);
      expect(options.validateStatus?.call(403), isFalse);
      expect(options.validateStatus?.call(500), isFalse);
    });

    test("answers the status of the request when the session is over", () async {
      requestManager.answers.add(RequestStatus.loginError);

      final attempt = await service.claimDevice(deviceName: "a device", secretKey: "a secret");

      expect(attempt.status, RequestStatus.loginError);
      expect(attempt.response, isNull);
      expect(attempt.httpStatus, isNull);
    });
  });

  group("TbDevicesService.releaseClaim", () {
    test("asks the server to release the device", () async {
      serverAnswersRelease();

      await service.releaseClaim(deviceName: "a device");

      final path = verify(() => requestManager.client.delete<void>(captureAny())).captured.single;

      expect(path, "/api/customer/device/a%20device/claim");
    });

    test("answers that the request went through", () async {
      serverAnswersRelease();

      expect((await service.releaseClaim(deviceName: "a device")).isOk, isTrue);
    });

    test("answers the status of the request when the session is over", () async {
      requestManager.answers.add(RequestStatus.loginError);

      final response = await service.releaseClaim(deviceName: "a device");

      expect(response.status, RequestStatus.loginError);
      verifyNever(() => requestManager.client.delete<void>(any()));
    });
  });

  group("TbDevicesService.isDeviceVisibleToCustomer", () {
    test("says that the device is visible when the customer reads it back", () async {
      when(() => devices.getDevice(any())).thenAnswer((_) async => Device("a device", "a type"));

      expect(await service.isDeviceVisibleToCustomer(aDeviceId), isTrue);
    });

    test("says that the device is not visible when the server answers none", () async {
      when(() => devices.getDevice(any())).thenAnswer((_) async => null);

      expect(await service.isDeviceVisibleToCustomer(aDeviceId), isFalse);
    });

    test("says that the device is not visible when the request to the server failed", () async {
      requestManager.answers.add(RequestStatus.globalError);

      expect(await service.isDeviceVisibleToCustomer(aDeviceId), isFalse);
    });
  });

  group("TbDevicesService.outcomeFromAttempt", () {
    test("says that the session is over when the request never reached the server", () {
      expect(
        TbDevicesService.outcomeFromAttempt(
          anAttempt(status: RequestStatus.loginError, response: ClaimResponse.SUCCESS),
        ),
        TbClaimOutcome.loginError,
      );
    });

    test("says that the claim worked when the server answered SUCCESS", () {
      expect(
        TbDevicesService.outcomeFromAttempt(anAttempt(response: ClaimResponse.SUCCESS)),
        TbClaimOutcome.success,
      );
    });

    test("says that the device is already claimed when the server answered CLAIMED", () {
      expect(
        TbDevicesService.outcomeFromAttempt(anAttempt(response: ClaimResponse.CLAIMED)),
        TbClaimOutcome.alreadyClaimed,
      );
    });

    test("says that the claim was refused when the server answered FAILURE", () {
      expect(
        TbDevicesService.outcomeFromAttempt(anAttempt(response: ClaimResponse.FAILURE)),
        TbClaimOutcome.refused,
      );
    });

    test("says that the device is unknown when the server answered 404", () {
      expect(
        TbDevicesService.outcomeFromAttempt(anAttempt(httpStatus: 404)),
        TbClaimOutcome.unknownDevice,
      );
    });

    test("says that the secret was refused when the server answered 400", () {
      expect(
        TbDevicesService.outcomeFromAttempt(anAttempt(httpStatus: 400)),
        TbClaimOutcome.secretRefused,
      );
    });

    test("says that the server could not be reached on any other answer", () {
      expect(
        TbDevicesService.outcomeFromAttempt(anAttempt(httpStatus: 503)),
        TbClaimOutcome.communicationError,
      );
      expect(TbDevicesService.outcomeFromAttempt(anAttempt()), TbClaimOutcome.communicationError);
    });
  });

  group("TbDevicesService.parseDeviceId", () {
    test("reads the device the server says it bound", () {
      expect(
        TbDevicesService.parseDeviceId({
          "device": {
            "id": {"id": "a-device-id"},
          },
        }),
        "a-device-id",
      );
    });

    test("answers nothing when the answer carries no device", () {
      expect(TbDevicesService.parseDeviceId(const <String, dynamic>{}), isNull);
      expect(TbDevicesService.parseDeviceId(const {"device": "a device"}), isNull);
      expect(TbDevicesService.parseDeviceId(const {"device": <String, dynamic>{}}), isNull);
      expect(
        TbDevicesService.parseDeviceId(const {
          "device": {"id": <String, dynamic>{}},
        }),
        isNull,
      );
      expect(
        TbDevicesService.parseDeviceId(const {
          "device": {
            "id": {"id": ""},
          },
        }),
        isNull,
      );
    });

    test("answers nothing when the server answered a bare string or nothing at all", () {
      expect(TbDevicesService.parseDeviceId("CLAIMED"), isNull);
      expect(TbDevicesService.parseDeviceId(null), isNull);
    });
  });

  group("TbDevicesService.parseClaimResponse", () {
    test("reads the claim answer of an answer which is an object", () {
      expect(
        TbDevicesService.parseClaimResponse(const {"response": "SUCCESS"}),
        ClaimResponse.SUCCESS,
      );
    });

    test("reads the claim answer the server sent as a bare string", () {
      expect(TbDevicesService.parseClaimResponse("CLAIMED"), ClaimResponse.CLAIMED);
      expect(TbDevicesService.parseClaimResponse("FAILURE"), ClaimResponse.FAILURE);
    });

    test("reads a claim answer whatever its case", () {
      expect(TbDevicesService.parseClaimResponse("success"), ClaimResponse.SUCCESS);
    });

    test("answers nothing when the answer carries no claim answer", () {
      expect(TbDevicesService.parseClaimResponse(null), isNull);
      expect(TbDevicesService.parseClaimResponse(const <String, dynamic>{}), isNull);
      expect(TbDevicesService.parseClaimResponse("not a verdict"), isNull);
    });
  });
}

/// The answer of the server to a claim, which carries [data] and the HTTP status [status].
Response<dynamic> anAnswer(Object? data, {int status = 200}) =>
    Response<dynamic>(requestOptions: RequestOptions(path: "/"), data: data, statusCode: status);

/// One answer of the server to a claim, as the decision table reads it.
TbClaimAttempt anAttempt({
  RequestStatus status = RequestStatus.success,
  ClaimResponse? response,
  int? httpStatus,
}) => TbClaimAttempt(status: status, response: response, httpStatus: httpStatus);
