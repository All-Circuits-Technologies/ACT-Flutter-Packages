// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_remote_local_vers_file_manager/src/models/remote_local_dir_options.dart';
import 'package:act_remote_local_vers_file_manager/src/types/mixin_remote_local_vers_file_type.dart';
import 'package:equatable/equatable.dart';

/// This class is used to store the configuration of the server local directories.
/// It contains a map of [MixinRemoteLocalVersFileType] to [RemoteLocalDirOptions].
class RemoteLocalDirConfig<T extends MixinRemoteLocalVersFileType> extends Equatable {
  /// This is the options stored in config
  final Map<T, RemoteLocalDirOptions> options;

  /// Class constructor
  const RemoteLocalDirConfig({
    required this.options,
  });

  /// Returns a copy of this [RemoteLocalDirConfig] with the given options.
  RemoteLocalDirConfig copyWith({
    Map<MixinRemoteLocalVersFileType, RemoteLocalDirOptions>? options,
  }) =>
      RemoteLocalDirConfig(
        options: options ?? this.options,
      );

  /// Parses a [RemoteLocalDirConfig] from a JSON map.
  static RemoteLocalDirConfig<T>? parseFromJson<T extends MixinRemoteLocalVersFileType>(
    Map<String, dynamic> json, {
    required List<T> dirTypes,
  }) {
    final dirsOptions = <T, RemoteLocalDirOptions>{};
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

      final options = RemoteLocalDirOptions.parseFromJson(tmpValue);
      if (options == null) {
        appLogger().w("We can't parse the JSON value of dir type: $tmpKey");
        continue;
      }

      dirsOptions[tmpDirType] = options;
    }

    return RemoteLocalDirConfig(options: dirsOptions);
  }

  /// Contains the class properties
  @override
  List<Object?> get props => [options];
}
