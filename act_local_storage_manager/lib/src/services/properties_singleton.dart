// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PropertiesSingleton extends AbsWithLifeCycle {
  static PropertiesSingleton? _instance;

  static PropertiesSingleton get instance => _instance!;

  static PropertiesSingleton createInstance(SharedPreferences prefs) {
    _instance ??= PropertiesSingleton._(prefs: prefs);
    return _instance!;
  }

  final SharedPreferences prefs;

  PropertiesSingleton._({
    required this.prefs,
  });
}
