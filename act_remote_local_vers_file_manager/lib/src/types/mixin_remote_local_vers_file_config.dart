// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_remote_local_vers_file_manager/src/models/remote_local_dir_config.dart';
import 'package:act_remote_local_vers_file_manager/src/types/mixin_remote_local_vers_file_type.dart';
import 'package:flutter/foundation.dart';

/// This mixin provides a configuration manager for server local version files.
mixin MixinRemoteLocalVersFileConfig<T extends MixinRemoteLocalVersFileType>
    on AbstractConfigManager {
  /// The configuration variable for the server local version files.
  late final remoteLocalVersFileConfig =
      ParserConfigVar<RemoteLocalDirConfig<T>, Map<String, dynamic>>(
    "remoteLocalVersFile.config",
    parser: (value) => RemoteLocalDirConfig.parseFromJson<T>(
      value,
      dirTypes: getMultiDirTypes(),
    ),
  );

  /// {@template act_remote_local_vers_file_manager.MixinRemoteLocalVersFileConfig.getMultiDirTypes}
  /// Get the list of [T]
  /// {@endtemplate}
  @protected
  List<T> getMultiDirTypes();
}
