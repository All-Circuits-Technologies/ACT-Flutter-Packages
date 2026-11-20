// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_barcode/src/types/qr_code_data_wifi_security.dart';
import 'package:act_global_manager/act_global_manager.dart';

/// Utility class for generating barcode content, including Wi-Fi QR code data.
sealed class BarcodeContentUtilities {
  /// The characters which must be escaped with a backslash in the fields of a Wi-Fi QR code.
  static final _wifiSpecialCharacters = RegExp(r'[\\;,":]');

  /// Generates the content of a QR code that a phone scans to join a Wi-Fi network.
  ///
  /// The content has the form `WIFI:T:<type>;S:<ssid>;P:<password>;;`, with `H:true;` before the
  /// end for a [hidden] network. The special characters of the [ssid] and the [password] (`\`,
  /// `;`, `,`, `"` and `:`) are escaped with a backslash.
  ///
  /// [password] is the Wi-Fi network password, which can be null or empty for open networks: an
  /// open network has no password field, whatever the requested [security].
  ///
  /// Returns the generated Wi-Fi QR code content as a string.
  static String generateWifiQrCodeData({
    required String ssid,
    required QrCodeDataWifiSecurity security,
    required String? password,
    bool hidden = false,
  }) {
    var tmpSecurity = security;
    if (password == null || password.isEmpty) {
      if (security != QrCodeDataWifiSecurity.none) {
        appLogger().w("Password is empty or null, setting security to none.");
      }

      tmpSecurity = QrCodeDataWifiSecurity.none;
    }

    final content = StringBuffer("WIFI:")
      ..write("T:${tmpSecurity.stringValue};")
      ..write("S:${_escapeWifiField(ssid)};");

    if (tmpSecurity != QrCodeDataWifiSecurity.none && password != null) {
      content.write("P:${_escapeWifiField(password)};");
    }

    if (hidden) {
      content.write("H:true;");
    }

    content.write(";");

    return content.toString();
  }

  /// Escapes the special characters of a field of a Wi-Fi QR code with a backslash.
  static String _escapeWifiField(String value) =>
      value.replaceAllMapped(_wifiSpecialCharacters, (match) => "\\${match[0]}");
}
