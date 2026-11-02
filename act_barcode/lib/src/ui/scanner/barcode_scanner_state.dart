// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_barcode/src/types/barcode_scanner_status.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Hold the status of the barcode scanner, from the camera permission to the camera.
class BarcodeScannerState extends BlocStateForMixin<BarcodeScannerState> {
  /// Hold the current status of the scanner.
  ///
  /// It's null until the asynchronous initialization of the bloc has emitted the first status.
  final BarcodeScannerStatus? status;

  /// Tell whether the camera has run since the permission was granted.
  ///
  /// It tells a camera which stopped from one which hasn't started yet.
  final bool hasCameraRun;

  /// Tell whether the [status] follows the camera, which is the case once the permission is
  /// granted.
  bool get isCameraStatus =>
      status == BarcodeScannerStatus.starting ||
      status == BarcodeScannerStatus.scanning ||
      status == BarcodeScannerStatus.stopped ||
      status == BarcodeScannerStatus.error;

  /// Create the state from all its values.
  const BarcodeScannerState({required this.status, required this.hasCameraRun});

  /// Create the state the bloc starts with, which has no status yet.
  const BarcodeScannerState.init() : status = null, hasCameraRun = false;

  /// {@macro act_flutter_utility.BlocStateForMixin.copyWith}
  @override
  BarcodeScannerState copyWith({
    BarcodeScannerStatus? status,
    bool forceStatusValue = false,
    bool? hasCameraRun,
  }) => BarcodeScannerState(
    status: forceStatusValue ? status : (status ?? this.status),
    hasCameraRun: hasCameraRun ?? this.hasCameraRun,
  );

  /// Copy the state to the one of a platform where the camera can't be read.
  BarcodeScannerState copyToUnsupportedState() =>
      copyWith(status: BarcodeScannerStatus.unsupported, forceStatusValue: true);

  /// Copy the state to the one where the camera permission is checked or asked for.
  BarcodeScannerState copyToWaitingPermissionState() =>
      copyWith(status: BarcodeScannerStatus.waitingPermission, forceStatusValue: true);

  /// Copy the state to the one where the camera permission isn't granted.
  BarcodeScannerState copyToPermissionDeniedState() =>
      copyWith(status: BarcodeScannerStatus.permissionDenied, forceStatusValue: true);

  /// Copy the state once the camera permission is granted.
  ///
  /// The camera hasn't run since this permission, and the status comes from the
  /// [controllerState].
  BarcodeScannerState copyWithGrantedPermission({required MobileScannerState controllerState}) =>
      _copyFromController(controllerState: controllerState, hasCameraRun: false);

  /// Copy the state with the new state of the scanner controller.
  BarcodeScannerState copyWithControllerState({required MobileScannerState controllerState}) =>
      _copyFromController(controllerState: controllerState, hasCameraRun: hasCameraRun);

  /// Copy the state, whose status comes from the [controllerState].
  ///
  /// The [hasCameraRun] is the value before the [controllerState] is taken into account.
  BarcodeScannerState _copyFromController({
    required MobileScannerState controllerState,
    required bool hasCameraRun,
  }) {
    final BarcodeScannerStatus status;
    var hasRun = hasCameraRun;

    if (controllerState.error != null) {
      status = BarcodeScannerStatus.error;
    } else if (controllerState.isRunning) {
      hasRun = true;
      status = BarcodeScannerStatus.scanning;
    } else if (controllerState.isStarting || !hasRun) {
      status = BarcodeScannerStatus.starting;
    } else {
      status = BarcodeScannerStatus.stopped;
    }

    return copyWith(status: status, forceStatusValue: true, hasCameraRun: hasRun);
  }

  /// {@macro act_flutter_utility.BlocStateForMixin.props}
  @override
  List<Object?> get props => [...super.props, status, hasCameraRun];
}
