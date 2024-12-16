// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';

/// Represents the payload packet element (the elements between the
/// [HaloPacketUtility._elementSeparator]), the bytes contains in it are escaped
typedef PayloadPacketElem = Uint8List;

/// Represents the final packet to exchange with the [HaloPacketUtility._startByte] and the
/// [HaloPacketUtility._endByte]
typedef PayloadPacket = Uint8List;

/// This class is helpful to manage the exchanged HALO packets
abstract class HaloPacketUtility {
  /// This is the start byte of each payload packets which are exchanged
  static const int _startByte = 0xC0;

  /// This is the end byte of each payload packets which are exchanged
  static const int _endByte = 0xC1;

  /// This byte is used to separate the data timestamp from its value
  static const int _tsSeparator = 0x3A;

  /// This byte is used to separate the different values of a data
  static const int _elementSeparator = 0x7C;

  /// When this byte is present, it marks a byte which has been escaped
  static const int _escapeElement = 0x7D;

  /// This byte is used to mask a byte which has the same value as the previous bytes
  static const int _escapeMask = 0x20;

  /// Represents the size of a data timestamp
  static const _tsBytesNb = ByteUtility.bytesNbUInt32;

  /// Represents the expected true value for a byte
  static const int _trueValue = 0x01;

  /// Represents the expected false value for a byte
  static const int _falseValue = 0x00;

  /// List all the bytes which needs to be escaped in the final packets exchanged
  static final List<int> _forbiddenElems = [
    HaloPacketUtility._startByte,
    HaloPacketUtility._endByte,
    HaloPacketUtility._tsSeparator,
    HaloPacketUtility._elementSeparator,
    HaloPacketUtility._escapeElement,
  ];

  /// Format the [escapedDataToSend] to a [PayloadPacket] and then cuts it to create packets which
  /// respects the [maxPacketSize] given.
  /// If [maxPacketSize] is equals to -1, the list returned will only have one element.
  static List<Uint8List> formatPackets({
    required List<PayloadPacketElem> escapedDataToSend,
    int maxPacketSize = -1,
  }) {
    final dataLength = escapedDataToSend.length;
    if (dataLength == 0) {
      return const <Uint8List>[];
    }

    final packets = <Uint8List>[];

    // We add all the elements to send in the main packet
    final temporary = [HaloPacketUtility._startByte];
    for (var idx = 0; idx < dataLength; ++idx) {
      temporary.addAll(escapedDataToSend[idx]);

      if (idx < (dataLength - 1)) {
        temporary.add(HaloPacketUtility._elementSeparator);
      }
    }

    temporary.add(HaloPacketUtility._endByte);

    int packetSize, packetNb;

    if (maxPacketSize > 0) {
      packetSize = maxPacketSize;
      packetNb = (temporary.length / packetSize).ceil();
    } else {
      packetSize = temporary.length;
      packetNb = 1;
    }

    for (var idxPacket = 0; idxPacket < packetNb; ++idxPacket) {
      int? end;

      if (idxPacket < (packetNb - 1)) {
        // Not the last packet
        end = packetSize * (idxPacket + 1);
      }

      packets.add(Uint8List.fromList(temporary.sublist(idxPacket * packetSize, end)));
    }

    return packets;
  }

  /// Extract a list of payload packet element from a [payloadPacket] received from Device
  static List<PayloadPacketElem>? extractFromPayloadPacket(Uint8List payloadPacket) {
    if (payloadPacket.isEmpty) {
      appLogger().w("The HALO payload packet is empty, nothing can't be extracted");
      return null;
    }

    final payloadLength = payloadPacket.length;

    if (payloadPacket[0] != HaloPacketUtility._startByte ||
        payloadPacket[payloadLength - 1] != HaloPacketUtility._endByte) {
      appLogger().w("The HALO payload packet received isn't complete, we haven't the start and/or "
          "end byte");
      return null;
    }

    final elements = <PayloadPacketElem>[];
    if (payloadLength == 2) {
      // That means that the packet is empty
      return elements;
    }

    var elemIdx = 1;
    for (var idx = 1; idx < (payloadLength - 1); ++idx) {
      if (payloadPacket[idx] == HaloPacketUtility._elementSeparator) {
        elements.add(Uint8List.fromList(payloadPacket.sublist(elemIdx, idx)));
        // The new elem index is after this element separator
        elemIdx = idx + 1;
      }
    }

    // We add the last element after the separator (or the first if there were no separator)
    elements.add(Uint8List.fromList(payloadPacket.sublist(elemIdx, (payloadLength - 1))));

    return elements;
  }

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [toSend] String given and the optional [ts] DateTime
  static PayloadPacketElem formatString(
    String toSend, {
    DateTime? ts,
  }) =>
      _formatAndEscapePacketElem(Uint8List.fromList(toSend.codeUnits), ts);

