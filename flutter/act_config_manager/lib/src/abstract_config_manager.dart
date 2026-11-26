// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/data/config_constants.dart' as config_constants;
import 'package:act_config_manager/src/utilities/assets_config_reader.dart';
import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:flutter/widgets.dart';

/// Builder for creating the ConfigManager
abstract class AbstractConfigBuilder<T extends AbstractConfigManager>
    extends AbsCoreConfigBuilder<T> {
  /// A factory to create a manager instance
  const AbstractConfigBuilder(super.factory);
}

/// [AbstractConfigManager] handles config variables management, from the assets of the application.
///
/// Each supported config variable is accessible through a public member, which provides a getter
/// to read from config variables.
///
/// This is the config manager of the Flutter applications: the configuration files are assets of
/// the application.
///
/// To choose the config environment in flutter run/build, use the parameter "--dart-define"
/// Example : flutter run --dart-define="ENV=PROD".
/// Possible values are : DEV, QUALIF and PROD.
abstract class AbstractConfigManager extends AbsCoreConfigManager {
  /// Path to configuration folder
  final String configPath;

  /// Builds an instance of [AbstractConfigManager].
  ///
  /// You may want to use created instance as a singleton in order to save memory.
  AbstractConfigManager({
    required super.logger,
    this.configPath = config_constants.defaultConfigPath,
  }) : super(
         env: Environment.fromString(
           // We explicitly use Environment here because we need to get the env type to know the
           // environment to use in the app
           // ignore: do_not_use_environment
           const String.fromEnvironment(Environment.envType),
         ),
       );

  /// Load the configuration from the assets of the application.
  ///
  /// The files of the [configPath] folder and the environment variables are read and merged.
  @override
  @protected
  Future<Map<String, dynamic>> loadConfigs() async {
    WidgetsFlutterBinding.ensureInitialized();

    return ConfigLoader.loadConfigs(
      reader: AssetsConfigReader(configPath: configPath),
      env: env,
      processEnv: ActPlatform.instance.environment,
    );
  }
}
