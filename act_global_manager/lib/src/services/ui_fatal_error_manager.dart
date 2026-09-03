// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/src/services/abs_global_manager.dart';
import 'package:act_global_manager/src/types/fatal_error_page_types.dart';
import 'package:act_global_manager/src/ui/fatal_error_wrapper_widget.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Build a manager to handle fatal errors in the UI
class UiFatalErrorBuilder extends AbsLifeCycleFactory<UiFatalErrorManager> {
  /// A factory to create the [UiFatalErrorManager], with the [buildFatalErrorPage] used to build
  /// the page to display when a fatal error occurs.
  UiFatalErrorBuilder(FatalErrorPageBuilder buildFatalErrorPage)
    : super(() => UiFatalErrorManager(buildFatalErrorPage: buildFatalErrorPage));

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [];
}

/// This manager is used to handle fatal errors in the UI and display a page when a fatal error
/// occurs.
class UiFatalErrorManager extends AbsWithLifeCycleAndUi {
  /// Indicates whether a fatal error has occurred.
  bool _hasFatalError;

  /// This [ValueNotifier] is used to notify the app when a fatal error occurs
  final ValueNotifier<Object?> _fatalErrorNotifier;

  /// The [_buildFatalErrorPage] is used to build a page to display when a fatal error occurs
  final FatalErrorPageBuilder _buildFatalErrorPage;

  /// {@template act_global_manager.UiFatalErrorManager.fatal_error_will_show_handler}
  /// The handlers are called when a fatal error page is about to be displayed.
  ///
  /// Those handlers will be invoked before the fatal error page is displayed.
  /// {@endtemplate}
  final Set<FatalErrorWillShowHandler> _fatalErrorWillShowHandlers;

  /// Class constructor
  UiFatalErrorManager({required FatalErrorPageBuilder buildFatalErrorPage})
    : _fatalErrorNotifier = ValueNotifier<Object?>(null),
      _buildFatalErrorPage = buildFatalErrorPage,
      _fatalErrorWillShowHandlers = {},
      _hasFatalError = false;

  /// Wrap the app with a widget that will display a fatal error page when a fatal error occurs
  Widget wrapWithFatalErrorWidget({required Widget child}) => FatalErrorWrapperWidget(
    fatalErrorNotifier: _fatalErrorNotifier,
    buildFatalErrorPage: _buildFatalErrorPage,
    child: child,
  );

  /// Display the fatal error page with the given [error]
  ///
  /// This will trigger the display of the fatal error page with the provided [error]. This won't
  /// throw an error itself (and so it won't be catch by logger manager).
  void displayFatalErrorPage(Object error) => _raise(error);

  /// {@macro act_global_manager.UiFatalErrorManager.fatal_error_will_show_handler}
  ///
  /// Adds a handler to be called when a fatal error page is about to be displayed.
  void addFatalErrorWillShowHandler(FatalErrorWillShowHandler handler) {
    _fatalErrorWillShowHandlers.add(handler);
  }

  /// {@macro act_global_manager.UiFatalErrorManager.fatal_error_will_show_handler}
  ///
  /// Removes a handler that was previously added to be called when a fatal error page is about to
  /// be displayed.
  void removeFatalErrorWillShowHandler(FatalErrorWillShowHandler handler) {
    _fatalErrorWillShowHandlers.remove(handler);
  }

  /// Called when a fatal error occurs to notify the app and display the error page
  void _raise(Object error) {
    if (_hasFatalError) {
      // A fatal error has already been raised; the first one, most relevant, stays on screen.
      return;
    }
    _hasFatalError = true;

    // The handlers are notified before the page is shown, each in isolation so that a slow or
    // failing one neither skips the others nor leaks an unhandled error. Their completion is not
    // awaited: the page must appear even if a handler hangs.
    for (final handler in _fatalErrorWillShowHandlers) {
      _notifyWillShowHandler(handler, error);
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      _fatalErrorNotifier.value = error;
    } else {
      // A fatal error raised during a frame: the notifier is set out of the build phase.
      scheduleMicrotask(() => _fatalErrorNotifier.value = error);
    }
  }

  /// Calls one will-show [handler], guarding both a synchronous throw and a rejected future so a
  /// single faulty handler cannot break the others or leak an unhandled error.
  void _notifyWillShowHandler(FatalErrorWillShowHandler handler, Object error) {
    void logHandlerError(Object handlerError) => appLogger().e(
      "An error occurred while notifying a fatal error will show handler: $handlerError",
    );

    try {
      final result = handler(error);
      if (result is Future) {
        unawaited(result.catchError(logHandlerError));
      }
    } catch (handlerError) {
      logHandlerError(handlerError);
    }
  }
}
