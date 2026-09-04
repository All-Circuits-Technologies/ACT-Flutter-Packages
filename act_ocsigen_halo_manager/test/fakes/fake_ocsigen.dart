// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';

/// The ways an application under test reaches its device.
enum FakeHwType {
  /// The way the application reaches the device.
  ble,

  /// A way the application knows of but does not use.
  serial,
}

/// The requests an application adds to the ones OCSIGEN devices already answer.
enum AppRequestId with MixinHaloType, MixinHaloRequestId {
  /// A request of the application itself.
  readTemperature(rawValue: 0x01, type: HaloRequestType.function),

  /// A request which is answered instead of the OCSIGEN one which shares its value.
  echo(rawValue: 0xFF, type: HaloRequestType.function);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// The type of request
  @override
  final HaloRequestType type;

  /// Enum constructor
  const AppRequestId({required this.rawValue, required this.type});
}

/// The requests of a device, answered by the test.
///
/// It records what it was sent, which is what a test reads to know what the feature wrote in the
/// packet of a request.
class FakeOcsigenDevice extends AbstractHaloRequestToDeviceHardware {
  /// The error the device answers with.
  final HaloErrorType error;

  /// The values the device answers a function with, if it answers any.
  HaloPayloadPacket? result;

  /// The requests the device received, in the order it received them.
  final List<HaloRequestParamsPacket> calls = [];

  /// Class constructor
  FakeOcsigenDevice({this.error = HaloErrorType.noError, this.result});

  /// The request the device received, when it received one only.
  HaloRequestParamsPacket get call => calls.single;

  /// {@macro act_halo_abstract.AbstractHaloRequestToDeviceHardware.implCallFunction}
  @override
  Future<HaloRequestResult> implCallFunction({
    required HaloRequestParamsPacket request,
    required Duration executionTimeout,
  }) async {
    calls.add(request);

    if (error != HaloErrorType.noError) {
      return HaloRequestResult.error(requestId: request.requestId, error: error);
    }

    return HaloRequestResult(requestId: request.requestId, result: result, error: error);
  }

  /// {@macro act_halo_abstract.AbstractHaloRequestToDeviceHardware.implCallProcedure}
  @override
  Future<HaloErrorType> implCallProcedure({
    required HaloRequestParamsPacket request,
    required Duration executionTimeout,
  }) async {
    calls.add(request);

    return error;
  }

  /// {@macro act_halo_abstract.AbstractHaloRequestToDeviceHardware.implCallOrder}
  @override
  Future<HaloErrorType> implCallOrder({required HaloRequestParamsPacket request}) async {
    calls.add(request);

    return error;
  }

  /// {@macro act_halo_abstract.AbstractHaloRequestToDeviceHardware.close}
  @override
  Future<void> close() async {}
}

/// The attributes of a device an application under test does not read.
class FakeAttributeHardware extends AbstractHaloAttributeHardware {
  @override
  Future<HaloErrorType> writeAttribute({required HaloPacket packet}) async => HaloErrorType.noError;

  @override
  Future<(HaloErrorType, HaloPacket?)> readAttribute({required HaloDataId dataId}) async =>
      (HaloErrorType.noError, null);

  @override
  Future<HaloErrorType> subAttribute({required HaloDataId dataId}) async => HaloErrorType.noError;

  @override
  Future<HaloErrorType> unSubAttribute({required HaloDataId dataId}) async => HaloErrorType.noError;
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
  FakeHaloHardware({required FakeOcsigenDevice requestToDevice})
    : super(
        attributeHardware: FakeAttributeHardware(),
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

  /// Builds a helper which reaches the device over the way an application uses.
  factory FakeHwTypeHelper.only({required FakeOcsigenDevice device}) => FakeHwTypeHelper(
    hardwareServices: {
      FakeHwType.ble: HaloHardwareType<FakeHwType>(
        type: FakeHwType.ble,
        haloHardware: FakeHaloHardware(requestToDevice: device),
      ),
    },
  );
}

/// The OCSIGEN HALO manager of an application under test.
class FakeOcsigenManager extends AbstractOcsigenHaloManager<FakeHwType> {
  /// The device the application reaches.
  final FakeOcsigenDevice device;

  /// Class constructor
  FakeOcsigenManager({required this.device});

  /// {@macro act_halo_manager.AbstractHaloManager.initHaloManagerConfig}
  @override
  Future<HaloManagerConfig<FakeHwType>?> initHaloManagerConfig() async =>
      HaloManagerConfig<FakeHwType>(
        hardwareLayer: FakeHwTypeHelper.only(device: device),
        requestIdHelper: OcsigenRequestIdHelper(),
      );
}

/// The builder of the OCSIGEN HALO manager of an application under test.
class FakeOcsigenBuilder extends AbstractOcsigenHaloBuilder<FakeOcsigenManager> {
  /// Class constructor
  FakeOcsigenBuilder(super.factory);
}
