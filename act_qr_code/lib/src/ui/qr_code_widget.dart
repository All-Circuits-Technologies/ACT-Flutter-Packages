// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Widget to display a QR code image based on the provided text and size.
class QrCodeImage extends StatefulWidget {
  /// The text to encode in the QR code.
  final String text;

  /// The color of the QR code.
  final Color color;

  /// The size of the QR code image.
  final double size;

  /// The error correction level for the QR code.
  ///
  /// The error correction level determines how much of the QR code can be restored if it is
  /// damaged or obscured. The higher the level, the more data can be restored, but the QR code will
  /// be larger and more complex. The default is [BarcodeQRCorrectionLevel.low].
  final BarcodeQRCorrectionLevel errorCorrectLevel;

  /// The barcode generator for QR codes.
  final Barcode _barcode;

  /// Class constructor
  QrCodeImage({
    super.key,
    required this.text,
    required this.color,
    required this.size,
    this.errorCorrectLevel = BarcodeQRCorrectionLevel.low,
  }) : _barcode = Barcode.qrCode(errorCorrectLevel: errorCorrectLevel);

  /// This widget is stateful because the QR code generation can be computationally expensive, and
  /// we want to avoid regenerating it unnecessarily if the text or size does not change.
  @override
  State<StatefulWidget> createState() => _QrCodeImageState();
}

/// The state of the [QrCodeImage] widget, responsible for generating and caching the QR code SVG.
class _QrCodeImageState extends State<QrCodeImage> {
  /// Cache the generated SVG to avoid regenerating it on every build if the text and color do not
  /// change.
  String? _cachedSvg;

  /// Init the state and generate the initial SVG for the QR code.
  @override
  void initState() {
    super.initState();
    _generateSvg();
  }

  /// If the widget is updated with new text, size, or color, we need to regenerate the QR code SVG.
  @override
  void didUpdateWidget(covariant QrCodeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the text, size or color changes, we need to regenerate the QR code
    if (oldWidget.text != widget.text ||
        oldWidget.color != widget.color ||
        oldWidget.size != widget.size ||
        oldWidget.errorCorrectLevel != widget.errorCorrectLevel) {
      setState(() {
        if (oldWidget.text != widget.text ||
            oldWidget.color != widget.color ||
            oldWidget.errorCorrectLevel != widget.errorCorrectLevel) {
          // If the text, color or error correct level changes, we need to regenerate the SVG and
          // update the cache
          //
          // We don't need to regenerate the SVG if only the size changes
          _generateSvg();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_cachedSvg!, width: widget.size, height: widget.size);

  /// Generate the SVG for the QR code based on the current text, size, and color. This method
  /// updates the [_cachedSvg] variable with the generated SVG string.
  void _generateSvg() {
    _cachedSvg = widget._barcode.toSvg(
      widget.text,
      width: widget.size,
      height: widget.size,
      color: widget.color.toARGB32(),
    );
  }
}
