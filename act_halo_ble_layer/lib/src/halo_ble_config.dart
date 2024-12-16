// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_a_attr_notify.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_b_attr_cmd.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_c_attr_tmp.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_d_inst_notify.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_e_inst_cmd.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_f_inst_tmp.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_g_record_notify.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_h_record_cmd.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_i_record_tmp.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_j_request_to_device_cmd.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_k_request_to_device_tmp.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_l_request_to_client_cmd.dart';
import 'package:act_halo_ble_layer/src/characteristics/char_m_request_to_client_tmp.dart';
import 'package:act_halo_ble_layer/src/characteristics/mix_char_notification.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Contains all the needed configuration for the HALO BLE hardware layer
class HaloBleConfig extends Equatable {
  /// The max characteristic payload byte size
  final int maxCharacteristicByteSize;

  /// The HALO characteristic A for attribute notification exchange
  final CharAAttrNotify charAAttrNotify;

  /// The HALO characteristic B for attribute command exchange
  final CharBAttrCmd charBAttrCmd;

  /// The HALO characteristic C for attribute temporary exchange
  final CharCAttrTmp charCAttrTmp;

  /// The HALO characteristic D for instant data notification exchange
  final CharDInstNotify charDInstNotify;

  /// The HALO characteristic E for instant data command exchange
  final CharEInstCmd charEInstCmd;

  /// The HALO characteristic F for instant data temporary exchange
  final CharFInstTmp charFInstTmp;

  /// The HALO characteristic G for record data notification exchange
  final CharGRecordNotify charGRecordNotify;

  /// The HALO characteristic H for record data command exchange
  final CharHRecordCmd charHRecordCmd;

  /// The HALO characteristic I for record data temporary exchange
  final CharIRecordTmp charIRecordTmp;

  /// The HALO characteristic J for request to device command exchange
  final CharJRequestToDeviceCmd charJRequestToDeviceCmd;

  /// The HALO characteristic K for request to device temporary exchange
  final CharKRequestToDeviceTmp charKRequestToDeviceTmp;

  /// The HALO characteristic L for request from device command exchange
  final CharLRequestToClientCmd charLRequestToClientCmd;

  /// The HALO characteristic M for request from device temporary exchange
  final CharMRequestToClientTmp charMRequestToClientTmp;

  /// This contains the list of all the HALO characteristics
  late final List<AbstractHaloCharacteristic> allHaloCharacteristics;

  /// This contains the list of all the characteristics which can raise notification
  late final List<MixCharNotification> notifiableHaloCharacteristics;

  /// Class constructor
  HaloBleConfig({
    required UuidValue charAAttrNotifyUuid,
    required UuidValue charBAttrCmdUuid,
    required UuidValue charCAttrTmpUuid,
    required UuidValue charDInstNotifyUuid,
    required UuidValue charEInstCmdUuid,
    required UuidValue charFInstTmpUuid,
    required UuidValue charGRecordNotifyUuid,
    required UuidValue charHRecordCmdUuid,
    required UuidValue charIRecordTmpUuid,
    required UuidValue charJRequestToDeviceCmdUuid,
    required UuidValue charKRequestToDeviceTmpUuid,
    required UuidValue charLRequestToClientCmdUuid,
    required UuidValue charMRequestToClientTmpUuid,
    required this.maxCharacteristicByteSize,
  })  : assert(maxCharacteristicByteSize >= 0,
            "The max characteristic content size: $maxCharacteristicByteSize can't be negative"),
        charAAttrNotify = CharAAttrNotify(uuid: charAAttrNotifyUuid.uuid),
        charBAttrCmd = CharBAttrCmd(uuid: charBAttrCmdUuid.uuid),
        charCAttrTmp = CharCAttrTmp(uuid: charCAttrTmpUuid.uuid),
        charDInstNotify = CharDInstNotify(uuid: charDInstNotifyUuid.uuid),
        charEInstCmd = CharEInstCmd(uuid: charEInstCmdUuid.uuid),
        charFInstTmp = CharFInstTmp(uuid: charFInstTmpUuid.uuid),
        charGRecordNotify = CharGRecordNotify(uuid: charGRecordNotifyUuid.uuid),
        charHRecordCmd = CharHRecordCmd(uuid: charHRecordCmdUuid.uuid),
        charIRecordTmp = CharIRecordTmp(uuid: charIRecordTmpUuid.uuid),
        charJRequestToDeviceCmd = CharJRequestToDeviceCmd(uuid: charJRequestToDeviceCmdUuid.uuid),
        charKRequestToDeviceTmp = CharKRequestToDeviceTmp(uuid: charKRequestToDeviceTmpUuid.uuid),
        charLRequestToClientCmd = CharLRequestToClientCmd(uuid: charLRequestToClientCmdUuid.uuid),
        charMRequestToClientTmp = CharMRequestToClientTmp(uuid: charMRequestToClientTmpUuid.uuid) {
    allHaloCharacteristics = [
      charAAttrNotify,
      charBAttrCmd,
      charCAttrTmp,
      charDInstNotify,
      charEInstCmd,
      charFInstTmp,
      charGRecordNotify,
      charHRecordCmd,
      charIRecordTmp,
      charJRequestToDeviceCmd,
      charKRequestToDeviceTmp,
      charLRequestToClientCmd,
      charMRequestToClientTmp,
    ];

    notifiableHaloCharacteristics = [];
    for (final char in allHaloCharacteristics) {
      if (char.hasNotification && char is MixCharNotification) {
        notifiableHaloCharacteristics.add(char);
      }
    }
  }

  @override
  List<Object?> get props => [
        charAAttrNotify,
        charBAttrCmd,
        charCAttrTmp,
        charDInstNotify,
        charEInstCmd,
        charFInstTmp,
        charGRecordNotify,
        charHRecordCmd,
        charIRecordTmp,
        charJRequestToDeviceCmd,
        charKRequestToDeviceTmp,
        charLRequestToClientCmd,
        charMRequestToClientTmp,
      ];
}
