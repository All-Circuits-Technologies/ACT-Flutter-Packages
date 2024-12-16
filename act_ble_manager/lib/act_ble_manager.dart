// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library act_ble_manager;

export 'package:flutter_reactive_ble/flutter_reactive_ble.dart'
    show DeviceConnectionState, ScanMode, Uuid;

export 'src/ble_manager.dart';
export 'src/gap/ble_gap_service.dart';
export 'src/gatt/ble_gatt_service.dart';
export 'src/mixins/mixin_ble_env.dart';
export 'src/models/abstract_characteristic_info.dart';
export 'src/models/ble_device.dart';
export 'src/models/ble_scan_update_status.dart';
export 'src/models/ble_scanned_device.dart';
export 'src/models/mix_char_info_notification.dart';
export 'src/types/bond_state.dart';
export 'src/types/characteristics_error.dart';