  /// Parse the [element] given to extract a string, and the optional DateTime if it's present
  static (String, DateTime?)? getString(PayloadPacketElem element) {
    final tmp = _extractDataFromPacketElem(element);

    if (tmp == null) {
      appLogger().w("A problem occurred when tried to get the string representation from a payload "
          "packet element");
      return null;
    }

    final (data, ts) = tmp;

    return (String.fromCharCodes(data), ts);
  }

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [toSend] boolean given and the optional [ts] DateTime
  static PayloadPacketElem formatBoolean(
    bool toSend, {
    DateTime? ts,
  }) {
    final tmp = Uint8List(1);
    tmp[0] = toSend ? HaloPacketUtility._trueValue : HaloPacketUtility._falseValue;

    return _formatAndEscapePacketElem(tmp, ts);
  }

  /// Parse the [element] given to extract a boolean, and the optional DateTime if it's present
  static (bool, DateTime?)? getBoolean(PayloadPacketElem element) {
    final tmp = _extractDataFromPacketElem(element);

    if (tmp == null) {
      appLogger().w("A problem occurred when tried to get the boolean representation from a "
          "payload packet element");
      return null;
    }

    final (data, ts) = tmp;

    if (data.isEmpty) {
      appLogger().w("We can't get a boolean from an empty payload packet element");
      return null;
    }

    return (data[0] == HaloPacketUtility._trueValue, ts);
  }

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [number] unsigned integer of 8bits given and the optional [ts] DateTime
  ///
  /// Returns null if a problem occurred in the process (for instance if the [number] given
  /// overflows the expected integer size)
  static PayloadPacketElem? formatUInt8(
    int number, {
    DateTime? ts,
  }) =>
      HaloPacketUtility._formatNumber(number, ByteUtility.bytesNbUInt8, false, ts: ts);

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [number] unsigned integer of 16bits given and the optional [ts] DateTime
  ///
  /// Returns null if a problem occurred in the process (for instance if the [number] given
  /// overflows the expected integer size)
  static PayloadPacketElem? formatUInt16(
    int number, {
    DateTime? ts,
  }) =>
      HaloPacketUtility._formatNumber(number, ByteUtility.bytesNbUInt16, false, ts: ts);

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [number] unsigned integer of 32bits given and the optional [ts] DateTime
  ///
  /// Returns null if a problem occurred in the process (for instance if the [number] given
  /// overflows the expected integer size)
  static PayloadPacketElem? formatUInt32(
    int number, {
    DateTime? ts,
  }) =>
      HaloPacketUtility._formatNumber(number, ByteUtility.bytesNbUInt32, false, ts: ts);

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [number] signed integer of 8bits given and the optional [ts] DateTime
  ///
  /// Returns null if a problem occurred in the process (for instance if the [number] given
  /// overflows the expected integer size)
  static PayloadPacketElem? formatInt8(
    int number, {
    DateTime? ts,
  }) =>
      HaloPacketUtility._formatNumber(number, ByteUtility.bytesNbUInt8, true, ts: ts);

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [number] signed integer of 16bits given and the optional [ts] DateTime
  ///
  /// Returns null if a problem occurred in the process (for instance if the [number] given
  /// overflows the expected integer size)
  static PayloadPacketElem? formatInt16(
    int number, {
    DateTime? ts,
  }) =>
      HaloPacketUtility._formatNumber(number, ByteUtility.bytesNbUInt16, true, ts: ts);

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [number] signed integer of 32bits given and the optional [ts] DateTime
  ///
  /// Returns null if a problem occurred in the process (for instance if the [number] given
  /// overflows the expected integer size)
  static PayloadPacketElem? formatInt32(
    int number, {
    DateTime? ts,
  }) =>
      HaloPacketUtility._formatNumber(number, ByteUtility.bytesNbUInt32, true, ts: ts);

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [number] signed integer of 64bits given and the optional [ts] DateTime
  ///
  /// Returns null if a problem occurred in the process (for instance if the [number] given
  /// overflows the expected integer size)
  static PayloadPacketElem? formatInt64(
    int number, {
    DateTime? ts,
  }) =>
      HaloPacketUtility._formatNumber(number, ByteUtility.bytesNbUInt64, true, ts: ts);

