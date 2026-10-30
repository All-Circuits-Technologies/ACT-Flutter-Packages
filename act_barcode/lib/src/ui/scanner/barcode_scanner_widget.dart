// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math';

import 'package:act_barcode/src/types/barcode_scanner_status.dart';
import 'package:act_barcode/src/types/barcode_scanner_text.dart';
import 'package:act_barcode/src/ui/scanner/barcode_scanner_bloc.dart';
import 'package:act_barcode/src/ui/scanner/barcode_scanner_event.dart';
import 'package:act_barcode/src/ui/scanner/barcode_scanner_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Display what the camera sees and hand over every barcode it reads.
///
/// The widget is built on `mobile_scanner`, which reads all the usual formats (QR codes, linear
/// barcodes, ...). The reading is continuous: the application stops, pauses or starts the camera
/// again, and lights the flash, through a [MobileScannerController].
///
/// ## Camera permission
///
/// The camera permission is asked through `act_permissions_manager`, as soon as the widget is
/// displayed. The pages the application registered to explain the permission are displayed first,
/// unless [displayContextualIfNeeded] is `false`. The widget reads the `PlatformManager`, the
/// `AppLifeCycleManager` and the `PermissionsManager` from the global manager of the application,
/// so these three have to be registered. The permission is followed afterwards: one granted in the
/// settings starts a denied scanner, and one withdrawn denies a running scanner.
///
/// ## Statuses
///
/// The widget goes through the [BarcodeScannerStatus] values, which [onStatusChanged] reports, and
/// shows:
///
/// - [BarcodeScannerStatus.unsupported]: the text [BarcodeScannerText.unsupportedPlatform], on
///   Linux, Windows and Fuchsia;
/// - [BarcodeScannerStatus.waitingPermission]: the text [BarcodeScannerText.waitingPermission];
/// - [BarcodeScannerStatus.permissionDenied]: the text [BarcodeScannerText.permissionDenied] and a
///   button, labeled [BarcodeScannerText.askPermissionButton], which asks the permission again;
/// - [BarcodeScannerStatus.starting], [BarcodeScannerStatus.scanning] and
///   [BarcodeScannerStatus.stopped]: the camera view, with its frame and the [overlayBuilder];
/// - [BarcodeScannerStatus.error]: the text [BarcodeScannerText.cameraError] in place of the camera
///   view.
///
/// ## Size
///
/// - without [width] nor [height], the widget is a square whose side is the smallest side of the
///   space available;
/// - with only one of them, the other side takes the space available in its direction;
/// - with both, the widget has these dimensions.
///
/// ## Controller
///
/// Without [controller], the widget creates a `MobileScannerController()` without any format
/// filter, which reads all the formats, and disposes it with the widget. An application which
/// restricts the formats (`MobileScannerController(formats: ...)`) or drives the camera gives its
/// own controller: it keeps its ownership, and the widget never disposes it. The controller is read
/// when the widget is first displayed: giving another one later has no effect.
///
/// ## Codes
///
/// Every barcode of a capture which has neither a value nor bytes is ignored. The others are given
/// to [validator], and those it accepts reach [onCodeFound]; without validator, all of them do.
class BarcodeScannerWidget extends StatelessWidget {
  /// Give the translated text of each message of the widget.
  final String Function(BuildContext context, BarcodeScannerText text) textGetter;

  /// Call for each barcode read which the [validator] accepts.
  final void Function(Barcode barcode) onCodeFound;

  /// Filter the barcodes read: only those it returns `true` for reach [onCodeFound].
  ///
  /// When null, all the barcodes are accepted.
  final bool Function(Barcode barcode)? validator;

  /// Give the controller of the application, which drives the camera.
  ///
  /// When null, the widget creates a controller which reads all the formats, and disposes it. A
  /// controller given by the application is never disposed by the widget.
  final MobileScannerController? controller;

  /// Set the width of the widget.
  ///
  /// When null, the width depends on [height], see the class documentation for the size.
  final double? width;

  /// Set the height of the widget.
  ///
  /// When null, the height depends on [width], see the class documentation for the size.
  final double? height;

  /// Tell how the camera view fits the widget, as `MobileScanner` does.
  final BoxFit fit;

  /// Set the color of the frame around the camera view.
  ///
  /// When null, the primary color of the theme is used.
  final Color? frameColor;

  /// Set the width of the frame around the camera view; with `0` the frame is hidden.
  final double frameWidth;

  /// Set the radius of the corners of the frame and of the camera view.
  final double frameRadius;

  /// Draw over the camera view, with the current status.
  ///
  /// It's called only while the camera view is displayed, see [BarcodeScannerStatus]. When null,
  /// nothing is drawn over the camera view.
  final Widget Function(BuildContext context, BarcodeScannerStatus status)? overlayBuilder;

  /// Call at each change of the status, the first status included.
  final void Function(BarcodeScannerStatus status)? onStatusChanged;

  /// Tell whether the pages of the application explain the camera permission before it is asked.
  ///
  /// It's transmitted to `PermissionMonitorService.verifyAndAskBeforeAction`. An application which
  /// has registered no page for the camera passes `false`: the permission is then asked of the
  /// device directly, and a permanent refusal opens the settings.
  final bool displayContextualIfNeeded;

  /// Tell whether the user has to accept the camera permission.
  ///
  /// It's transmitted to `PermissionMonitorService.verifyAndAskBeforeAction`.
  final bool isAcceptanceCompulsory;

