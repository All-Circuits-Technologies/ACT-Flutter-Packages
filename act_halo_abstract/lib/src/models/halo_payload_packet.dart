// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/src/halo_packet_utility.dart';

/// Represents the payload packet element (the elements between the
/// [HaloPacketUtility._elementSeparator]), the bytes contains in it are escaped
typedef _PayloadPacketElem = Uint8List;

/// Represents the payload of a packet, it has a specific format
class HaloPayloadPacket {
  /// The list of packet element stored in the payload
  final List<_PayloadPacketElem> _elements;

  /// The number of elements in the packet
  int get elementsNb => _elements.length;

  /// Class constructor
  HaloPayloadPacket() : _elements = [];

  /// Specific constructor when receiving a packet from device
  HaloPayloadPacket._fromDevice(List<_PayloadPacketElem> elements) : _elements = elements;

  /// This helpful method parses the packet received from the device (the packet may be split
  /// in several parts) and returns a [HaloPayloadPacket] or null if a problem occurred in the
  /// process
  ///
  /// [payloadPackets] are joined in the method and are considered as one packet
  static HaloPayloadPacket? fromDevice(List<Uint8List> payloadPackets) {
    final payloadPacket = Uint8List.fromList(payloadPackets.expand((element) => element).toList());

    final elements = HaloPacketUtility.extractFromPayloadPacket(payloadPacket);
    if (elements == null) {
      appLogger().w("We can't create a HaloPayloadPacket, a problem occurred");
      return null;
    }

    return HaloPayloadPacket._fromDevice(elements);
  }

  /// This method transforms the payload as a packet ready to be received by the device.
  ///
  /// The method also splits the packet in several part, depending of the [maxPacketSize]
  List<Uint8List> getDataToSend({
    int maxPacketSize = -1,
  }) =>
      HaloPacketUtility.formatPackets(
        escapedDataToSend: _elements,
        maxPacketSize: maxPacketSize,
      );

  /// Helpful method to add a string in the list of packet element, you may also prepend the value
  /// with a [ts] timestamp
  void addString(
    String toSend, {
    DateTime? ts,
  }) {
    final element = HaloPacketUtility.formatString(toSend, ts: ts);
    _elements.add(element);
  }

  /// Helpful method to add a string list in the list of packet elements, you may also prepend the
  /// values list with a [ts] timestamp
  /// The list is flattened in the packet elements list
  void addStringList(
    List<String> toSend, {
    DateTime? ts,
  }) {
    for (var idx = 0; idx < toSend.length; ++idx) {
      addString(toSend[idx], ts: (idx == 0) ? ts : null);
    }
  }

  /// Helpful method to get a string from the packet elements list thanks to the [elemIdx] idx given
  /// If a problem occurred (because the element has not the type you expect or the index overflows
  /// the list length) the method returns null
  /// If a timestamp is attached to the element, it will be returned
  (String, DateTime?)? getString(int elemIdx) {
    if (elemIdx >= elementsNb) {
      appLogger().w("We can't get a string where the idx: $elemIdx, overflows the payload packet "
          "element list size: $elementsNb");
      return null;
    }

    return HaloPacketUtility.getString(_elements[elemIdx]);
  }

  /// Helpful method to get a string list from the packet elements list thanks to the
  /// [fromStartIdx] idx given and the [length].
  /// If [length] is equals to -1, the method will try to get all from the start index.
  /// If [length] is different of -1, the method will try to get exactly the number asked, and will
  /// returns an error, if it overflows the list
  /// If [fromStartIdx] is equals to 0
  ///
  ///
  /// If a problem occurred (because the element has not the type you expect or the index overflows
  /// the list length) the method returns null
  /// If a timestamp is attached to the element, it will be returned
  (List<String>, DateTime?)? getListString(int fromStartIdx, [int length = -1]) {
    if (fromStartIdx > elementsNb) {
      // If the [fromStartIdx] is equal to the elementsNb this can mean that the list you want to
      // get is empty
      appLogger().w("We can't get a string list where the idx: $fromStartIdx, overflows the "
          "payload packet element list size: $elementsNb");
      return null;
    }

    if (length != -1 && (fromStartIdx + length - 1) >= elementsNb) {
      appLogger().w("We can't get a string list where the last idx: ${fromStartIdx + length - 1}, "
          "overflows the payload packet element list size: $elementsNb");
      return null;
    }

    final realLength = (length != -1) ? length : elementsNb - fromStartIdx;

    DateTime? firstTimestamp;
    final elements = <String>[];
    for (var idx = 0; idx < realLength; ++idx) {
      final tmp = HaloPacketUtility.getString(_elements[idx]);

      if (tmp == null) {
        return null;
      }

      final (data, ts) = tmp;

      firstTimestamp ??= ts;

      elements.add(data);
    }

    return (elements, firstTimestamp);
  }

