// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

export 'package:barcode/barcode.dart' show BarcodeQRCorrectionLevel;
export 'package:mobile_scanner/mobile_scanner.dart'
    show
        Barcode,
        BarcodeCapture,
        BarcodeFormat,
        CameraFacing,
        DetectionSpeed,
        MobileScannerController,
        MobileScannerErrorCode,
        MobileScannerException,
        MobileScannerState,
        TorchState;

export 'src/types/barcode_scanner_status.dart';
export 'src/types/barcode_scanner_text.dart';
export 'src/ui/qr_code_widget.dart';
export 'src/ui/scanner/barcode_scanner_widget.dart';
