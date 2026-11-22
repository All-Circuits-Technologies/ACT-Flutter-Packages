// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/src/services/config_store.dart';
import 'package:act_dart_config_manager/src/types/environment.dart';
import 'package:act_dart_life_cycle/act_dart_life_cycle.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:meta/meta.dart';

/// Builder for creating a config manager derived from [AbsCoreConfigManager].
abstract class AbsCoreConfigBuilder<T extends AbsCoreConfigManager> extends AbsLifeCycleFactory<T> {
  /// A factory to create a manager instance
  const AbsCoreConfigBuilder(super.factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [];
}

/// Base class of the config managers, which doesn't know where the configuration comes from.
///
/// The manager holds the environment it works with, asks the derived class to load the
/// configuration ([loadConfigs]) when it's initialized, and puts it in the [ConfigStore] the
/// config variables read from. The store is released when the manager is disposed.
///
/// Each supported config variable is declared as a public member of the derived class (or of a
/// mixin on this class), which provides a getter to read from the config variables.
///
/// Use a derived class which knows how to load the configuration: the `AbsFileConfigManager` class
/// for a pure Dart application which reads its files from the file system, or the
/// `AbstractConfigManager` class of `act_config_manager` for a Flutter application which reads
/// them from its assets. This class is mainly the type the mixins which declare config variables
/// target.
abstract class AbsCoreConfigManager extends AbsWithLifeCycle {
  /// The logger category linked to this manager.
  static const _loggerCategory = "conf";

  /// The environment used
  final Environment env;

  /// The logger used to log messages in this manager.
  final MixinActLogger _logger;

  /// Builds an instance of [AbsCoreConfigManager].
  ///
  /// The [env] is the environment the configuration is loaded for. The manager logs through a
  /// sub-logger of [logger].
  ///
  /// You may want to use created instance as a singleton in order to save memory.
  AbsCoreConfigManager({required MixinActLogger logger, required this.env})
    : _logger = logger.createAbsSubLogger(subCategory: _loggerCategory),
      super();

  /// The logger used to log messages in this manager.
  @protected
  MixinActLogger get logger => _logger;

  /// Init the manager
  ///
  /// The configuration is loaded with [loadConfigs] and put in the [ConfigStore].
  ///
  /// This method throws if the configuration can't be loaded: the manager is initialized at
  /// startup and the application can't work without its configuration.
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    final configs = await loadConfigs();

    ConfigStore.create(logger: _logger, configs: configs);

    _logger.i("Config manager initialized with environment: $env");
  }

  /// Load the configuration, from the source the derived class knows, and return it merged.
  ///
  /// The returned map is the structured configuration the [ConfigStore] is created with. It follows
  /// the precedence of the config sources (from the less to the most important): the default file,
  /// the file of the chosen [env], the local file, then the environment variables.
  @protected
  Future<Map<String, dynamic>> loadConfigs();

  /// Called when the manager is disposed
  @override
  Future<void> disposeLifeCycle() async {
    // The store doesn't exist when the manager is disposed before it has been initialized, for
    // instance when its initialization failed
    ConfigStore.instanceOrNull?.dispose();
    await super.disposeLifeCycle();
  }
}