  /// Helpful method to add a boolean in the list of packet element, you may also prepend the value
  /// with a [ts] timestamp
  void addBoolean(
    // We keep this parameter as positional to match the other methods of this kind
    // ignore: avoid_positional_boolean_parameters
    bool toSend, {
    DateTime? ts,
  }) {
    final element = HaloPacketUtility.formatBoolean(toSend, ts: ts);
    _elements.add(element);
  }

  /// Helpful method to add a boolean list in the list of packet elements, you may also prepend the
  /// values list with a [ts] timestamp
  /// The list is flattened in the packet elements list
  void addBooleanList(
    List<bool> toSend, {
    DateTime? ts,
  }) {
    for (var idx = 0; idx < toSend.length; ++idx) {
      addBoolean(toSend[idx], ts: (idx == 0) ? ts : null);
    }
  }

  /// Helpful method to get a boolean from the packet elements list thanks to the [elemIdx] idx
  /// given.
  /// If a problem occurred (because the element has not the type you expect or the index overflows
  /// the list length) the method returns null
  /// If a timestamp is attached to the element, it will be returned
  (bool, DateTime?)? getBoolean(int elemIdx) {
    if (elemIdx >= elementsNb) {
      appLogger().w("We can't a boolean where the idx: $elemIdx, overflows the payload packet "
          "element list size: $elementsNb");
      return null;
    }

    return HaloPacketUtility.getBoolean(_elements[elemIdx]);
  }

  /// Helpful method to add an unsigned integer of 8bits in the list of packet element, you may
  /// also prepend the value with a [ts] timestamp
  bool addUInt8(
    int toSend, {
    DateTime? ts,
  }) {
    final element = HaloPacketUtility.formatUInt8(toSend, ts: ts);

    if (element == null) {
      return false;
    }

    _elements.add(element);
    return true;
  }

  /// Helpful method to add an unsigned integer of 16bits in the list of packet element, you may
  /// also prepend the value with a [ts] timestamp
  bool addUInt16(
    int toSend, {
    DateTime? ts,
  }) {
    final element = HaloPacketUtility.formatUInt16(toSend, ts: ts);

    if (element == null) {
      return false;
    }

    _elements.add(element);
    return true;
  }

  /// Helpful method to add an unsigned integer of 32bits in the list of packet element, you may
  /// also prepend the value with a [ts] timestamp
  bool addUInt32(
    int toSend, {
    DateTime? ts,
  }) {
    final element = HaloPacketUtility.formatUInt32(toSend, ts: ts);

    if (element == null) {
      return false;
    }

    _elements.add(element);
    return true;
  }

  /// Helpful method to add a signed integer of 8bits in the list of packet element, you may
  /// also prepend the value with a [ts] timestamp
  bool addInt8(
    int toSend, {
    DateTime? ts,
  }) {
    final element = HaloPacketUtility.formatInt8(toSend, ts: ts);

    if (element == null) {
      return false;
    }

    _elements.add(element);
    return true;
  }

  /// Helpful method to add a signed integer of 16bits in the list of packet element, you may
  /// also prepend the value with a [ts] timestamp
  bool addInt16(
    int toSend, {
    DateTime? ts,
  }) {
    final element = HaloPacketUtility.formatInt16(toSend, ts: ts);

    if (element == null) {
      return false;
    }

    _elements.add(element);
    return true;
  }

