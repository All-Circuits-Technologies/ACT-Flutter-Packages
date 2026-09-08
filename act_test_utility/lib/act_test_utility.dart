// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

// The fakes which do not need Flutter live in act_dart_test_utility. They are re-exported here so
// a Flutter package still reaches every fake through this single import.
export 'package:act_dart_test_utility/act_dart_test_utility.dart';

export 'src/fakes/fake_assets.dart';
export 'src/fakes/fake_external_logger.dart';
export 'src/fakes/fake_global_manager.dart';
