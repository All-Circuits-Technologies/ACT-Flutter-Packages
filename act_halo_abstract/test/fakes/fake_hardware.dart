// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The attributes of a device which answers whatever the test asks it to.
class FakeAttributeHardware extends AbstractHaloAttributeHardware {
  /// True once the component has been closed.
  bool isClosed = false;

  /// Pushes [packet] the way the device pushes an updated attribute.
  void pushNewValue(HaloPacket packet) => attributeNewValueCtrl.add(packet);

  @override
  Future<HaloErrorType> writeAttribute({required HaloPacket packet}) async =>
      HaloErrorType.noError;

  @override
  Future<(HaloErrorType, HaloPacket?)> readAttribute({required HaloDataId dataId}) async =>
      (HaloErrorType.noError, null);

  @override
  Future<HaloErrorType> subAttribute({required HaloDataId dataId}) async => HaloErrorType.noError;

  @override
  Future<HaloErrorType> unSubAttribute({required HaloDataId dataId}) async =>
      HaloErrorType.noError;

  @override
  Future<void> close() async {
    isClosed = true;

    await super.close();
  }
}

/// The instant data of a device which answers whatever the test asks it to.
class FakeInstantDataHardware extends AbstractHaloInstantDataHardware {
  /// True once the component has been closed.
  bool isClosed = false;

  /// Pushes [packet] the way the device pushes updated instant data.
  void pushNewValue(HaloPacket packet) => instantDataNewValueCtrl.add(packet);

  @override
  Future<HaloErrorType> writeInstantData({required HaloPacket packet}) async =>
      HaloErrorType.noError;

  @override
  Future<(HaloErrorType, HaloPacket?)> readInstantData({required HaloDataId dataId}) async =>
      (HaloErrorType.noError, null);

  @override
  Future<HaloErrorType> subInstantData({required HaloDataId dataId}) async =>
      HaloErrorType.noError;

  @override
  Future<HaloErrorType> unSubInstantData({required HaloDataId dataId}) async =>
      HaloErrorType.noError;

  @override
  Future<void> close() async {
    isClosed = true;

    await super.close();
  }
}

/// The record data of a device which answers whatever the test asks it to.
class FakeRecordDataHardware extends AbstractHaloRecordDataHardware {
  /// True once the component has been closed.
  bool isClosed = false;

  /// Pushes [packet] the way the device pushes a new record.
  void pushNewValue(HaloRecordPacket packet) => recordDataNewValueCtrl.add(packet);

  /// Pushes [key] the way the device pushes the key of a new record.
  void pushNewKey(HaloRecordKey key) => recordKeysNewValueCtrl.add(key);

  @override
  Future<HaloErrorType> subRecordData({
    required HaloDataId dataId,
    bool onlyNotifyKey = false,
  }) async => HaloErrorType.noError;

  @override
  Future<HaloErrorType> unSubRecordData({required HaloDataId dataId}) async =>
      HaloErrorType.noError;

  @override
  Future<(HaloErrorType, HaloRecordPacket?)> readRecordData({
    required HaloRecordKey recordKey,
  }) async => (HaloErrorType.noError, null);

  @override
  Future<(HaloErrorType, List<HaloRecordKey>?)> getAllRecordDataKeys({
    required HaloDataId dataId,
  }) async => (HaloErrorType.noError, const <HaloRecordKey>[]);

  @override
  Future<HaloErrorType> ackRecordData({required HaloRecordKey recordKey}) async =>
      HaloErrorType.noError;

  @override
  Future<void> close() async {
    isClosed = true;

    await super.close();
  }
}

/// The requests a device sends to the application.
class FakeRequestFromDeviceHardware extends AbstractHaloRequestFromDeviceHardware {
  /// True once the component has been closed.
  bool isClosed = false;

  @override
  Future<void> close() async {
    isClosed = true;

    await super.close();
  }
}

/// The requests the application sends to a device which answers what the test asks it to.
class FakeRequestToDeviceHardware extends AbstractHaloRequestToDeviceHardware {
  /// The result the device answers a function with.
  HaloRequestResult? functionResult;

  /// The error the device answers a procedure with.
  HaloErrorType procedureError = HaloErrorType.noError;

  /// The error the device answers an order with.
  HaloErrorType orderError = HaloErrorType.noError;

  /// The requests which reached the device.
  final List<HaloRequestParamsPacket> calledRequests = [];

  /// The timeouts the requests reached the device with.
  final List<Duration> executionTimeouts = [];

  /// True once the component has been closed.
  bool isClosed = false;

  @override
  Future<HaloRequestResult> implCallFunction({
    required HaloRequestParamsPacket request,
    required Duration executionTimeout,
  }) async {
    calledRequests.add(request);
    executionTimeouts.add(executionTimeout);

    return functionResult ??
        HaloRequestResult(
          requestId: request.requestId,
          result: HaloPayloadPacket(),
          error: HaloErrorType.noError,
        );
  }

  @override
  Future<HaloErrorType> implCallProcedure({
    required HaloRequestParamsPacket request,
    required Duration executionTimeout,
  }) async {
    calledRequests.add(request);
    executionTimeouts.add(executionTimeout);

    return procedureError;
  }

  @override
  Future<HaloErrorType> implCallOrder({required HaloRequestParamsPacket request}) async {
    calledRequests.add(request);

    return orderError;
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

/// A hardware layer built on the components a test can drive.
class FakeHaloHardware extends AbstractHaloHardware {
  /// Class constructor
  FakeHaloHardware()
    : super(
        attributeHardware: FakeAttributeHardware(),
        instantDataHardware: FakeInstantDataHardware(),
        recordDataHardware: FakeRecordDataHardware(),
        requestFromDeviceHardware: FakeRequestFromDeviceHardware(),
        requestToDeviceHardware: FakeRequestToDeviceHardware(),
      );

  /// The attributes of the device.
  FakeAttributeHardware get fakeAttributes => attributeHardware as FakeAttributeHardware;

  /// The instant data of the device.
  FakeInstantDataHardware get fakeInstantData => instantDataHardware as FakeInstantDataHardware;

  /// The record data of the device.
  FakeRecordDataHardware get fakeRecordData => recordDataHardware as FakeRecordDataHardware;

  /// The requests the device sends to the application.
  FakeRequestFromDeviceHardware get fakeRequestsFromDevice =>
      requestFromDeviceHardware as FakeRequestFromDeviceHardware;

  /// The requests the application sends to the device.
  FakeRequestToDeviceHardware get fakeRequestsToDevice =>
      requestToDeviceHardware as FakeRequestToDeviceHardware;
}
