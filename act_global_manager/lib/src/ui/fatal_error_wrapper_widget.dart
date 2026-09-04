// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/src/types/fatal_error_page_types.dart';
import 'package:flutter/widgets.dart';

/// This widget is used to wrap the app with a widget that will display a fatal error page when a
/// fatal error occurs
class FatalErrorWrapperWidget extends StatelessWidget {
  /// The [fatalErrorNotifier] is used to notify the app when a fatal error occurs
  final ValueNotifier<Object?> fatalErrorNotifier;

  /// The [buildFatalErrorPage] is used to build a page to display when a fatal error occurs
  final FatalErrorPageBuilder buildFatalErrorPage;

  /// The [child] is the widget to display when no fatal error occurs
  final Widget child;

  /// Class constructor
  const FatalErrorWrapperWidget({
    super.key,
    required this.fatalErrorNotifier,
    required this.buildFatalErrorPage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Object?>(
    valueListenable: fatalErrorNotifier,
    builder: (BuildContext context, Object? error, Widget? child) {
      if (error == null) {
        return child!;
      }

      return buildFatalErrorPage(error);
    },
    child: child,
  );
}
