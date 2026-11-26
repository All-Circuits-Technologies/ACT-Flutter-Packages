// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';

/// This class reads the raw content of the config files from the assets bundle of the application.
class AssetsConfigReader extends AbsConfigReader {
  /// The path of the assets folder which contains the config files, ending with a separator.
  final String configPath;

  /// Class constructor
  const AssetsConfigReader({required this.configPath});

  /// The location of a config file is its asset key: the [configPath] followed by the [fileName].
  @override
  String locate(String fileName) => "$configPath$fileName";

  /// Read the asset at [location], without caching it: the config files are read once.
  @override
  Future<String?> readRaw(String location) async {
    final result = await AssetsBundleUtility.loadStringFromAssetBundle(location, cache: false);

    if (result.status != AssetsBundleResult.ok) {
      return null;
    }

    return result.value;
  }
}
