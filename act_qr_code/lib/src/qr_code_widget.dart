// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_music_player_manager/act_music_player_manager.dart';
import 'package:act_qr_code/src/qr_code_bloc.dart';
import 'package:act_qr_code/src/qr_code_event.dart';
import 'package:act_qr_code/src/qr_code_state.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

/// Validator is a function which takes a string and returns a bool
/// with true value if the string matches expected data.
typedef QrCodeReaderValidator = bool Function(String);

/// Feedback to parent goes through a function called with validated data
/// as argument.
typedef QrCodeReaderResult = void Function(String);

typedef PermissionButtonGen = RawMaterialButton Function({
  VoidCallback onPressed,
});

/// This class contains needed information for asking permissions to user
@immutable
class AskPermissionInfo {
  /// This function is called when the user hasn't the permissions to access
  /// camera and we display a message to the user
  final PermissionButtonGen permButton;

  /// This text is displayed to user when we need to ask him the permission
  final Text textAskingPermission;

  /// This text is displayed when the user has denied the usage of this
  /// permission
  final Text textWhenPermissionDenied;

  /// This is the space between the button and the text displayed to user
  final double spaceBetweenTextAndButton;

  const AskPermissionInfo({
    required this.permButton,
    required this.textAskingPermission,
    required this.textWhenPermissionDenied,
    this.spaceBetweenTextAndButton = 0,
  });
}

/// This squared widget scan QR (and other) codes.
///
/// Outlines
/// --------
/// User can provide a test function to filter wanted codes, and can receive
/// first matching one (or first one if unfiltered).
///
/// ```dart
/// QrCodeWidget(
///   size: 200,
///   validator: (String scanData) => scanData.isNotEmpty,
///   onDataFound: (String scanData) => setState(() {
///     _lastQrText = scanData;
///   }))
/// ```
///
/// Look and feel
/// -------------
/// When user is expected to scan a code: this widget show the rear camera video
/// and turn on flash light.
///
/// As soon a good scan data is detected: video stream is frozen, flash light is
/// turned off and a border added to the widget.
class QrCodeWidget extends StatefulWidget {
  /// Automatically turn flash on when user is expected to scan something.
  ///
  /// Flash is then turned off when wanted QR code has been read.
  /// If set to false, flash is left off all the time.
  final bool autoFlash;

  /// The validator used to filter wanted scan data.
  ///
  /// Any scan data is seen as good when no validator is provided.
  final QrCodeReaderValidator? validator;

  /// This function is used to send good scan event to parent
  final QrCodeReaderResult onDataFound;

  /// This key is used for flutter to not re-create a QRView for each frame
  /// but to update previously created one instead.
  ///
  /// If none is given through [QrCodeWidget] constructor, then
  /// [_QrCodeWidgetState] uses a hard-coded GlobalKey instead,
  /// making it impossible to insert two [QrCodeWidget] instances
  /// in a widget tree.
  final Key? qrGlobalKey;

  /// Explicit square size to use.
  ///
  /// Squared widget expends to its maximum possible square size when null.
  final double? size;

  /// If not null, this music is played on success
  final MusicSound? playedOnSuccess;

  /// If not null, this music is played when the QR Code isn't the right one
  final MusicSound? playedOnError;

  /// This is the border shape when the right QR code is discovered
  final double? borderShapeWhenDiscovered;

  final AskPermissionInfo askPermissionInfo;

  /// Create the squared QR code scanner.
  ///
  /// Providing [onDataFound] is needed to receive decoded QR code events. This
  /// widget would be useless without this feedback. You can also provide a
  /// [validator] to filter expected code among any others user may mistakenly
  /// scan. This way [onDataFound] as well as all other data-found feedbacks
  /// (camera freeze, etc) do not trigger for invalid scan data.
  ///
  /// An explicit square side size can be set through [size] argument.
  /// If not given, this squared widget will expand to fit parent widget
  /// available space.
  ///
  /// Inner [QRView] widget requires a key, in order to be instanciated only
  /// once (and moved between parents instead).
  /// You may want to provide a specific one through [qrGlobalKey], or (more
  /// likely) let it null so [QrCodeWidget] uses a default one. In the
  /// later case, inserting [QrCodeWidget] twice in a widget tree may
  /// not work as expected.
  const QrCodeWidget({
    super.key,
    this.validator,
    required this.onDataFound,
    required this.askPermissionInfo,
    this.autoFlash = false,
    this.size,
    this.qrGlobalKey,
    this.playedOnSuccess,
    this.playedOnError,
    this.borderShapeWhenDiscovered,
  });

  @override
  State<StatefulWidget> createState() => _QrCodeWidgetState();
}

class _QrCodeWidgetState extends State<QrCodeWidget> {
  /// Fancy name of the default QRView global key.
  ///
  /// QRView widget requires a key, hence we create one if no explicit one
  /// is given to us. This string is the nickname we give to the unique key
  /// we create ourselves when none is given, in order to help debug one day.
  /// This name does not impact key comparison, it only helps developers to
  /// understand things when he is debugging keys-related stuff.
  static const String _defaultQrKeyHint = "QRV-reader";

  /// QRView key actually used.
  ///
  /// It equals the key provided through [QrCodeWidget] constructor,
  /// defaulting to a hard-coded GlobalKey if not provided.
  late Key qrGlobalKey;

