// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

export 'package:act_halo_abstract/act_halo_abstract.dart'
    show AbstractHaloHwTypeHelper, HaloHardwareType;
export 'package:act_halo_manager/act_halo_manager.dart' show HaloManagerConfig;

export "src/abstract_ocsigen_halo_manager.dart";
export "src/features/ocsigen_request_to_device_feature.dart";
export "src/models/ocsigen_request_id.dart";
export "src/models/ocsigen_wifi_complete_scan_result.dart";
export "src/models/ocsigen_wifi_connect_result.dart";
export "src/models/ocsigen_wifi_status_result.dart";
export "src/types/ocsigen_wifi_auth_mode.dart";
export "src/types/ocsigen_wifi_connect_status.dart";
export "src/types/ocsigen_wifi_urc.dart";
export "src/types/restricted_end_com_status.dart";
