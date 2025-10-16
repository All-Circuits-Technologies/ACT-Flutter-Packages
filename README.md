<!--
SPDX-FileCopyrightText: 2023, 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ActFlutterPackages  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [mono\_repo](#mono_repo)
- [Packages list](#packages-list)
- [How to use the packages in your project](#how-to-use-the-packages-in-your-project)
- [Add a new package](#add-a-new-package)

## Presentation

Shared flutter packages for all the Flutter projects.

## mono_repo

[mono_repo](https://github.com/google/mono_repo.dart) is used to manage multiple flutter packages
within a single repository.

We are using it to generate github actions and the packages list.

To install it globally, you have to call:

```console
> dart pub global activate mono_repo
```

## Packages list

| Package                                                                   | Description                                                                                                    | Version |
| ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ------- |
| [act_abs_peripherals_manager](act_abs_peripherals_manager/)               | Contains useful elements for managing peripherals such as BLE, WiFi, location, etc.                            |         |
| [act_abstract_manager](act_abstract_manager/)                             | This package contains the base for all the managers                                                            |         |
| [act_amplify_api](act_amplify_api/)                                       | This is the package used to add api support to the mobile app                                                  |         |
| [act_amplify_cognito](act_amplify_cognito/)                               | This is the package used to add cognito support to the mobile app                                              |         |
| [act_amplify_core](act_amplify_core/)                                     | This is the package to manage amplify with our ACT libs                                                        |         |
| [act_amplify_storage_s3](act_amplify_storage_s3/)                         | This package is a wrapper around the Amplify Storage S3 plugin.                                                |         |
| [act_aws_iot_core](act_aws_iot_core/)                                     | Package to interact with aws iot core using amplify credentials                                                |         |
| [act_ble_manager](act_ble_manager/)                                       | This package contains the base for Bluetooth Low Energy                                                        |         |
| [act_ble_manager_ui](act_ble_manager_ui/)                                 | This contains ui elements to complete the ACT BLE manager                                                      |         |
| [act_config_manager](act_config_manager/)                                 | This package contains methods to manage config variables.                                                      |         |
| [act_consent_manager](act_consent_manager/)                               | This package contains useful methods and classes to manage user consents.                                      |         |
| [act_contextual_views_manager](act_contextual_views_manager/)             | This package is useful to define a skeleton for contextual views                                               |         |
| [act_dart_utility](act_dart_utility/)                                     | This package contains useful methods and classes which extends dart functionality.                             |         |
| [act_enable_service_utility](act_enable_service_utility/)                 | The package contains utility classes to manage the enabling of services                                        |         |
| [act_entity](act_entity/)                                                 | This package contains the entity base class for models.                                                        |         |
| [act_firebase_core](act_firebase_core/)                                   | This is the main package to manage firebase with our ACT libs                                                  |         |
| [act_firebase_crash](act_firebase_crash/)                                 | A new Flutter package project.                                                                                 |         |
| [act_flutter_utility](act_flutter_utility/)                               | This package contains useful methods and classes which extends flutter functionality.                          |         |
| [act_global_manager](act_global_manager/)                                 | This package contains the default global_manager which has to be extended in the app.                          |         |
| [act_halo_abstract](act_halo_abstract/)                                   | Contains the abstract and shared elements to manager the HALO protocol                                         |         |
| [act_halo_ble_layer](act_halo_ble_layer/)                                 | This is the BLE hardware layer for the HALO protocol                                                           |         |
| [act_halo_manager](act_halo_manager/)                                     | This is the manager for the HALO protocol                                                                      |         |
| [act_http_client_jwt_auth](act_http_client_jwt_auth/)                     | Contains specific server authentication to work with JWT                                                       |         |
| [act_http_client_manager](act_http_client_manager/)                       | Useful to request third HTTP servers                                                                           |         |
| [act_http_core](act_http_core/)                                           | This package contains the core HTTP functionalities                                                            |         |
| [act_http_logging_manager](act_http_logging_manager/)                     | This package contains the HTTP logging manager                                                                 |         |
| [act_internet_connectivity_manager](act_internet_connectivity_manager/)   | The package contains the internet connectivity manager to know when we are connected to internet, or not.      |         |
| [act_intl](act_intl/)                                                     | This package contains non-graphical utilities classes linked to translations.                                  |         |
| [act_intl_ui](act_intl_ui/)                                               | This package contains graphical helpers linked to translations.                                                |         |
| [act_jwt_utilities](act_jwt_utilities/)                                   | Contains useful classes to manage JWT in mobile app                                                            |         |
| [act_launcher_icon](act_launcher_icon/)                                   | Useful package to generate launcher icons for the apps                                                         |         |
| [act_life_cycle_manager](act_life_cycle_manager/)                         | This package contains the manager for the life cycle.                                                          |         |
| [act_local_storage_manager](act_local_storage_manager/)                   | This package contains two managers to store properties and secrets                                             |         |
| [act_location_manager](act_location_manager/)                             | This package is useful to get location from phones                                                             |         |
| [act_logger_manager](act_logger_manager/)                                 | This package contains a logger manager for your app                                                            |         |
| [act_music_player_manager](act_music_player_manager/)                     | This package contains a music player manager.                                                                  |         |
| [act_oauth2_core](act_oauth2_core/)                                       | This package contains the common elements to connect to OAuth 2.0 client from Identity Providers.              |         |
| [act_oauth2_google](act_oauth2_google/)                                   | This package contains the needed elements to connect to a OAuth 2.0 Client through Google Identity Provider.   |         |
| [act_ocsigen_halo_manager](act_ocsigen_halo_manager/)                     | This is the manager for the OCSIGEN implementation of HALO                                                     |         |
| [act_permissions_manager](act_permissions_manager/)                       | Useful classes to manager permissions                                                                          |         |
| [act_platform_manager](act_platform_manager/)                             | Useful class to manage platform                                                                                |         |
| [act_qr_code](act_qr_code/)                                               | This package contains a QR Code widget ready to use                                                            |         |
| [act_remote_local_vers_file_manager](act_remote_local_vers_file_manager/) | Act remote localized and versioned file manager.                                                               |         |
| [act_remote_storage_manager](act_remote_storage_manager/)                 | This package contains the remote storage manager, which can be used to get files from a remote server.         |         |
| [act_remote_storage_ui](act_remote_storage_ui/)                           | Contains helpful widgets to work with act_remote_storage_manager                                               |         |
| [act_router_manager](act_router_manager/)                                 | This package contains a router manager.                                                                        |         |
| [act_shared_auth](act_shared_auth/)                                       | This contains generic and shared elements for authentication services.                                         |         |
| [act_shared_auth_local_storage](act_shared_auth_local_storage/)           | This contains services to store ids from the authentication services to act secure local storage.              |         |
| [act_shared_auth_ui](act_shared_auth_ui/)                                 | This package completes the act_shared_auth and offers widgets, blocs, page, etc.                               |         |
| [act_splash_screen_manager](act_splash_screen_manager/)                   | Useful package to support native splash screens in mobile applications                                         |         |
| [act_thingsboard_client](act_thingsboard_client/)                         | Helpful package to use the Thingsboard client with app                                                         |         |
| [act_thingsboard_client_ui](act_thingsboard_client_ui/)                   | This package contains widgets, BLoCs and other classes useful to display information from thingsboard servers. |         |
| [act_tic_manager](act_tic_manager/)                                       | This package contains a tic manager which helps to display HMI in pace                                         |         |
| [act_web_local_storage_manager](act_web_local_storage_manager/)           | This package contains the web local storage manager                                                            |         |
| [act_websocket_client_manager](act_websocket_client_manager/)             | This package contains the WebSocket client manager                                                             |         |
| [act_websocket_core](act_websocket_core/)                                 | This package contains the shared WebSocket classes between server and client                                   |         |
| [act_yaml_utility](act_yaml_utility/)                                     | This contains utility classes to manage YAML                                                                   |         |

To generate this list, you can call:

```console
> dart pub global run mono_repo readme --pad
```

This will print a markdown table to copy/paste here each time we add or remove a package.

## How to use the packages in your project

To use the libraries in your project, we recommend you to bind this repo as a /actlibs git submodule
in your project.

In the `pubspec.yaml` you will have to link them like this:

```yaml
act_abstract_manager:
  git:
    path: actlibs/act_abstract_manager
```

For each project which includes those libs, you have to create a branch in this repository and point
on it. This way, you are independent of the others projects but can get improvements or bugs
corrections from others.

Because, this code isn't reviewed if no merge request is done to the master branch, it's recommended
to oftenly create merge requests from the project branch to master.

## Add a new package

To add a new package to actlibs, at the root of `actlibs` folder you can call:

```console
> flutter create --template=package <your_package_name>
```

Then, in the `pubspec.yaml` you will have to set:

```yaml
publish_to: none
```

You will need to create a `mono_pkg.yaml` file with at least the stage: `analyze`.

Then, you will have to call the next command to generate the github action linked to this
package:

```console
> dart pub global run mono_repo generate
```
