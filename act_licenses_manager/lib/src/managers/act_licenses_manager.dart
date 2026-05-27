// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_licenses_manager/src/managers/mixin_licenses_config.dart';
import 'package:act_licenses_manager/src/models/abs_license_packages.dart';
import 'package:act_licenses_manager/src/utilities/licenses_utility.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';

/// Builder of the [ActLicensesManager]
class ActLicensesBuilder<C extends MixinLicensesConfig>
    extends AbsLifeCycleFactory<ActLicensesManager> {
  /// Class constructor
  ActLicensesBuilder() : super(() => ActLicensesManager(configGetter: globalGetIt().get<C>));

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager, C];
}

/// This is the manager of the licenses
class ActLicensesManager extends AbsWithLifeCycle {
  /// The log category of the manager
  static const String _logCategory = "licenses";

  /// The logger of the manager
  late final LogsHelper _logsHelper;

  /// The config of the manager
  final MixinLicensesConfig Function() _configGetter;

  /// This lock is used to avoid loading the licenses multiple times at the same time
  final LockUtility _loadLicensesLock;

  /// The list of licenses packages loaded from the config and the assets folders
  final List<AbsLicensePackages> _loadedLicensesPackages;

  /// Class constructor
  ActLicensesManager({required MixinLicensesConfig Function() configGetter})
    : _configGetter = configGetter,
      _loadLicensesLock = LockUtility(),
      _loadedLicensesPackages = [];

  /// {@macro act_life_cycle.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _logsHelper = LogsHelper(category: _logCategory);

    unawaited(_loadLicenses(logger: _logsHelper));
    LicenseRegistry.addLicense(_collector);
  }

  /// This method is used to collect the licenses from the loaded licenses packages and return them
  /// as a stream of [LicenseEntry].
  Stream<LicenseEntry> _collector() async* {
    await _loadLicensesLock.wait();

    for (final licensePackage in _loadedLicensesPackages) {
      final licenseEntry = await licensePackage.paragraphsLoader();

      if (licenseEntry != null) {
        yield licenseEntry;
      }
    }
  }

  /// This method loads the licenses from the config and the assets folders.
  ///
  /// It should be called in the initLifeCycle of the manager.
  ///
  /// This method may take some time. Therefore, it is recommended to not wait for it to be
  /// completed before showing the app to the user.
  ///
  /// But waiting the lock to be released before showing the licenses page.
  Future<void> _loadLicenses({required LogsHelper logger}) =>
      _loadLicensesLock.protectLock(() async {
        final tmpLicensesPackages = await LicensesUtility.parseLicensePackages(
          config: _configGetter(),
          logger: logger,
        );
        _loadedLicensesPackages.addAll(tmpLicensesPackages);
      });
}