  /// Helpful method to add a signed integer of 32bits in the list of packet element, you may
  /// also prepend the value with a [ts] timestamp
  bool addInt32(
    int toSend, {
    DateTime? ts,
  }) {
    final element = HaloPacketUtility.formatInt32(toSend, ts: ts);

    if (element == null) {
      return false;
    }

    _elements.add(element);
    return true;
  }

  /// Helpful method to add a double via a signed integer of 8 bits in the list of packet elements,
  /// you may also prepend the value with a [ts] timestamp.
  ///
  /// The method is ideal if you want to send a number with some digits after comma to a device,
  /// via an integer.
  /// For instance: if we want to send 2.5, we can set the [powerOfTenCoeff] to 1 and the method
  /// will send 25 to the device. Of course, the coeff has to be known by the device.
  ///
  /// If you want to set [powerOfTenCoeff] to 0, it's better to use the method [double.toInt] and
  /// uses the add integer methods
  bool addDoubleViaInt8(
    double toSend,
    int powerOfTenCoeff, {
    DateTime? ts,
  }) {
    final intValue = NumUtility.convertDoubleToInt8(
      toSend,
      powerOfTenCoeff,
      loggerManager: appLogger(),
    );

    if (intValue == null) {
      return false;
    }

    return addInt8(intValue, ts: ts);
  }

  /// Helpful method to add a double via a signed integer of 16 bits in the list of packet elements,
  /// you may also prepend the value with a [ts] timestamp.
  ///
  /// The method is ideal if you want to send a number with some digits after comma to a device,
  /// via an integer.
  /// For instance: if we want to send 2.5, we can set the [powerOfTenCoeff] to 1 and the method
  /// will send 25 to the device. Of course, the coeff has to be known by the device.
  ///
  /// If you want to set [powerOfTenCoeff] to 0, it's better to use the method [double.toInt] and
  /// uses the add integer methods
  bool addDoubleViaInt16(
    double toSend,
    int powerOfTenCoeff, {
    DateTime? ts,
  }) {
    final intValue = NumUtility.convertDoubleToInt16(
      toSend,
      powerOfTenCoeff,
      loggerManager: appLogger(),
    );

    if (intValue == null) {
      return false;
    }

    return addInt16(intValue, ts: ts);
  }

  /// Helpful method to add a double via a signed integer of 32 bits in the list of packet elements,
  /// you may also prepend the value with a [ts] timestamp.
  ///
  /// The method is ideal if you want to send a number with some digits after comma to a device,
  /// via an integer.
  /// For instance: if we want to send 2.5, we can set the [powerOfTenCoeff] to 1 and the method
  /// will send 25 to the device. Of course, the coeff has to be known by the device.
  ///
  /// If you want to set [powerOfTenCoeff] to 0, it's better to use the method [double.toInt] and
  /// uses the add integer methods
  bool addDoubleViaInt32(
    double toSend,
    int powerOfTenCoeff, {
    DateTime? ts,
  }) {
    final intValue = NumUtility.convertDoubleToInt32(
      toSend,
      powerOfTenCoeff,
      loggerManager: appLogger(),
    );

    if (intValue == null) {
      return false;
    }

    return addInt32(intValue, ts: ts);
  }

  /// Helpful method to add a double via an unsigned integer of 8 bits in the list of packet
  /// elements, you may also prepend the value with a [ts] timestamp.
  ///
  /// The method is ideal if you want to send a number with some digits after comma to a device,
  /// via an integer.
  /// For instance: if we want to send 2.5, we can set the [powerOfTenCoeff] to 1 and the method
  /// will send 25 to the device. Of course, the coeff has to be known by the device.
  ///
  /// If you want to set [powerOfTenCoeff] to 0, it's better to use the method [double.toInt] and
  /// uses the add integer methods
  bool addDoubleViaUInt8(
    double toSend,
    int powerOfTenCoeff, {
    DateTime? ts,
  }) {
    final intValue = NumUtility.convertDoubleToUInt8(
      toSend,
      powerOfTenCoeff,
      loggerManager: appLogger(),
    );

    if (intValue == null) {
      return false;
    }

    return addUInt8(intValue, ts: ts);
  }

