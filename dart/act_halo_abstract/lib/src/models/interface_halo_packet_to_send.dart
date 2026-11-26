// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

/// Useful interface for classes which have to send data to device
mixin InterfaceHaloPacketToSend {
  /// This method transforms the payload as a packet ready to be sent to the device.
  Uint8List getDataToSend();
}
