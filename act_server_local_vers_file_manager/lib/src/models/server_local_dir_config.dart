// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_local_vers_file_manager/src/models/server_local_dir_options.dart';
import 'package:act_server_local_vers_file_manager/src/types/mixin_server_local_vers_file_type.dart';
import 'package:equatable/equatable.dart';

/// This class is used to store the configuration of the server local directories.
/// It contains a map of [MixinServerLocalVersFileType] to [ServerLocalDirOptions].
class ServerLocalDirConfig<T extends MixinServerLocalVersFileType> extends Equatable {
  /// This is the options stored in config
  final Map<T, ServerLocalDirOptions> options;

  /// Class constructor
  const ServerLocalDirConfig({
    required this.options,
  });

  /// Returns a copy of this [ServerLocalDirConfig] with the given options.
  ServerLocalDirConfig copyWith({
    Map<MixinServerLocalVersFileType, ServerLocalDirOptions>? options,
  }) =>
      ServerLocalDirConfig(
        options: options ?? this.options,
      );

  /// Parses a [ServerLocalDirConfig] from a JSON map.
  static ServerLocalDirConfig<T>? parseFromJson<T extends MixinServerLocalVersFileType>(
    Map<String, dynamic> json, {
    required List<T> dirTypes,
  }) {
    final dirsOptions = <T, ServerLocalDirOptions>{};
    for (final entry in json.entries) {
      final tmpKey = entry.key;
      final tmpValue = entry.value;

      T? tmpDirType;
      for (final dirType in dirTypes) {
        if (dirType.dirId == tmpKey) {
          tmpDirType = dirType;
          break;
        }
      }

      if (tmpDirType == null) {
        // We don't stop here, because we may have more information in the json that we can manage
        // in the app.
        appLogger().w("The dir type: $tmpKey, is unknown in the app");
        continue;
      }

      if (tmpValue is! Map<String, dynamic>) {
        appLogger().w("The JSON value of the dir type: $tmpKey, isn't a JSON object; "
            "therefore, we can't parse the value");
        continue;
      }

      final options = ServerLocalDirOptions.parseFromJson(tmpValue);
      if (options == null) {
        appLogger().w("We can't parse the JSON value of dir type: $tmpKey");
        continue;
      }

      dirsOptions[tmpDirType] = options;
    }

    return ServerLocalDirConfig(options: dirsOptions);
  }

  /// Contains the class properties
  @override
  List<Object?> get props => [options];
}
