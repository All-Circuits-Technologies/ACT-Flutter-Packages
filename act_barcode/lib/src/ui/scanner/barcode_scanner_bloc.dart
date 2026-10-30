// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_barcode/src/ui/scanner/barcode_scanner_event.dart';
import 'package:act_barcode/src/ui/scanner/barcode_scanner_state.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Hold the status of the barcode scanner, from the camera permission to the camera.
///
/// The bloc owns the controller lifecycle: it creates the controller when the application gives
/// none, and disposes it in that case only.
class BarcodeScannerBloc extends BlocForMixin<BarcodeScannerState>
    with MixinAsyncInitBloc<BarcodeScannerState> {
  /// Name the category of the logs of the bloc.
  static const _loggerCategory = "barcode_scanner";

  /// Log what goes wrong, without breaking the scanner.
  final LogsHelper _logsHelper;

  /// Hold the controller of the scanner, whose value gives the status of the camera.
  final MobileScannerController _controller;

  /// Tell whether the bloc created the controller, and has to dispose it.
  final bool _ownsController;

  /// Hold the service which checks and asks the camera permission.
  ///
  /// It's null when the platform is unsupported.
  final PermissionMonitorService? _monitor;

  /// Transmit to [PermissionMonitorService.verifyAndAskBeforeAction].
  final bool _displayContextualIfNeeded;

  /// Transmit to [PermissionMonitorService.verifyAndAskBeforeAction].
  final bool _isAcceptanceCompulsory;

  /// Hold the subscription to the changes of the camera permission.
  ///
  /// It's null when the platform is unsupported.
  late final StreamSubscription<bool>? _permissionSub;

  /// Give the controller of the scanner, which the camera view displays.
  MobileScannerController get controller => _controller;

  /// Create the bloc.
  ///
  /// When the application gives no [controller], the bloc creates one and disposes it.
  BarcodeScannerBloc({
    MobileScannerController? controller,
    bool displayContextualIfNeeded = true,
    bool isAcceptanceCompulsory = false,
  }) : _logsHelper = LogsHelper(category: _loggerCategory),
       _controller = controller ?? MobileScannerController(),
       _ownsController = controller == null,
       _monitor = _createMonitor(),
       _displayContextualIfNeeded = displayContextualIfNeeded,
       _isAcceptanceCompulsory = isAcceptanceCompulsory,
       super(const BarcodeScannerState.init());

  /// {@macro act_flutter_utility.BlocForMixin.registerMixinEvents}
  @override
  void registerMixinEvents() {
    super.registerMixinEvents();

    on<BarcodeScannerAskPermissionEvent>(_onAskPermissionEvent);
    on<BarcodeScannerPermissionEvent>(_onPermissionEvent);
    on<BarcodeScannerControllerEvent>(_onControllerEvent);

    _permissionSub = _monitor?.hasPermissionStream.listen(
      (isGranted) => add(BarcodeScannerPermissionEvent(isGranted: isGranted)),
    );
    _controller.addListener(_onControllerChanged);
  }

  /// {@macro act_flutter_utility.MixinAsyncInitBloc.initAsyncBloc}
  ///
  /// It emits the first status: `unsupported`, or `waitingPermission` followed by the result of
  /// the permission request.
  @override
  Future<void> initAsyncBloc({required Emitter<BarcodeScannerState> emit}) async {
    await super.initAsyncBloc(emit: emit);

    if (_monitor == null) {
      emit.call(state.copyToUnsupportedState());
      return;
    }

    await _askPermission(emit);
  }

  /// Called when the [event] asks the camera permission again.
  Future<void> _onAskPermissionEvent(
    BarcodeScannerAskPermissionEvent event,
    Emitter<BarcodeScannerState> emit,
  ) async {
    await _askPermission(emit);
  }

  /// Called when the [event] tells that the camera permission changed.
  Future<void> _onPermissionEvent(
    BarcodeScannerPermissionEvent event,
    Emitter<BarcodeScannerState> emit,
  ) async {
    _updateWithPermission(emit, isGranted: event.isGranted);
  }

  /// Called when the [event] tells that the state of the controller changed.
  Future<void> _onControllerEvent(
    BarcodeScannerControllerEvent event,
    Emitter<BarcodeScannerState> emit,
  ) async {
    if (!state.isCameraStatus) {
      // The permission isn't granted: the camera isn't ours to follow
      return;
    }

    emit.call(state.copyWithControllerState(controllerState: event.controllerState));
  }

  /// Check, and ask if needed, the camera permission, then update the status with the answer.
  Future<void> _askPermission(Emitter<BarcodeScannerState> emit) async {
    final monitor = _monitor;

    if (monitor == null) {
      return;
    }

    emit.call(state.copyToWaitingPermissionState());

    final isGranted = await monitor.verifyAndAskBeforeAction(
      displayContextualIfNeeded: _displayContextualIfNeeded,
      isAcceptanceCompulsory: _isAcceptanceCompulsory,
    );

    _updateWithPermission(emit, isGranted: isGranted);
  }

  /// Update the status from the camera permission.
  void _updateWithPermission(Emitter<BarcodeScannerState> emit, {required bool isGranted}) {
    if (!isGranted) {
      emit.call(state.copyToPermissionDeniedState());
      return;
    }

    if (state.isCameraStatus) {
      // Already following the camera
      return;
    }

    emit.call(state.copyWithGrantedPermission(controllerState: _controller.value));
  }

  /// Called when the value of the controller changes.
  void _onControllerChanged() {
    add(BarcodeScannerControllerEvent(controllerState: _controller.value));
  }

  /// Create the service which asks the camera permission, unless the platform is unsupported.
  static PermissionMonitorService? _createMonitor() {
    PermissionMonitorService? monitor;

    if (!_isPlatformUnsupported()) {
      monitor = PermissionMonitorService.monitorService(
        permissionsManager: globalGetIt().get<PermissionsManager>(),
        permissionElement: PermissionElement.camera,
      );
    }

    return monitor;
  }

  /// Tell whether the camera can't be read on the platform.
  static bool _isPlatformUnsupported() {
    final platform = globalGetIt().get<PlatformManager>();

    return platform.isLinux || platform.isWindows || platform.isFuchsia;
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  ///
  /// It stops following the permission and the controller, closes the permission service and
  /// disposes the controller if the bloc created it.
  @override
  Future<void> disposeLifeCycle() async {
    await _permissionSub?.cancel();
    _controller.removeListener(_onControllerChanged);
    await _monitor?.close();

    if (_ownsController) {
      try {
        await _controller.dispose();
      } catch (error) {
        _logsHelper.e("The scanner controller failed to be disposed: $error");
      }
    }

    return super.disposeLifeCycle();
  }
}
