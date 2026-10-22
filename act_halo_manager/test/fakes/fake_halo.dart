// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/act_halo_manager.dart';

/// The ways an application under test reaches its device.
enum FakeHwType {
  /// The way the application reaches the device.
  ble,

  /// A way the application knows of but does not use.
  serial,
}

/// The requests the device of an application under test answers.
enum FakeRequestId with MixinHaloType, MixinHaloRequestId {
  /// A request which answers with a value.
  readTemperature(rawValue: 0x01, type: HaloRequestType.function),

  /// A request which answers nothing but is acknowledged.
  startHeating(rawValue: 0x02, type: HaloRequestType.procedure),

  /// A request which is neither acknowledged nor answered.
  reboot(rawValue: 0x03, type: HaloRequestType.order);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// The type of request
  @override
  final HaloRequestType type;

  /// Enum constructor
  const FakeRequestId({required this.rawValue, required this.type});
}

/// The requests of a device, answered by the test.
///
/// It answers the errors the test lined up, one per call, and repeats the last one once they run
/// out. That is what lets a test drive the retries of the manager.
class FakeRequestToDeviceHardware extends AbstractHaloRequestToDeviceHardware {
  /// The errors the device answers with, one per call.
  final List<HaloErrorType> errors;

  /// The values the device answers a function with, if it answers any.
  final HaloPayloadPacket? result;

  /// The requests the device received, in the order it received them.
  final List<MixinHaloRequestId> calls = [];

  /// The timeouts the requests were given, in the order they were received.
  final List<Duration> timeouts = [];

  /// True once the component has been closed.
  bool isClosed = false;

  /// When true, the next call throws instead of answering, then the device answers again.
  bool throwOnNextCall = false;

  /// Class constructor
  FakeRequestToDeviceHardware({
    List<HaloErrorType> errors = const [HaloErrorType.noError],
    this.result,
  }) : errors = List<HaloErrorType>.from(errors);

  /// The error the device answers the call which is running with.
  HaloErrorType _errorOf(int callIndex) =>
      errors[callIndex < errors.length ? callIndex : errors.length - 1];

  @override
  Future<HaloRequestResult> implCallFunction({
    required HaloRequestParamsPacket request,
    required Duration executionTimeout,
  }) async {
    final error = _errorOf(calls.length);
    calls.add(request.requestId);
    timeouts.add(executionTimeout);

    if (throwOnNextCall) {
      throwOnNextCall = false;
      throw StateError("the hardware broke");
    }

    if (error != HaloErrorType.noError) {
      return HaloRequestResult.error(requestId: request.requestId, error: error);
    }

    return HaloRequestResult(requestId: request.requestId, result: result, error: error);
  }

  @override
  Future<HaloErrorType> implCallProcedure({
    required HaloRequestParamsPacket request,
    required Duration executionTimeout,
  }) async {
    final error = _errorOf(calls.length);
    calls.add(request.requestId);
    timeouts.add(executionTimeout);

    return error;
  }

  @override
  Future<HaloErrorType> implCallOrder({required HaloRequestParamsPacket request}) async {
    final error = _errorOf(calls.length);
    calls.add(request.requestId);

    return error;
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

/// The attributes of a device, answered by the test.
///
/// It answers the errors the test lined up, one per call, and repeats the last one once they run
/// out. That is what lets a test drive the retries of the manager.
class FakeAttributeHardware extends AbstractHaloAttributeHardware {
  /// The errors the device answers with, one per call.
  final List<HaloErrorType> errors;

  /// The values the device answers a read with, if it answers any.
  final HaloPayloadPacket? result;

  /// The calls the device received, in the order it received them, as `<method> <id>`.
  final List<String> calls = [];

  /// When true, the next call throws instead of answering, then the device answers again.
  bool throwOnNextCall = false;

  /// Class constructor
  FakeAttributeHardware({List<HaloErrorType> errors = const [HaloErrorType.noError], this.result})
    : errors = List<HaloErrorType>.from(errors);

  /// Records the call and answers the error the test lined up for it.
  HaloErrorType _answer(String method, HaloDataId dataId) {
    final error = errors[calls.length < errors.length ? calls.length : errors.length - 1];
    calls.add("$method ${dataId.id}");

    if (throwOnNextCall) {
      throwOnNextCall = false;
      throw StateError("the hardware broke");
    }

    return error;
  }

  /// Tells the application that the device sent the new value [packet] of an attribute.
  void tellNewValue(HaloPacket packet) => attributeNewValueCtrl.add(packet);

  @override
  Future<HaloErrorType> writeAttribute({required HaloPacket packet}) async =>
      _answer("write", packet.dataId);

  @override
  Future<(HaloErrorType, HaloPacket?)> readAttribute({required HaloDataId dataId}) async {
    final error = _answer("read", dataId);

    if (error != HaloErrorType.noError || result == null) {
      return (error, null);
    }

    return (error, HaloPacket(dataId: dataId, payload: result!));
  }

  @override
  Future<HaloErrorType> subAttribute({required HaloDataId dataId}) async => _answer("sub", dataId);

  @override
  Future<HaloErrorType> unSubAttribute({required HaloDataId dataId}) async =>
      _answer("unsub", dataId);
}

/// The instant data of a device an application under test does not read.
class FakeInstantDataHardware extends AbstractHaloInstantDataHardware {
  @override
  Future<HaloErrorType> writeInstantData({required HaloPacket packet}) async =>
      HaloErrorType.noError;

  @override
  Future<(HaloErrorType, HaloPacket?)> readInstantData({required HaloDataId dataId}) async =>
      (HaloErrorType.noError, null);

  @override
  Future<HaloErrorType> subInstantData({required HaloDataId dataId}) async => HaloErrorType.noError;

  @override
  Future<HaloErrorType> unSubInstantData({required HaloDataId dataId}) async =>
      HaloErrorType.noError;
}

/// The records of a device an application under test does not read.
class FakeRecordDataHardware extends AbstractHaloRecordDataHardware {
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
  }) async => (HaloErrorType.noError, null);

