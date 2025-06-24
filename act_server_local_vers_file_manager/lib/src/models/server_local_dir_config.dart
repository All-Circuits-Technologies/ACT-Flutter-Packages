// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_local_vers_file_manager/src/models/server_local_dir_options.dart';
import 'package:act_server_local_vers_file_manager/src/types/mixin_server_local_vers_file_type.dart';
import 'package:equatable/equatable.dart';

class ServerLocalDirConfig<T extends MixinServerLocalVersFileType> extends Equatable {
  final Map<T, ServerLocalDirOptions> options;

  const ServerLocalDirConfig({
    required this.options,
  });

  ServerLocalDirConfig copyWith({
    Map<MixinServerLocalVersFileType, ServerLocalDirOptions>? options,
  }) =>
      ServerLocalDirConfig(
        options: options ?? this.options,
      );

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

  @override
  List<Object?> get props => [options];
}
