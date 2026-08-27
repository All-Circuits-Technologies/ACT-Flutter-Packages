// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:act_splash_screen_manager_desktop/act_splash_screen_manager_desktop.dart';
import 'package:flutter/material.dart';

/// Time the example pretends to need to be ready, so that the splash screen can be seen.
const initializationDuration = Duration(seconds: 2);

Future<void> main() async {
  // An application registers the builder in its global manager, and the manager finds the logger
  // of the application by itself. The example has no global manager, so it builds both by hand.
  final manager = DesktopSplashScreenManager(
    logger: LogsHelper.withExternalLogger(
      externalLogger: ConsoleExternalLogger.withMinLevel(),
      category: "example",
    ),
  );
  await manager.initLifeCycle();

  runApp(_ExampleApp(manager: manager));
}

/// Application displaying the image of the splash screen until it is ready, then its own view.
class _ExampleApp extends StatefulWidget {
  /// Manager holding the splash screen of the platform.
  final AbsSplashScreenManager manager;

  /// Class constructor
  const _ExampleApp({required this.manager});

  @override
  State<_ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<_ExampleApp> {
  /// Whether the application is ready to show its own view.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(initializationDuration);
      if (!mounted) {
        return;
      }

      await widget.manager.initAfterView(context);
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "ACT splash screen",
    home: _ready
        ? const Scaffold(body: Center(child: Text("The application is ready")))
        : const SplashScreenCover(image: AssetImage("assets/splash.png")),
  );
}
