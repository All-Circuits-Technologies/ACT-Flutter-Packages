// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_intl/src/observers/locales_observer_widget.dart';
import 'package:act_intl/src/utilities/locale_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// This is the builder for the [LocalesManager].
class LocalesManagerBuilder extends AbsManagerBuilder<LocalesManager> {
  /// Class constructor
  LocalesManagerBuilder() : super(LocalesManager.new);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// This is the manager that handles the current locale of the application.
/// It allows to subscribe to locale changes and provides the current locale.
///
/// To use this manager, you have to add the [LocalesObserverWidget] in the root
/// tree of your main widget. This widget will catch the locale modification and update
/// the [LocalesManager]. Therefore, if you don't add the widget, you won't be advised of locale
/// update.
class LocalesManager extends AbsWithLifeCycle {
  /// This is the category used for logging
  static const _logsCategory = "locales";

  /// This is how we'll allow subscribing to connection changes
  final StreamController<Locale> _currentLocaleCtrl;

  /// This is the helper used to log messages
  late final LogsHelper _logsHelper;

  /// This is the current locale of the application.
  Locale _currentLocale;

  /// This is the stream of the current locale.
  Stream<Locale> get currentLocaleStream => _currentLocaleCtrl.stream;

  /// This is the current locale of the application.
  /// If you want to be sure that the locale is set, you should wait for the [initAfterView] method
  /// to be ended.
  Locale get currentLocale => _currentLocale;

  /// Class constructor
  LocalesManager()
      : _currentLocale = const Locale.fromSubtags(),
        _currentLocaleCtrl = StreamController<Locale>.broadcast();

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory);
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initAfterView}
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    // We only search for ancestor and we know that context is still relevant for what we do
    // ignore: use_build_context_synchronously
    final observer = context.findAncestorWidgetOfExactType<LocalesObserverWidget>();
    if (observer == null) {
      _logsHelper.w("To be fully functional you have to add the LocalesObserverWidget in the root "
          "tree of your main widget. The widget catches the locale modification and update the "
          "LocalesManager. Therefore, if you don't add the widget, you won't be advised of local "
          "update");
    }

    // Because the locale is returned by Intl.getCurrentLocale, we suppose that it can't return a
    // wrong value. That's why we expect the Locale created to be not null.
    // We don't call _setCurrentLocale to not emit an event here. We expect that no manager or view
    // call currentLocale getter before this line; therefore, emit an event would be overkill.
    _currentLocale = LocaleUtility.localeFromString(string: Intl.getCurrentLocale())!;
  }

  /// This method is used to set the current locale of the application.
  /// It will emit an event on the [currentLocaleStream] stream if the locale is different.
  void _setCurrentLocale(Locale locale) {
    if (locale == _currentLocale) {
      // Nothing to do
      return;
    }

    _currentLocale = locale;
    _currentLocaleCtrl.add(locale);
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _currentLocaleCtrl.close();
    return super.disposeLifeCycle();
  }
}

/// This is a utility class to set the current locale of the application.
/// It is used internally by the [LocalesObserverWidget] to set the current locale.
sealed class InternalCurrentLocaleSetter {
  /// This method is used to set the current locale of the application.
  /// It is used internally by the [LocalesObserverWidget] to set the current locale.
  static void setCurrentLocale(Locale locale) =>
      globalGetIt().get<LocalesManager>()._setCurrentLocale(locale);
}
