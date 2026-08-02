// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_test_utility/src/fakes/silent_logger.dart';

/// A global manager which stands in for the one of an application.
///
/// A class which calls `appLogger` or `globalGetIt` needs the application to have a global manager;
/// without one, those shortcuts throw. This manager gives the test one, with a logger it chooses
/// and without any of the managers of a real application.
///
/// Install it before the class under test is built, and forget the managers it holds once the test
/// is over:
///
/// ```dart
/// void main() {
///   late FakeGlobalManager globalManager;
///
///   setUp(() => globalManager = FakeGlobalManager.install());
///   tearDown(() => globalManager.reset());
///
///   test("logs a warning when the packet is empty", () {
///     ...
///   });
/// }
/// ```
class FakeGlobalManager extends AbsGlobalManager {
  /// The logger the test reads the messages of the class under test from.
  final MixinActLogger _logger;

  /// The logger the shortcut of the application returns.
  @override
  MixinActLogger get defaultLogger => _logger;

  /// Class constructor.
  ///
  /// The manager logs nothing unless the test gives it a [logger] to record the messages with.
  FakeGlobalManager({MixinActLogger? logger})
    : _logger = logger ?? const SilentLogger(),
      super.create();

  /// Builds a manager and sets it as the one of the application.
  ///
  /// The manager of the previous test is replaced, so a test never sees the managers of another
  /// one through the shortcuts.
  static FakeGlobalManager install({MixinActLogger? logger}) {
    final manager = FakeGlobalManager(logger: logger);
    AbsGlobalManager.setInstance = manager;

    return manager;
  }

  /// Registers [builder] the way an application registers one of its managers.
  void register<T extends AbsWithLifeCycle>(AbsLifeCycleFactory<T> builder) =>
      registerManagerAsync<T>(builder);

  /// Waits for the registered managers to be built and initialized.
  Future<void> allReady() => managers.allReady();

  /// Forgets the registered managers.
  ///
  /// The instance which serves the shortcuts is shared by the whole test file, so a test which
  /// registers a manager has to call this once it is over, otherwise the next test finds it
  /// already registered.
  Future<void> reset() => managers.reset();

  /// {@macro act_global_manager.AbsGlobalManager.registerManagers}
  @override
  Future<void> registerManagers() async {}
}
