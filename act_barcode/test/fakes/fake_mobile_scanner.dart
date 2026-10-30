// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Replace the platform of the scanner in a test, which has no real camera.
///
/// It starts without any camera, draws an empty view and sends the captures the test gives it.
class FakeMobileScannerPlatform extends MobileScannerPlatform {
  /// Send the captures to the listeners.
  // ignore: close_sinks, the platform lives as long as the test
  final StreamController<BarcodeCapture?> _barcodesCtrl;

  /// Send the torch states to the listeners.
  // ignore: close_sinks, the platform lives as long as the test
  final StreamController<TorchState> _torchCtrl;

  /// Send the zoom scales to the listeners.
  // ignore: close_sinks, the platform lives as long as the test
  final StreamController<double> _zoomCtrl;

  /// Set the error the camera fails to start with, if the test wants one.
  MobileScannerException? startError;

  /// Count the times the camera was started.
  int startCount;

  /// Count the times the camera was stopped.
  int stopCount;

  /// Count the times the camera was paused.
  int pauseCount;

  /// Count the times the platform was disposed.
  int disposeCount;

  /// Give the captures sent by [emit].
  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodesCtrl.stream;

  /// Give the torch states, of which there is none.
  @override
  Stream<TorchState> get torchStateStream => _torchCtrl.stream;

  /// Give the zoom scales, of which there is none.
  @override
  Stream<double> get zoomScaleStateStream => _zoomCtrl.stream;

  /// Create the platform, whose camera has never been used.
  FakeMobileScannerPlatform()
    : _barcodesCtrl = StreamController<BarcodeCapture?>.broadcast(),
      _torchCtrl = StreamController<TorchState>.broadcast(),
      _zoomCtrl = StreamController<double>.broadcast(),
      startCount = 0,
      stopCount = 0,
      pauseCount = 0,
      disposeCount = 0;

  /// Send a capture of the given [barcodes], as the camera does when it reads them.
  void emit(List<Barcode> barcodes) => _barcodesCtrl.add(BarcodeCapture(barcodes: barcodes));

  /// Build an empty view, in place of the camera view.
  @override
  Widget buildCameraView() => const SizedBox.shrink();

  /// Start the camera, which fails with the [startError] when the test set one.
  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCount++;

    final error = startError;
    if (error != null) {
      throw error;
    }

    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
    );
  }

  /// Stop the camera, which is counted.
  @override
  Future<void> stop() async => stopCount++;

  /// Pause the camera, which is counted.
  @override
  Future<void> pause() async => pauseCount++;

  /// Dispose the platform, which is counted.
  @override
  Future<void> dispose() async => disposeCount++;

  /// Install a new fake as the platform of the scanner, and give it back.
  static FakeMobileScannerPlatform install() {
    final platform = FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = platform;

    return platform;
  }
}
