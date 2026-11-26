<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# Flutter packages

The packages of this folder depend on Flutter. A Flutter application uses them together with the
pure Dart packages of the [`dart/`](../dart/README.md) folder: the [main README](../README.md)
explains the split.

| Package                                                                   | Description                                                                                                              | Version |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------- |
| [act_abs_peripherals_manager](act_abs_peripherals_manager/)               | Contains useful elements for managing peripherals such as BLE, WiFi, location, etc.                                      |         |
| [act_amplify_api](act_amplify_api/)                                       | This is the package used to add api support to the mobile app                                                            |         |
| [act_amplify_cognito](act_amplify_cognito/)                               | This is the package used to add cognito support to the mobile app                                                        |         |
| [act_amplify_core](act_amplify_core/)                                     | This is the package to manage amplify with our ACT libs                                                                  |         |
| [act_amplify_storage_s3](act_amplify_storage_s3/)                         | This package is a wrapper around the Amplify Storage S3 plugin.                                                          |         |
| [act_app_life_cycle_manager](act_app_life_cycle_manager/)                 | This package contains the manager for the app life cycle.                                                                |         |
| [act_aws_iot_core](act_aws_iot_core/)                                     | Package to interact with aws iot core using amplify credentials                                                          |         |
| [act_barcode](act_barcode/)                                               | This package contains widgets linked to barcodes, QR codes included                                                      |         |
| [act_ble_manager](act_ble_manager/)                                       | This package contains the base for Bluetooth Low Energy                                                                  |         |
| [act_ble_manager_ui](act_ble_manager_ui/)                                 | This contains ui elements to complete the ACT BLE manager                                                                |         |
| [act_config_manager](act_config_manager/)                                 | This package contains methods to manage config variables.                                                                |         |
| [act_consent_manager](act_consent_manager/)                               | This package contains useful methods and classes to manage user consents.                                                |         |
| [act_contextual_views_manager](act_contextual_views_manager/)             | This package is useful to define a skeleton for contextual views                                                         |         |
| [act_enable_service_utility](act_enable_service_utility/)                 | The package contains utility classes to manage the enabling of services                                                  |         |
| [act_ffi_utility](act_ffi_utility/)                                       | This package provides utility functions for working with FFI in Flutter.                                                 |         |
| [act_file_transfer_manager](act_file_transfer_manager/)                   | A Flutter package for managing file transfers.                                                                           |         |
| [act_firebase_core](act_firebase_core/)                                   | This is the main package to manage firebase with our ACT libs                                                            |         |
| [act_firebase_crash](act_firebase_crash/)                                 | Reports the crashes and the logs of an application to Firebase Crashlytics.                                              |         |
| [act_flutter_utility](act_flutter_utility/)                               | This package contains useful methods and classes which extends flutter functionality.                                    |         |
| [act_global_manager](act_global_manager/)                                 | This package contains the default global_manager which has to be extended in the app.                                    |         |
| [act_halo_abstract](act_halo_abstract/)                                   | Contains the abstract and shared elements to manager the HALO protocol                                                   |         |
| [act_halo_ble_layer](act_halo_ble_layer/)                                 | This is the BLE hardware layer for the HALO protocol                                                                     |         |
| [act_halo_manager](act_halo_manager/)                                     | This is the manager for the HALO protocol                                                                                |         |
| [act_http_client_jwt_auth](act_http_client_jwt_auth/)                     | Contains specific server authentication to work with JWT                                                                 |         |
| [act_http_client_manager](act_http_client_manager/)                       | Useful to request third HTTP servers                                                                                     |         |
| [act_http_logging_manager](act_http_logging_manager/)                     | This package contains the HTTP logging manager                                                                           |         |
| [act_http_server_manager](act_http_server_manager/)                       | This package contains the HTTP server manager                                                                            |         |
| [act_internet_connectivity_manager](act_internet_connectivity_manager/)   | The package contains the internet connectivity manager to know when we are connected to internet, or not.                |         |
| [act_intl](act_intl/)                                                     | This package contains non-graphical utilities classes linked to translations.                                            |         |
| [act_intl_ui](act_intl_ui/)                                               | This package contains graphical helpers linked to translations.                                                          |         |
| [act_jwt_utilities](act_jwt_utilities/)                                   | Contains useful classes to manage JWT in mobile app                                                                      |         |
| [act_licenses_manager](act_licenses_manager/)                             | This package manages the licenses of the app and its dependencies.                                                       |         |
| [act_life_cycle](act_life_cycle/)                                         | This package contains a life cycle pattern implementation to manage the life cycle of classes and their dependencies.    |         |
| [act_local_storage_manager](act_local_storage_manager/)                   | This package contains two managers to store properties and secrets                                                       |         |
| [act_location_manager](act_location_manager/)                             | This package is useful to get location from phones                                                                       |         |
| [act_logger_manager](act_logger_manager/)                                 | This package contains a logger manager for your app                                                                      |         |
| [act_music_player_manager](act_music_player_manager/)                     | This package contains a music player manager.                                                                            |         |
| [act_oauth2_core](act_oauth2_core/)                                       | This package contains the common elements to connect to OAuth 2.0 client from Identity Providers.                        |         |
| [act_oauth2_google](act_oauth2_google/)                                   | This package contains the needed elements to connect to a OAuth 2.0 Client through Google Identity Provider.             |         |
| [act_oauth2_keycloak](act_oauth2_keycloak/)                               | This package contains the needed elements to connect to a OAuth 2.0 Client through a Keycloak Identity Provider.         |         |
| [act_ocsigen_halo_manager](act_ocsigen_halo_manager/)                     | This is the manager for the OCSIGEN implementation of HALO                                                               |         |
| [act_permissions_manager](act_permissions_manager/)                       | Useful classes to manager permissions                                                                                    |         |
| [act_platform_manager](act_platform_manager/)                             | Useful class to manage platform                                                                                          |         |
| [act_remote_local_vers_file_manager](act_remote_local_vers_file_manager/) | Act remote localized and versioned file manager.                                                                         |         |
| [act_remote_storage_manager](act_remote_storage_manager/)                 | This package contains the remote storage manager, which can be used to get files from a remote server.                   |         |
| [act_remote_storage_ui](act_remote_storage_ui/)                           | Contains helpful widgets to work with act_remote_storage_manager                                                         |         |
| [act_router_manager](act_router_manager/)                                 | This package contains a router manager.                                                                                  |         |
| [act_shared_auth](act_shared_auth/)                                       | This contains generic and shared elements for authentication services.                                                   |         |
| [act_shared_auth_local_storage](act_shared_auth_local_storage/)           | This contains services to store ids from the authentication services to act secure local storage.                        |         |
| [act_shared_auth_ui](act_shared_auth_ui/)                                 | This package completes the act_shared_auth and offers widgets, blocs, page, etc.                                         |         |
| [act_splash_screen_manager](act_splash_screen_manager/)                   | Keeps the splash screen of the platform displayed until the application is ready                                         |         |
| [act_tb_extender_auth](act_tb_extender_auth/)                             | Signs a user in with Keycloak and exchanges the token for ThingsBoard tokens through the tb-extender broker.             |         |
| [act_tb_extender_client](act_tb_extender_client/)                         | Speaks to the tb-extender broker: exchanges an identity provider token for ThingsBoard tokens, claims and frees devices. |         |
| [act_test_utility](act_test_utility/)                                     | This package contains shared fakes and helpers to write the unit tests of the ACT packages.                              |         |
| [act_themes_manager](act_themes_manager/)                                 | This package contains the manager for the app themes                                                                     |         |
| [act_thingsboard_client](act_thingsboard_client/)                         | Reaches a Thingsboard server, its devices and their telemetry                                                            |         |
| [act_thingsboard_client_ui](act_thingsboard_client_ui/)                   | This package contains widgets, BLoCs and other classes useful to display information from thingsboard servers.           |         |
| [act_tic_manager](act_tic_manager/)                                       | This package contains a tic manager which helps to display HMI in pace                                                   |         |
| [act_web_local_storage_manager](act_web_local_storage_manager/)           | This package contains the web local storage manager                                                                      |         |
| [act_websocket_client_manager](act_websocket_client_manager/)             | This package contains the WebSocket client manager                                                                       |         |
| [act_websocket_core](act_websocket_core/)                                 | This package contains the shared WebSocket classes between server and client                                             |         |
| [act_websocket_server_manager](act_websocket_server_manager/)             | This package contains the WebSocket server manager                                                                       |         |
| [act_yaml_utility](act_yaml_utility/)                                     | This contains utility classes to manage YAML                                                                             |         |
