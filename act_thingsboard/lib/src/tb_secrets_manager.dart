// Copyright (c) 2020. BMS Circuits

import 'package:act_stores_manager/act_stores_manager.dart';

// Export the store manager to avoid to have multiple files to import for using
// store manager
export 'package:act_stores_manager/act_stores_manager.dart';

abstract class TbSecretsManager extends AbstractSecretsManager {
  /// Last user used to log in to Thingsboard server.
  ///
  /// See also [thingsboardUserPassword].
  final thingsboardUserEmail = SecretItem<String>("thingsboardUserEmail");

  /// Thingsboard password of current [thingsboardUserEmail] user.
  ///
  /// See also [thingsboardUserEmail].
  final thingsboardUserPassword = SecretItem<String>(
    "thingsboardUserPassword",
    doNotMigrate: true,
  );

  /// Thingsboard long life-cycle refresh token.
  ///
  /// See also [thingsboardToken].
  final thingsboardRefreshToken = SecretItem<String>(
    "thingsboardRefreshToken",
    doNotMigrate: true,
  );

  /// Thingsboard short life-cycle token.
  ///
  /// See also [thingsboardRefreshToken].
  final thingsboardToken = SecretItem<String>(
    "thingsboardToken",
    doNotMigrate: true,
  );

  TbSecretsManager() : super();
}
