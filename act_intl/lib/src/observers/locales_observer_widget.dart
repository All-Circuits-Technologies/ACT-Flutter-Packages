// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_intl/src/managers/locales_manager.dart';
import 'package:flutter/widgets.dart';

/// This widget is used to observe the locale changes in the application.
/// It should be added in the root widget of the application to catch locale changes and to be
/// accessible from the managers when calling initAfterView method.
class LocalesObserverWidget extends StatefulWidget {
  /// The child widget to display inside this widget.
  /// If null, an empty widget will be displayed.
  final Widget? child;

  /// Class constructor
  const LocalesObserverWidget({
    super.key,
    this.child,
  });

  /// Create the state of this widget.
  @override
  State<LocalesObserverWidget> createState() => _LocalesObserverWidgetState();
}

/// This is the state of the [LocalesObserverWidget].
/// It implements the [WidgetsBindingObserver] to catch locale changes in the application.
class _LocalesObserverWidgetState extends State<LocalesObserverWidget> with WidgetsBindingObserver {
  /// Initialize the widget state.
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  /// This method is called when the locales of the application change.
  /// It will set the current locale in the [LocalesManager] and notify the listeners.
  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);

    final currentLocale = locales?.first;
    if (currentLocale == null) {
      // Nothing to do
      return;
    }

    InternalCurrentLocaleSetter.setCurrentLocale(locales!.first);
  }

  /// Build the widget tree for this state.
  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();

  /// Dispose the widget state.
  /// It will remove the observer from the [WidgetsBinding] to avoid memory leaks.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
