// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_server_local_vers_file_manager/src/models/server_local_dir_config.dart';
import 'package:act_server_local_vers_file_manager/src/types/mixin_server_local_vers_file_type.dart';
import 'package:flutter/foundation.dart';

/// This mixin provides a configuration manager for server local version files.
mixin MixinServerLocalVersFileConfig<T extends MixinServerLocalVersFileType>
    on AbstractConfigManager {
  /// The configuration variable for the server local version files.
  late final serverLocalVersFileConfig =
      ParserConfigVar<ServerLocalDirConfig<T>, Map<String, dynamic>>(
    "serverLocalVersFile.config",
    parser: (value) => ServerLocalDirConfig.parseFromJson<T>(
      value,
      dirTypes: getMultiDirTypes(),
    ),
  );

  /// {@template act_server_local_vers_file_manager.MixinServerLocalVersFileConfig.getMultiDirTypes}
  /// Get the list of [T]
  /// {@endtemplate}
  @protected
  List<T> getMultiDirTypes();
}