  /// Format a [PayloadPacketElem] (with the needed escaped bytes and the timestamp prepend) from
  /// the [number] given and the optional [ts] DateTime.
  /// The [bytesNb] gives the number of the expected bytes in the [number] given and [isSigned] says
  /// if the [number] contains a signed number or not.
  ///
  /// Returns null if a problem occurred in the process (for instance if the [number] given
  /// overflows the expected integer size)
  static PayloadPacketElem? _formatNumber(
    int number,
    int bytesNb,
    bool isSigned, {
    DateTime? ts,
  }) {
    final tmp = ByteUtility.convertToLsbFirst(
      number: number,
      bytesNb: bytesNb,
      isSigned: isSigned,
    );

    if (tmp == null) {
      appLogger().w("A problem occurred when tried to convert the number: $number to LSB, with "
          "bytes number: $bytesNb, and is it signed ? $isSigned");
      return null;
    }

    return _formatAndEscapePacketElem(tmp, ts);
  }

  /// Parse the [element] given to extract an integer, and the optional DateTime if it's present
  /// [isSigned] is useful to know if the number you want to get is signed or not
  static (int, DateTime?)? getNumber(PayloadPacketElem element, bool isSigned) {
    final tmp = _extractDataFromPacketElem(element);

    if (tmp == null) {
      appLogger().w("A problem occurred when tried to get the number representation from a "
          "payload packet element");
      return null;
    }

    final (data, ts) = tmp;

    final value = ByteUtility.convertFromLsb(lsbNumber: data, isSigned: isSigned);

    if (value == null) {
      appLogger().w("A problem occurred when tried to convert the byte list to a number");
      return null;
    }

    return (value, ts);
  }

  /// Format and escape bytes list to create a [PayloadPacketElement], the method also prepend the
  /// [timestamp] if not null
  static PayloadPacketElem _formatAndEscapePacketElem(Uint8List element, DateTime? timestamp) {
    var tmp = Uint8List.fromList(element);
    tmp = _escapeGivenElementIfNeeded(tmp);

    if (timestamp != null) {
      // This won't crash until 2106
      var formattedTs = ByteUtility.unsafeConvertToLsbFirst(
        number: (timestamp.millisecondsSinceEpoch / 1000).round(),
        bytesNb: HaloPacketUtility._tsBytesNb,
        isSigned: false,
      );

      formattedTs = _escapeGivenElementIfNeeded(formattedTs);

      formattedTs.add(HaloPacketUtility._tsSeparator);

      // Insert the timestamp before
      tmp.insertAll(0, formattedTs);
    }

    return tmp;
  }

  /// This method escapes the bytes of the list given if needed
  /// It also adds the escape byte in the list given before the escaped byte (it modifies the given
  /// list)
  static Uint8List _escapeGivenElementIfNeeded(Uint8List toEscape) {
    final tmp = toEscape.toList();
    for (var idx = (tmp.length - 1); idx >= 0; --idx) {
      final value = tmp[idx];
      if (_forbiddenElems.contains(value)) {
        tmp[idx] = value ^ HaloPacketUtility._escapeMask;
        tmp.insert(idx, HaloPacketUtility._escapeElement);
      }
    }

    return Uint8List.fromList(toEscape);
  }

