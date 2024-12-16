// Copyright (c) 2020. BMS Circuits

import 'package:act_stores_manager/act_stores_manager.dart';

// Export the store manager to avoid to have multiple files to import for using
// store manager
export 'package:act_stores_manager/act_stores_manager.dart';

abstract class TbPropertiesManager extends AbstractPropertiesManager {
  /// Store the list of known devices of the current user
  final devicesList = SharedPreferencesItem<String>("devicesList");

  TbPropertiesManager() : super();
}
