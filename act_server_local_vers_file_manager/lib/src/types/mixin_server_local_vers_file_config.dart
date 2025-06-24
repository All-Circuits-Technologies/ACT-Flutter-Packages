// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_server_local_vers_file_manager/src/models/server_local_dir_config.dart';
import 'package:act_server_local_vers_file_manager/src/types/mixin_server_local_vers_file_type.dart';
import 'package:flutter/foundation.dart';

mixin MixinServerLocalVersFileConfig<T extends MixinServerLocalVersFileType>
    on AbstractConfigManager {
  late final serverLocalVersFileConfig =
      ParserConfigVar<ServerLocalDirConfig<T>, Map<String, dynamic>>(
    "serverLocalVersFile.config",
    parser: (value) => ServerLocalDirConfig.parseFromJson<T>(
      value,
      dirTypes: getMultiDirTypes(),
    ),
  );

  @protected
  List<T> getMultiDirTypes();
}