  /// This method unescape the given element to remove all the escape byte and convert back all the
  /// escaped byte
  /// The method returns null if a problem occurred in the process
  static Uint8List? _unescapeGivenElementIfNeeded(Uint8List toUnescape) {
    final tmp = toUnescape.toList();

    for (var idx = 0; idx < tmp.length; ++idx) {
      final value = tmp[idx];
      if (value == HaloPacketUtility._escapeElement) {
        if (idx == (tmp.length - 1)) {
          // This case should never happen (it means that the packet hasn't well formatted
          appLogger().w("There is an escape character at the end of a payload element, this case "
              "should never happen, but it happened.");
          return null;
        }

        final nextValue = tmp[idx + 1];
        tmp[idx] = nextValue ^ HaloPacketUtility._escapeMask;
        tmp.removeAt(idx + 1);
      }
    }

    return Uint8List.fromList(tmp);
  }

  /// The method extract the data from packet element: it extracts the datetime and the value, and
  /// also unescape both before returning the values.
  static (Uint8List, DateTime?)? _extractDataFromPacketElem(PayloadPacketElem element) {
    var tmpElement = PayloadPacketElem.fromList(element);
    DateTime? ts;

    final tsSepIndex = element.indexOf(HaloPacketUtility._tsSeparator);
    if (tsSepIndex >= 0) {
      // We have a timestamp to extract
      final tmpTs = _unescapeGivenElementIfNeeded(element.sublist(0, tsSepIndex));
      if (tmpTs == null) {
        appLogger().w("A problem occurred when tried to unescape a timestamp from a payload packet "
            "element");
        return null;
      }

      final tsInMS = ByteUtility.unsafeConvertFromLsb(lsbNumber: tmpTs, isSigned: false);
      ts = DateTime.fromMillisecondsSinceEpoch(tsInMS, isUtc: true);

      // Remove the ts from the temporary element
      tmpElement = element.sublist(tsSepIndex + 1);
    }

    final unTmpElem = _unescapeGivenElementIfNeeded(tmpElement);

    if (unTmpElem == null) {
      appLogger().w("A problem occurred when tried to unescape a value from a payload packet "
          "element");
      return null;
    }

    return (unTmpElem, ts);
  }

  /// This method tests if the packet given has the endByte as last byte
  /// This is useful to know if all the expected packet are received from the device
  static bool? isLastElementPacket(Uint8List packet) {
    if (packet.isEmpty) {
      return false;
    }

    if (packet.last == HaloPacketUtility._endByte) {
      return true;
    }

    if (packet.contains(HaloPacketUtility._endByte)) {
      appLogger()
          .w("The end byte has been seen in the middle of packet received but this should never "
              "happen. The end byte has to be the last byte of the packet");
      return null;
    }

    return false;
  }

  /// Try to clean the last element packet
  ///
  /// If the [packet] given has 0x00 bytes after the end packet, the method removes it.
  /// If the [packet] has other bytes than 0x00, the method returns null.
  static Uint8List? tryToCleanLastElementPacket(Uint8List packet) {
    final endByteIndex = packet.indexOf(HaloPacketUtility._endByte);
    final packetLastIdx = packet.length - 1;

    if (endByteIndex < 0 || endByteIndex == packetLastIdx) {
      // There is nothing to do
      return packet;
    }

    final newPacket = List<int>.from(packet);
    for (var idx = endByteIndex + 1; idx <= packetLastIdx; ++idx) {
      if (newPacket[idx] != 0x00) {
        appLogger().w("After the end byte, there are non zero bytes. We can't proceed.");
        return null;
      }
    }

    appLogger().w("After the end byte, there are only 0x00 bytes; therefore, we remove them "
        "considering they don't exist, but they can be relevant data");
    newPacket.removeRange(endByteIndex + 1, packetLastIdx + 1);
    return Uint8List.fromList(newPacket);
  }
}
