// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_config_manager/src/data/config_constants.dart' as config_constants;
import 'package:act_config_manager/src/services/config_singleton.dart';
import 'package:act_config_manager/src/types/environment.dart';
import 'package:act_config_manager/src/utilities/config_from_env_utility.dart';
import 'package:act_config_manager/src/utilities/config_from_yaml_utility.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter/widgets.dart';

/// Builder for creating the ConfigManager
abstract class AbstractConfigBuilder<T extends AbstractConfigManager> extends AbsManagerBuilder<T> {
  /// A factory to create a manager instance
  AbstractConfigBuilder(super.factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [];
}

/// [AbstractConfigManager] handles config variables management.
///
/// Each supported config variable is accessible through a public member, which provides a getter
/// to read from config variables.
///
/// To choose the config environment in flutter run/build, use the parameter "--dart-define"
/// Example : flutter run --dart-define="ENV=PROD".
/// Possible values are : DEV, QUALIF and PROD.
abstract class AbstractConfigManager extends AbsWithLifeCycle {
  /// The environment used
  late final Environment env;

  /// Path to configuration folder
  final String configPath;

  /// Builds an instance of [AbstractConfigManager].
  ///
  /// You may want to use created instance as a singleton in order to save memory.
  AbstractConfigManager({
    this.configPath = config_constants.defaultConfigPath,
  }) : super() {
    // We explicitly use Environment here because we need to get the env type to know the
    // environment to use in the app
    // ignore: do_not_use_environment
    env = Environment.fromString(const String.fromEnvironment(Environment.envType));
  }

  /// Init the manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    WidgetsFlutterBinding.ensureInitialized();

    final configsValue = await ConfigFromYamlUtility.parseFromConfigFiles(configPath, env);
    final envConfigs = await ConfigFromEnvUtility.parseFromEnv(configPath);
    final finalValue = JsonUtility.mergeJson(
      baseJson: configsValue,
      jsonToOverrideWith: envConfigs,
    );

    final configs = ConfigSingleton.createInstance(finalValue);
    await configs.initLifeCycle();
  }

  /// Called after the first view is built
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);
    await ConfigSingleton.instance.initLifeCycle();
  }

  /// Called when the manager is disposed
  @override
  Future<void> disposeLifeCycle() async {
    await super.disposeLifeCycle();
    await ConfigSingleton.instance.disposeLifeCycle();
  }
}