  /// Create the scanner.
  const BarcodeScannerWidget({
    required this.textGetter,
    required this.onCodeFound,
    this.validator,
    this.controller,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.frameColor,
    this.frameWidth = 2,
    this.frameRadius = 0,
    this.overlayBuilder,
    this.onStatusChanged,
    this.displayContextualIfNeeded = true,
    this.isAcceptanceCompulsory = false,
    super.key,
  });

  /// Build the widget, whose bloc owns the camera permission and the controller.
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => BarcodeScannerBloc(
      controller: controller,
      displayContextualIfNeeded: displayContextualIfNeeded,
      isAcceptanceCompulsory: isAcceptanceCompulsory,
    ),
    child: _BarcodeScannerWidgetView(scanner: this),
  );
}

/// Render the [BarcodeScannerWidget], from the status of its bloc.
class _BarcodeScannerWidgetView extends StatelessWidget {
  /// Hold the widget which gives the parameters and the callbacks to use.
  final BarcodeScannerWidget scanner;

  /// Create the view.
  const _BarcodeScannerWidgetView({required this.scanner});

  /// Build the sized content, which follows the status of the bloc.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fallback = MediaQuery.sizeOf(context).shortestSide;
      final finite = [constraints.maxWidth, constraints.maxHeight].where((size) => size.isFinite);
      final double width;
      final double height;

      if (scanner.width == null && scanner.height == null) {
        width = height = finite.isEmpty ? fallback : finite.reduce(min);
      } else {
        width = scanner.width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : fallback);
        height =
            scanner.height ?? (constraints.maxHeight.isFinite ? constraints.maxHeight : fallback);
      }

      return SizedBox(
        width: width,
        height: height,
        child: BlocListener<BarcodeScannerBloc, BarcodeScannerState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            final status = state.status;

            if (status != null) {
              scanner.onStatusChanged?.call(status);
            }
          },
          child: BlocBuilder<BarcodeScannerBloc, BarcodeScannerState>(
            builder: (context, state) => switch (state.status) {
              null || BarcodeScannerStatus.waitingPermission => _ScannerText(
                textGetter: scanner.textGetter,
                text: BarcodeScannerText.waitingPermission,
              ),
              BarcodeScannerStatus.unsupported => _ScannerText(
                textGetter: scanner.textGetter,
                text: BarcodeScannerText.unsupportedPlatform,
              ),
              BarcodeScannerStatus.permissionDenied => _PermissionDenied(
                textGetter: scanner.textGetter,
              ),
              final BarcodeScannerStatus status => _CameraView(
                scanner: scanner,
                controller: context.read<BarcodeScannerBloc>().controller,
                status: status,
                onDetect: _onDetect,
              ),
            },
          ),
        ),
      );
    },
  );

  /// Give the barcodes read to the application, if they are accepted.
  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue == null && barcode.rawDecodedBytes == null) {
        continue;
      }

      if (!(scanner.validator?.call(barcode) ?? true)) {
        continue;
      }

      scanner.onCodeFound(barcode);
    }
  }
}

/// Display a message of the scanner, centered.
class _ScannerText extends StatelessWidget {
  /// Give the translated text of the [text].
  final String Function(BuildContext context, BarcodeScannerText text) textGetter;

  /// Name the message to display.
  final BarcodeScannerText text;

  /// Create the centered message.
  const _ScannerText({required this.textGetter, required this.text});

  /// Build the centered text.
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(textGetter(context, text), textAlign: TextAlign.center));
}

/// Display that the camera permission is denied, with a button to ask it again.
class _PermissionDenied extends StatelessWidget {
  /// Give the translated text of each message.
  final String Function(BuildContext context, BarcodeScannerText text) textGetter;

  /// Create the message and its button.
  const _PermissionDenied({required this.textGetter});

  /// Build the message and the button which asks the permission again.
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(textGetter(context, BarcodeScannerText.permissionDenied), textAlign: TextAlign.center),
        TextButton(
          onPressed: () =>
              context.read<BarcodeScannerBloc>().add(const BarcodeScannerAskPermissionEvent()),
          child: Text(textGetter(context, BarcodeScannerText.askPermissionButton)),
        ),
      ],
    ),
  );
}

/// Display the camera view, with its frame and the overlay of the application.
class _CameraView extends StatelessWidget {
  /// Hold the widget which gives the frame, the fit and the overlay.
  final BarcodeScannerWidget scanner;

  /// Hold the controller which drives the camera.
  final MobileScannerController controller;

  /// Hold the current status, given to the overlay.
  final BarcodeScannerStatus status;

  /// Call when the camera reads barcodes.
  final void Function(BarcodeCapture capture) onDetect;

  /// Create the camera view.
  const _CameraView({
    required this.scanner,
    required this.controller,
    required this.status,
    required this.onDetect,
  });

  /// Build the camera view, framed, with the overlay over it.
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(scanner.frameRadius);
    final overlay = scanner.overlayBuilder?.call(context, status);

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: scanner.frameWidth > 0
            ? Border.all(
                color: scanner.frameColor ?? Theme.of(context).colorScheme.primary,
                width: scanner.frameWidth,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              fit: scanner.fit,
              onDetect: onDetect,
              errorBuilder: (context, error) => _ScannerText(
                textGetter: scanner.textGetter,
                text: BarcodeScannerText.cameraError,
              ),
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}