  @override
  Future<HaloErrorType> ackRecordData({required HaloRecordKey recordKey}) async =>
      HaloErrorType.noError;
}

/// The requests a device makes of an application under test.
class FakeRequestFromDeviceHardware extends AbstractHaloRequestFromDeviceHardware {}

/// One way of reaching the device of an application under test.
class FakeHaloHardware extends AbstractHaloHardware {
  /// Class constructor
  FakeHaloHardware({
    required FakeRequestToDeviceHardware requestToDevice,
    FakeAttributeHardware? attribute,
  }) : super(
         attributeHardware: attribute ?? FakeAttributeHardware(),
         instantDataHardware: FakeInstantDataHardware(),
         recordDataHardware: FakeRecordDataHardware(),
         requestFromDeviceHardware: FakeRequestFromDeviceHardware(),
         requestToDeviceHardware: requestToDevice,
       );
}

/// The ways an application under test reaches its device, and what answers on each of them.
class FakeHwTypeHelper extends AbstractHaloHwTypeHelper<FakeHwType> {
  /// Class constructor
  FakeHwTypeHelper({required super.hardwareServices});

  /// Builds a helper which reaches the device over [type] alone.
  factory FakeHwTypeHelper.only({
    required FakeHwType type,
    required FakeRequestToDeviceHardware requestToDevice,
    FakeAttributeHardware? attribute,
  }) => FakeHwTypeHelper(
    hardwareServices: {
      type: HaloHardwareType<FakeHwType>(
        type: type,
        haloHardware: FakeHaloHardware(requestToDevice: requestToDevice, attribute: attribute),
      ),
    },
  );
}

/// The requests an application under test knows of.
class FakeRequestIdHelper extends AbstractHaloRequestIdHelper {
  /// Class constructor
  FakeRequestIdHelper({super.overriddenExecutionTimeout, super.defaultRequestTimeout})
    : super(requestIds: {for (final request in FakeRequestId.values) request.uniqueId: request});
}

/// The HALO manager of an application under test.
class FakeHaloManager extends AbstractHaloManager<FakeHwType> {
  /// The configuration the manager runs on, or null when the application could not build one.
  final HaloManagerConfig<FakeHwType>? config;

  /// The feature the manager builds, if the application builds one of its own.
  final HaloRequestToDeviceFeature<FakeHwType>? ownFeature;

  /// The attribute feature the manager builds, if the application builds one of its own.
  final HaloAttributeFeature<FakeHwType>? ownAttributeFeature;

  /// Class constructor
  FakeHaloManager({this.config, this.ownFeature, this.ownAttributeFeature});

  @override
  Future<HaloManagerConfig<FakeHwType>?> initHaloManagerConfig() async => config;

  @override
  Future<HaloRequestToDeviceFeature<FakeHwType>> createRequestToDeviceFeature({
    required HaloManagerConfig<FakeHwType> haloManagerConfig,
  }) async =>
      ownFeature ?? super.createRequestToDeviceFeature(haloManagerConfig: haloManagerConfig);

  @override
  Future<HaloAttributeFeature<FakeHwType>> createAttributeFeature({
    required HaloManagerConfig<FakeHwType> haloManagerConfig,
  }) async =>
      ownAttributeFeature ?? super.createAttributeFeature(haloManagerConfig: haloManagerConfig);
}

/// The builder of the HALO manager of an application under test.
class FakeHaloBuilder extends AbstractHaloBuilder<FakeHaloManager> {
  /// Class constructor
  FakeHaloBuilder(super.factory);
}
