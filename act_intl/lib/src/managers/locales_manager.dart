// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_intl/src/mixins/mixin_locale_properties.dart';
import 'package:act_intl/src/observers/locales_observer_widget.dart';
import 'package:act_intl/src/utilities/locale_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// This is the builder for the [LocalesManager].
class LocalesManagerBuilder<P extends MixinLocaleProperties>
    extends AbsManagerBuilder<LocalesManager> {
  /// Class constructor
  LocalesManagerBuilder({
    required List<Locale> Function() getSupportedLocales,
  }) : super(() => LocalesManager(
              getSupportedLocales: getSupportedLocales,
              propertiesGetter: globalGetIt().get<P>,
            ));

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager, P];
}

/// This is the manager that handles the current locale of the application.
/// It allows to subscribe to locale changes and provides the current locale.
///
/// To use this manager, you have to add the [LocalesObserverWidget] in the root
/// tree of your main widget. This widget will catch the locale modification and update
/// the [LocalesManager]. Therefore, if you don't add the widget, you won't be advised of locale
/// update.
///
/// If you want to use this manager to update the wanted locale, you have to use the [wantedLocale]
/// getter with the locale property of the MaterialApp widget.
class LocalesManager extends AbsWithLifeCycle {
  /// This is the category used for logging
  static const _logsCategory = "locales";

  /// This is how we'll allow subscribing to connection changes
  final StreamController<Locale> _currentLocaleCtrl;

  /// This is the stream controller used to set the give the current wanted locale wanted by user
  final StreamController<Locale?> _wantedLocaleCtrl;

  /// This function is used to get the list of supported locales in the app
  final List<Locale> Function() _getSupportedLocales;

  /// This function is used to get the properties manager
  final MixinLocaleProperties Function() _propertiesGetter;

  /// This is the helper used to log messages
  late final LogsHelper _logsHelper;

  /// This is the list of supported locales in the app.
  late final List<Locale> supportedLocales;

  /// This is the current locale of the application.
  Locale _currentLocale;

  /// This is the stream of the current locale.
  Stream<Locale> get currentLocaleStream => _currentLocaleCtrl.stream;

  /// This is the current locale of the application.
  /// If you want to be sure that the locale is set, you should wait for the [initAfterView] method
  /// to be ended.
  Locale get currentLocale => _currentLocale;

  /// This is the locale wanted by the user
  ///
  /// {@template act_intl.LocalesManager.wantedLocale.brief}
  /// This may not match the [_currentLocale] value, in case where the wanted locale is not yet
  /// loaded of if it doesn't exist in the files.
  /// {@endtemplate}
  Locale? _wantedLocale;

  /// This is the stream of the wanted locale.
  Stream<Locale?> get wantedLocaleStream => _wantedLocaleCtrl.stream;

  /// This is the wanted locale of the application.
  ///
  /// {@macro act_intl.LocalesManager.wantedLocale.brief}
  Locale? get wantedLocale => _wantedLocale;

  /// This method is used to set the wanted locale of the application.
  set wantedLocale(Locale? newLocale) {
    final newLocaleLanguageTag = newLocale?.toLanguageTag();
    if (newLocaleLanguageTag == _wantedLocale?.toLanguageTag()) {
      // Nothing to do
      return;
    }

    Locale? newLocaleInSupported;
    if (newLocaleLanguageTag != null) {
      newLocaleInSupported = _findLocaleFromSupportedLocales(newLocaleLanguageTag);
      if (newLocaleInSupported == null) {
        // This wanted locale isn't supported, we don't go further
        _logsHelper.w("The user wants the locale: $newLocaleLanguageTag, but this language "
            "isn't in the supported list; therefore, we do nothing");
        return;
      }
    }

    _wantedLocale = newLocaleInSupported;
    _wantedLocaleCtrl.add(newLocaleInSupported);
    // We save the wanted locale in property without waiting for an answer
    unawaited(_propertiesGetter().wantedLocale.store(newLocaleLanguageTag));

    if (newLocaleInSupported == null) {
      // Nothing more to do
      return;
    }

    // The wanted locale is in the supported locale, so we know that it will become current
    // locale and so we set the current locale.
    _setCurrentLocale(newLocaleInSupported);
  }

  /// Class constructor
  LocalesManager({
    required List<Locale> Function() getSupportedLocales,
    required MixinLocaleProperties Function() propertiesGetter,
  })  : _currentLocale = const Locale.fromSubtags(),
        _currentLocaleCtrl = StreamController<Locale>.broadcast(),
        _wantedLocaleCtrl = StreamController<Locale?>.broadcast(),
        _getSupportedLocales = getSupportedLocales,
        _propertiesGetter = propertiesGetter;

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory);
    supportedLocales = _getSupportedLocales();
    await _initWantedLocale();
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

    _currentLocale = _wantedLocale ??
        // Because the locale is returned by Intl.getCurrentLocale, we suppose that it can't return a
        // wrong value. That's why we expect the Locale created to be not null.
        // We don't call _setCurrentLocale to not emit an event here. We expect that no manager or view
        // call currentLocale getter before this line; therefore, emit an event would be overkill.
        LocaleUtility.localeFromString(string: Intl.getCurrentLocale())!;
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

  /// This method tries to find the given locale in the supported locales.
  ///
  /// This is useful to know if the wantedLocale is supported
  Locale? _findLocaleFromSupportedLocales(String wantedLocaleLanguageTag) {
    for (final locale in supportedLocales) {
      if (locale.toLanguageTag() == wantedLocaleLanguageTag) {
        return locale;
      }
    }

    return null;
  }

  /// This method is used to initialize the wanted locale from the saved properties.
  ///
  /// The supported locales have to be set before calling this method.
  Future<void> _initWantedLocale() async {
    final savedWantedLocale = await _propertiesGetter().wantedLocale.load();
    if (savedWantedLocale == null) {
      // Nothing to do
      return;
    }

    final localeFound = _findLocaleFromSupportedLocales(savedWantedLocale);
    if (localeFound == null) {
      _logsHelper.w("The saved wanted locale: $savedWantedLocale, isn't supported by the app; "
          "therefore we don't use it");
      return;
    }

    _wantedLocale = localeFound;
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait([
      _currentLocaleCtrl.close(),
      _wantedLocaleCtrl.close(),
    ]);
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
