// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_local_storage_manager/src/services/secrets_singleton.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// Builder for creating the SecretsManager
abstract class AbstractSecretsBuilder<P extends AbstractPropertiesManager,
    E extends MixinStoresConf, T extends AbstractSecretsManager> extends AbsManagerBuilder<T> {
  /// A factory to create a manager instance
  const AbstractSecretsBuilder(super.factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager, P, E];
}

/// [AbstractSecretsManager] handles confidential data storage.
///
/// (for non-secret data, please see [AbstractPropertiesManager])
///
/// Each supported secret is accessible through a public member,
/// which provides a getter and a setter to read from secure storage and
/// save to secure storage respectively.
///
/// Data is not always accessible
/// -----------------------------
///
/// {@macro act_local_storage_manager.SecretsSingleton.exceptions}
abstract class AbstractSecretsManager extends AbsWithLifeCycle {
  /// This is the getter used to access the [AbstractPropertiesManager] of the project
  final AbstractPropertiesManager Function() propertiesGetter;

  /// This is the getter used to access the config manager of the project, which implements the
  /// [MixinStoresConf] mixin.
  final MixinStoresConf Function() confGetter;

  /// Builds an instance of [AbstractSecretsManager].
  ///
  /// You may want to use created instance as a singleton
  /// in order to save memory.
  const AbstractSecretsManager({
    required this.propertiesGetter,
    required this.confGetter,
  }) : super();

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    SecretsSingleton.createInstance();

    final isFirstStart = propertiesGetter().isFirstStart;

    final isNeededToDeleteAll = confGetter().cleanSecretStorageWhenReinstall.load();

    // Check if app has already been run
    if (isFirstStart && isNeededToDeleteAll) {
      // Delete all keys associated with app,
      // this is required because of iOS keychain behaviour
      await deleteAll();
    }
  }

  /// Delete all stored secrets.
  ///
  /// Can throw a `PlatformException`.
  Future<void> deleteAll() async => SecretsSingleton.instance.deleteAll();
}
