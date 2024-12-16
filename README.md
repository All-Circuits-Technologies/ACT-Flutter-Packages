<!--
SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ActFlutterPackages  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Packages list](#packages-list)
- [How to use the packages in your project](#how-to-use-the-packages-in-your-project)

## Presentation

Shared flutter packages for all the Flutter projects:

## Packages list

| Package name                                                                     | Description                                                                                                                                                   |
| -------------------------------------------------------------------------------- |---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [act_abs_peripherals_manager](act_abs_peripherals_manager/README.md)             | This package contains useful elements for managing peripherals such as BLE, WiFi, location, etc.                                                              |
| [act_abstract_manager](act_abstract_manager/README.md)                           | This package contains the abstract_manager                                                                                                                    |
| [act_amplify_cognito](act_amplify_cognito/README.md)                             | This package is linked to [amplify core package](act_amplify_core/README.md) and adds the support of amplify cognito.                                         |
| [act_amplify_core](act_amplify_core/README.md)                                   | This package contains the link to flutter amplify and allow to use amplify with the act libraries.                                                            |
| [act_ble_manager](act_ble_manager/README.md)                                     | This package helps to manage BLE in app. It also manages the permission and BLE enabling.                                                                     |
| [act_ble_manager_ui](act_ble_manager_ui/README.md)                               | This package completes the [ACT BLE manager package](act_ble_manager/README.md) and contains views, blocs, widgets, etc. which can be used with it.           |
| [act_config_manager](act_config_manager/README.md)                               | This package contains methods to manage config variables.                                                                                                     |
| [act_contextual_views_manager](act_contextual_views_manager/README.md)           | This package contains the skeleton for building contextual views in managers. Each app has to define how they want to create their contextual views.          |
| [act_dart_utility](act_dart_utility/README.md)                                   | This package contains useful methods and classes which extends dart features.                                                                                 |
| [act_enable_service_utility](act_enable_service_utility/README.md)               | The package contains utility classes to manage the services which may be enabled.                                                                             |
| [act_entity](act_entity/README.md)                                               | This package contains the entity base class for models.                                                                                                       |
| [act_firebase_core](act_firebase_core/README.md)                                 | This package contains the link to flutter firebase and allow to use firebase with the act libraries.                                                          |
| [act_firebase_crash](act_firebase_crash/README.md)                               | This package adds Firebase Crashlytics to the mobile app. It needs `act_firebase_core` to work.                                                               |
| [act_flutter_utility](act_flutter_utility/README.md)                             | This package contains generic widgets and classes which extends the flutter features.                                                                         |
| [act_global_manager](act_global_manager/README.md)                               | This package contains the default global_manager which has to be extended in the app.                                                                         |
| [act_halo_abstract](act_halo_abstract/README.md)                                 | This package contains the common elements for each piece of the HALO protocol                                                                                 |
| [act_halo_ble_layer](act_halo_ble_layer/README.md)                               | This package contains the BLE hardware layer for using the HALO protocol through BLE                                                                          |
| [act_halo_manager](act_halo_manager/README.md)                                   | This package contains the HALO manager and the high level API                                                                                                 |
| [act_internet_connectivity_manager](act_internet_connectivity_manager/README.md) | The package contains the internet connectivity manager to know when we are connected to internet, or not                                                      |
| [act_intl](act_intl/README.md)                                                   | This package contains useful classes and widgets which are linked to translations                                                                             |
| [act_jwt_manager](act_jwt_manager/README.md)                                     | This package contains useful tools to manage JWT in the project                                                                                               |
| [act_launcher_icon](act_launcher_icon/README.md)                                 | This package helps to generate launcher icons                                                                                                                 |
| [act_life_cycle_manager](act_life_cycle_manager/README.md)                       | This package contains the manager for the life cycle                                                                                                          |
| [act_location_manager](act_location_manager/README.md)                           |                                                                                                                                                               |
| [act_logger_manager](act_logger_manager/README.md)                               | This package contains a logger manager for your app                                                                                                           |
| [act_music_player_manager](act_music_player_manager/README.md)                   | This package contains a music player manager.                                                                                                                 |
| [act_ocsigen_halo_manager](act_ocsigen_halo_manager/README.md)                   | This package contains the OCSIGEN HALO manager and the high level API                                                                                         |
| [act_permissions_manager](act_permissions_manager/README.md)                     | This package contains a manager to request for permissions                                                                                                    |
| [act_platform_manager](act_platform_manager/README.md)                           | This package contains a platform manager for your app                                                                                                         |
| [act_qr_code](act_qr_code/README.md)                                             | This package contains a QR Code widget ready to use                                                                                                           |
| [act_router_manager](act_router_manager/README.md)                               | This package contains a router manager.                                                                                                                       |
| [act_server_req_jwt_logins](act_server_req_jwt_logins/README.md)                 | This package contains specific server logins to work with JWT.                                                                                                |
| [act_server_req_manager](act_server_req_manager/README.md)                       | This package contains methods and classes to request third servers.                                                                                           |
| [act_shared_auth](act_shared_auth/README.md)                                     | This package abstracts the call of user authentication service                                                                                                |
| [act_shared_auth_ui](act_shared_auth_ui/README.md)                               | This package completes the [ACT Shared authentication package](act_shared_auth/README.md) and contains views, blocs, widgets, etc. which can be used with it. |
| [act_splash_screen_manager](act_splash_screen_manager/README.md)                 | This package helps to support native splash screen.                                                                                                           |
| [act_stores_manager](act_stores_manager/README.md)                               | This package contains two managers to store properties and secrets                                                                                            |
| [act_themes_manager](act_themes_manager/README.md)                               | This package contains classes and widgets linked to the App Theme                                                                                             |
| [act_thingsboard_client](act_thingsboard_client/README.md)                       | This package contains classes to use the Thingsboard client with app                                                                                          |
| [act_thingsboard_client_ui](act_thingsboard_client_ui/README.md)                 | This package contains widgets, BLoCs and other classes useful to help the displaying of information coming from the thingsboard server.                       |
| [act_tic_manager](act_tic_manager/README.md)                                     | This package contains a tic manager which helps to display HMI in pace                                                                                        |
| ~~[act_ui](act_ui/README.md)~~                                                   | **Deprecated** This package contains generic widget components and other specific classes linked. _Better to use the package `act_flutter_utility`_           |
| [act_wifi_manager](act_wifi_manager/README.md)                                   | This package helps to manage WiFi in app. It also manages the permission and WiFi enabling.                                                                   |
| [act_yaml_utility](act_yaml_utility/README.md)                                   | This package contains useful methods and classes to manage YAML files in the app.                                                                             |

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
