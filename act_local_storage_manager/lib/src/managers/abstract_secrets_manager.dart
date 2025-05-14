// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_local_storage_manager/src/services/secrets_singleton.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Builder for creating the SecretsManager
abstract class AbstractSecretsBuilder<
    P extends AbstractPropertiesManager,
    E extends MixinStoresConf,
    T extends AbstractSecretsManager<P, E>> extends AbsManagerBuilder<T> {
  /// A factory to create a manager instance
  AbstractSecretsBuilder(super.factory);

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
abstract class AbstractSecretsManager<P extends AbstractPropertiesManager,
    E extends MixinStoresConf> extends AbsWithLifeCycle {
  /// Builds an instance of [AbstractSecretsManager].
  ///
  /// You may want to use created instance as a singleton
  /// in order to save memory.
  AbstractSecretsManager() : super();

  /// Init the manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    SecretsSingleton.createInstance(const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ));

    final isFirstStart = globalGetIt().get<P>().isFirstStart;

    final isNeededToDeleteAll = globalGetIt().get<E>().cleanSecretStorageWhenReinstall.load();

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
  Future<void> deleteAll() async => SecretsSingleton.instance.secureStorage.deleteAll();
}
