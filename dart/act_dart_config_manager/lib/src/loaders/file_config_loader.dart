// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_dart_config_manager/src/loaders/config_loader.dart';
import 'package:act_dart_config_manager/src/loaders/file_config_reader.dart';
import 'package:act_dart_config_manager/src/services/config_store.dart';
import 'package:act_dart_config_manager/src/types/environment.dart';
import 'package:act_foundation/act_foundation.dart';

/// This class loads the configuration from the file system and fills the [ConfigStore].
///
/// It's the file system counterpart of the config manager which reads the configuration from the
/// assets bundle: it reads the same files, with the rules of [ConfigLoader], but from a directory
/// of the file system, which lets the configuration be changed without recompiling the host.
sealed class FileConfigLoader {
  /// The logger category linked to this loader.
  static const _loggerCategory = "conf";

  /// The name of the environment variable which overrides the directory the configuration is read
  /// from.
  static const configDirEnvKey = "ACT_CONFIG_DIR";

  /// The directory the configuration is read from when neither an explicit one nor the
  /// [configDirEnvKey] environment variable gives one.
  static const defaultConfigDir = "config";

  /// Load the configuration from the file system and create the [ConfigStore].
  ///
  /// The directory, the environment and the precedence are the ones of [loadConfigs]: [configDir]
  /// and [env] are used when they're given, else [resolveEnvironment] chooses the environment.
  static Future<ConfigStore> load({
    required MixinActLogger logger,
    String? configDir,
    Environment? env,
  }) async {
    final subLogger = logger.createAbsSubLogger(subCategory: _loggerCategory);
    final chosenEnv = env ?? resolveEnvironment();

    final finalValue = await loadConfigs(logger: subLogger, env: chosenEnv, configDir: configDir);

    final store = ConfigStore.create(logger: subLogger, configs: finalValue);

    subLogger.i(
      "Config store loaded from the directory '${_resolveDirectory(configDir)}' with "
      "environment: $chosenEnv",
    );

    return store;
  }

  /// Load the configuration from the file system and return it merged, without creating the
  /// [ConfigStore].
  ///
  /// The directory the files are read from is [configDir] when it's given, else the value of the
  /// [configDirEnvKey] environment variable, else [defaultConfigDir].
  ///
  /// The files read, their precedence and the errors are the ones of [ConfigLoader.loadConfigs],
  /// with the chosen [env] and the environment variables of the process.
  static Future<Map<String, dynamic>> loadConfigs({
    required MixinActLogger logger,
    required Environment env,
    String? configDir,
  }) async {
    final directory = _resolveDirectory(configDir);

    final result = await ConfigLoader.loadConfigs(
      reader: FileConfigReader(directory: directory),
      env: env,
      processEnv: Platform.environment,
    );

    logger.d("Config loaded from the directory '$directory' with environment: $env");

    return result;
  }

  /// Get the environment targeted by the [Environment.envType] environment variable of the
  /// process, or [Environment.development] when it's absent or unknown.
  static Environment resolveEnvironment() =>
      Environment.fromString(Platform.environment[Environment.envType] ?? "");

  /// Get the directory the configuration is read from: the given [configDir], else the
  /// [configDirEnvKey] environment variable, else [defaultConfigDir].
  static String _resolveDirectory(String? configDir) =>
      configDir ?? Platform.environment[configDirEnvKey] ?? defaultConfigDir;
}
