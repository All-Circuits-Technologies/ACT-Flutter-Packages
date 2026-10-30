// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Base the events of the barcode scanner bloc on this class.
sealed class BarcodeScannerEvent extends BlocEventForMixin {
  /// Create the event.
  const BarcodeScannerEvent();
}

/// Ask the bloc to check, and ask if needed, the camera permission again.
class BarcodeScannerAskPermissionEvent extends BarcodeScannerEvent {
  /// Create the event.
  const BarcodeScannerAskPermissionEvent();

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props];
}

/// Tell the bloc that the camera permission is known.
class BarcodeScannerPermissionEvent extends BarcodeScannerEvent {
  /// Tell whether the camera permission is granted.
  final bool isGranted;

  /// Create the event.
  const BarcodeScannerPermissionEvent({required this.isGranted});

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props, isGranted];
}

/// Tell the bloc that the state of the scanner controller changed.
class BarcodeScannerControllerEvent extends BarcodeScannerEvent {
  /// Hold the new state of the scanner controller.
  final MobileScannerState controllerState;

  /// Create the event.
  const BarcodeScannerControllerEvent({required this.controllerState});

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [
    ...super.props,
    controllerState.isInitialized,
    controllerState.isStarting,
    controllerState.isRunning,
    controllerState.error,
  ];
}
