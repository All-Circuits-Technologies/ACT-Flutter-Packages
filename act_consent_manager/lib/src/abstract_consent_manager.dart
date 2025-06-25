// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/material.dart';

/// Abstract class which defines a builder for the consent manager specifying
/// the other managers that it depends on.
abstract class AbstractConsentBuilder<T extends AbstractConsentManager>
    extends AbsManagerBuilder<T> {
  /// Class constructor
  AbstractConsentBuilder(super.factory);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [LoggerManager, LocalesManager];
}

/// Abstract class to store consent services and manage them in an application.
abstract class AbstractConsentManager<E extends Enum> extends AbsWithLifeCycle {
  /// Class logger category
  static const String _consentManagerLogCategory = 'consent';

  /// Logs helper
  late final LogsHelper _logsHelper;

  /// List of subscriptions to cancel on dispose
  final List<StreamSubscription> _subscriptions;

  /// Map of consent services
  final Map<E, AbstractConsentService> _services;

  /// List of required [StreamObserver] instances
  final List<StreamObserver> _observers;

  /// Class constructor
  AbstractConsentManager()
      : _services = {},
        _observers = [],
        _subscriptions = [];

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _consentManagerLogCategory,
    );
    final services = await getConsentServices(_logsHelper);
    _services.addAll(services);

    await Future.wait(_services.values.map((service) => service.initLifeCycle()));

    _subscriptions.add(
        globalGetIt().get<LocalesManager>().currentLocaleStream.listen(_onCurrentLocaleUpdate));
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initAfterView}
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    await Future.wait(_services.values.map((service) => service.initAfterView(context)));
  }

  /// {@template act_consent_manager.AbstractConsentManager.getConsentServices}
  /// Provide the [_services] map with the consent type as key and
  /// the service as value
  /// {@endtemplate}
  @protected
  Future<Map<E, AbstractConsentService>> getConsentServices(
    LogsHelper logsHelper,
  );

  /// This method must be implemented by the derived class to return a list of all the
  /// [StreamObserver] instances required by the service to determine the state of the consent.
  @protected
  void onRegisterObserver(StreamObserver observer) => _observers.add(observer);

  /// Get the service for a given [consentType] if it exists
  /// It's up to the implementation to make sure that the requested service
  /// is indeed implemented with the correct type.
  AbstractConsentService<T>? getService<T extends MixinConsentOptions>(E consentType) =>
      _services[consentType] as AbstractConsentService<T>?;

  /// Reset the local consent info for all services when the current locale is updated.
  Future<void> _onCurrentLocaleUpdate(Locale locale) async {
    await Future.wait(_services.values.map((service) => service.resetLocalConsentInfo()));
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait(_services.values.map((service) => service.disposeLifeCycle()));
    await Future.wait(_observers.map((observer) => observer.dispose()));
    await Future.wait(_subscriptions.map((sub) => sub.cancel()));
    await super.disposeLifeCycle();
  }
}