  /// Helpful method to add a double via an unsigned integer of 16 bits in the list of packet
  /// elements, you may also prepend the value with a [ts] timestamp.
  ///
  /// The method is ideal if you want to send a number with some digits after comma to a device,
  /// via an integer.
  /// For instance: if we want to send 2.5, we can set the [powerOfTenCoeff] to 1 and the method
  /// will send 25 to the device. Of course, the coeff has to be known by the device.
  ///
  /// If you want to set [powerOfTenCoeff] to 0, it's better to use the method [double.toInt] and
  /// uses the add integer methods
  bool addDoubleViaUInt16(
    double toSend,
    int powerOfTenCoeff, {
    DateTime? ts,
  }) {
    final intValue = NumUtility.convertDoubleToUInt16(
      toSend,
      powerOfTenCoeff,
      loggerManager: appLogger(),
    );

    if (intValue == null) {
      return false;
    }

    return addUInt16(intValue, ts: ts);
  }

  /// Helpful method to add a double via an unsigned integer of 32 bits in the list of packet
  /// elements, you may also prepend the value with a [ts] timestamp.
  ///
  /// The method is ideal if you want to send a number with some digits after comma to a device,
  /// via an integer.
  /// For instance: if we want to send 2.5, we can set the [powerOfTenCoeff] to 1 and the method
  /// will send 25 to the device. Of course, the coeff has to be known by the device.
  ///
  /// If you want to set [powerOfTenCoeff] to 0, it's better to use the method [double.toInt] and
  /// uses the add integer methods
  bool addDoubleViaUInt32(
    double toSend,
    int powerOfTenCoeff, {
    DateTime? ts,
  }) {
    final intValue = NumUtility.convertDoubleToUInt32(
      toSend,
      powerOfTenCoeff,
      loggerManager: appLogger(),
    );

    if (intValue == null) {
      return false;
    }

    return addUInt32(intValue, ts: ts);
  }

  /// Helpful method to get an unsigned integer from the packet elements list thanks to the
  /// [elemIdx] idx given.
  /// If a problem occurred (because the element has not the type you expect or the index overflows
  /// the list length) the method returns null
  /// If a timestamp is attached to the element, it will be returned
  (int, DateTime?)? getUInt(int elemIdx) => getNumber(elemIdx, isSigned: false);

  /// Helpful method to get a signed integer from the packet elements list thanks to the
  /// [elemIdx] idx given.
  /// If a problem occurred (because the element has not the type you expect or the index overflows
  /// the list length) the method returns null
  /// If a timestamp is attached to the element, it will be returned
  (int, DateTime?)? getInt(int elemIdx) => getNumber(elemIdx, isSigned: true);

  /// Helpful method to get an integer from the packet elements list thanks to the
  /// [elemIdx] idx given.
  /// Uses the [isSigned] parameter to say if the expected number is signed or not
  /// If a problem occurred (because the element has not the type you expect or the index overflows
  /// the list length) the method returns null
  /// If a timestamp is attached to the element, it will be returned
  (int, DateTime?)? getNumber(
    int elemIdx, {
    required bool isSigned,
  }) {
    if (elemIdx >= elementsNb) {
      appLogger().w("We can't a number where the idx: $elemIdx, overflows the payload packet "
          "element list size: $elementsNb");
      return null;
    }

    return HaloPacketUtility.getNumber(_elements[elemIdx], isSigned: isSigned);
  }

  /// This method tests if the packet given has the endByte as last byte
  /// This is useful to know if all the expected packet are received from the device
  static bool? isLastElementPacket(Uint8List packet) =>
      HaloPacketUtility.isLastElementPacket(packet);

  /// Try to clean the last element packet
  ///
  /// If the [packet] given has 0x00 bytes after the end packet, the method removes it.
  /// If the [packet] has other bytes than 0x00, the method returns null.
  static Uint8List? tryToCleanLastElementPacket(Uint8List packet) =>
      HaloPacketUtility.tryToCleanLastElementPacket(packet);
}
