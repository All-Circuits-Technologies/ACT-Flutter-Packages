// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/material.dart';

/// Abstract class which defines a builder for the consent manager specifying
/// the other managers that it depends on.
abstract class AbstractConsentBuilder<T extends AbstractConsentManager> extends ManagerBuilder<T> {
  /// Class constructor
  AbstractConsentBuilder(super.factory);

  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// Abstract class to store consent services and manage them in an application.
abstract class AbstractConsentManager<E extends Enum> extends AbstractManager {
  /// Class logger category
  static const String _consentManagerLogCategory = 'consent';

  /// Logs helper
  late final LogsHelper _logsHelper;

  /// Map of consent services
  final Map<E, AbstractConsentService> _services;

  /// List of required [ConsentObserver] instances
  final List<ConsentObserver> _observers;

  /// Class constructor
  AbstractConsentManager()
      : _services = {},
        _observers = [];

  @override
  Future<void> initManager() async {
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _consentManagerLogCategory,
    );
    final services = await getConsentServices(_logsHelper);
    _services.addAll(services);

    await Future.wait(_services.values.map((service) => service.initService()));
  }

  /// Initialize the services after the view has been created
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    await Future.wait(_services.values.map((service) => service.initAfterView(context)));
  }

  /// Provide the [_services] map with the consent type as key and
  /// the service as value
  @protected
  Future<Map<E, AbstractConsentService>> getConsentServices(
    LogsHelper logsHelper,
  );

  /// This method must be implemented by the derived class to return a list of all the
  /// [ConsentObserver] instances required by the service to determine the state of the consent.
  @protected
  void onRegisterObserver(ConsentObserver observer) => _observers.add(observer);

  /// Get the service for a given [consentType] if it exists
  /// It's up to the implementation to make sure that the requested service
  /// is indeed implemented with the correct type.
  AbstractConsentService<T>? getService<T extends MixinConsentOptions>(E consentType) {
    return _services[consentType] as AbstractConsentService<T>?;
  }

  @override
  Future<void> dispose() async {
    await Future.wait(_services.values.map((service) => service.dispose()));
    await Future.wait(_observers.map((observer) => observer.dispose()));
    await super.dispose();
  }
}