  /// QRView controller is used to control flash and to unsubscribe later.
  late QRViewController _qrController;

  /// Last unwanted scan data is kept in order to not insanely trigger "wrong
  /// QR code" feedbacks when user points an unwanted QR code.
  ///
  /// This is wanted since QRView announce detected codes very regularly when
  /// user is pointing a code (several times per second).
  String? _lastUnwantedScannedData;

  @override
  void initState() {
    qrGlobalKey = widget.qrGlobalKey ?? GlobalKey(debugLabel: _defaultQrKeyHint);
    super.initState();
  }

  /// This callback is called only once when QRView is ready to be used
  Future<void> onQrControllerReady(
    QRViewController controller,
    BuildContext context,
  ) async {
    _qrController = controller;
    final bloc = BlocProvider.of<QrCodeBloc>(context);

    // Controller should always be valid here, but stronger this way
    // Listen to data stream and validate it
    controller.scannedDataStream.listen((Barcode scanData) async {
      if (scanData.code == null) {
        return;
      }

      final code = scanData.code as String;
      if (widget.validator == null) {
        await onMatchedDataFound(bloc, code);
      } else {
        final validator = widget.validator as QrCodeReaderValidator;

        if (validator(code)) {
          await onMatchedDataFound(bloc, code);
        } else {
          await onWUnwantedDataFound(code);
        }
      }
    });

    if (widget.autoFlash) {
      // Turn flash on (its initial state is off).
      // Unfortunately QRViewController has no on and off methods.
      await _qrController.toggleFlash();
    }
  }

  /// Function called when a QR data matching expected one is found.
  ///
  /// It mainly froze camera image and send matching data back to parent.
  /// This function is not called many times since it pauses camera.
  Future<void> onMatchedDataFound(QrCodeBloc bloc, String scanData) async {
    await _qrController.pauseCamera();
    if (widget.autoFlash == true) {
      // Note to developers: Flash light is expected to be on here, hence
      // toggling it is expected to turn it off. Unfortunately, QRViewController
      // has no explicit on and off calls for the flash light.
      await _qrController.toggleFlash();
    }
    widget.onDataFound(scanData);

    bloc.add(const QrCodeFoundEvent(found: true));

    if (widget.playedOnSuccess != null) {
      await globalGetIt().get<MusicPlayerManager>().play(widget.playedOnSuccess!.value);
    }
  }

  /// Function called whenever a wrong QR code is scanned so user can have a
  /// specific feedback.
  Future<void> onWUnwantedDataFound(String scanData) async {
    // Note than QRView permanently tries to decode QR data and announces found
    // data each time it find something, even when this is the same as previous
    // computation.
    // We need to somehow unbounce those announcements to not send a huge amount
    // of feedbacks to users.

    // A finer-grain but more complicated solution would use a kind of smart
    // debouncer in order to re-trigger wrong QR code feedback if user attempts
    // to scan same unwanted QR code several times consecutively, but for now
    // this minimal anti-flood is OK.
    if (scanData != _lastUnwantedScannedData) {
      _lastUnwantedScannedData = scanData;

      if (widget.playedOnError != null) {
        await globalGetIt().get<MusicPlayerManager>().play(widget.playedOnError!.value);
      }
      // TODO(aloiseau): JMT would like a vibrator feedback too in the future
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  /// Helpful method to build the QrCode widget or a translated text when an
  /// error occurred
  Widget buildRightWidget({
    required BuildContext context,
    required double size,
    required QrCodeState state,
  }) {
    final themeData = Theme.of(context);

    if (state.permStatus != PermissionStatus.granted) {
      return Center(
        child: Column(
          children: [
            const Spacer(),
            (state.permStatus == null)
                ? widget.askPermissionInfo.textAskingPermission
                : widget.askPermissionInfo.textWhenPermissionDenied,
            SizedBox(
              height: widget.askPermissionInfo.spaceBetweenTextAndButton,
            ),
            widget.askPermissionInfo.permButton(
              onPressed: AppSettings.openAppSettings,
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return QRView(
      key: qrGlobalKey,
      onQRViewCreated: (QRViewController controller) async => onQrControllerReady(
        controller,
        context,
      ),
      overlay: (state.found &&
              widget.borderShapeWhenDiscovered != null &&
              (widget.borderShapeWhenDiscovered ?? 0) > 0)
          ? QrScannerOverlayShape(
              borderColor: themeData.primaryColor,
              borderWidth: widget.borderShapeWhenDiscovered ?? 0,
              // Half side length since those are actually corner borders
              // which join themselves
              borderLength: size / 2,
              cutOutSize: size,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider<QrCodeBloc>(
        create: (context) => QrCodeBloc(),
        child: BlocBuilder<QrCodeBloc, QrCodeState>(
          builder: (BuildContext blocContext, QrCodeState state) => LayoutBuilder(
            builder: (BuildContext layoutContext, BoxConstraints constraints) {
              // We take the biggest size that satisfies the constraints and the
              // shortest size, in order to fill parent
              final size = widget.size ?? constraints.biggest.shortestSide;

              return SizedBox(
                width: size, // auto-extends if null
                height: size, // auto-extends if null
                child: AspectRatio(
                  aspectRatio: 1,
                  child: buildRightWidget(
                    context: layoutContext,
                    size: size,
                    state: state,
                  ),
                ),
              );
            },
          ),
        ),
      );
}
