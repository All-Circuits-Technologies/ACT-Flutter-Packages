<!--
SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ActFlutterPackages

Shared flutter packages for all the Flutter projects:

* [ActAbstractManager](act_abstract_manager/README.md): This package contains the abstract_manager
  and manager_builder classes which allows to easily create managers
* [ActDartUtility](act_dart_utility/README.md): This package contains useful methods and classes
  which extends dart functionality.
* [ActEntity](act_entity/README.md): This package contains the entity base class for models.
* [ActFlutterUtility](act_entity/README.md): This package contains useful methods and classes which
  extends flutter functionality.
* [ActGlobalManager](act_global_manager/README.md): This package contains the default global_manager
  which has to be extended in the app.
* [ActIntl](act_intl/README.md): This package contains useful classes and widgets which are linked
  to translations
* [ActLifeCycleManager](act_life_cycle_manager/README.md): This package contains the manager for the
  life cycle.
* [ActLocationManager](act_location_manager/README.md): This package is useful to get location from
  phones
* [ActLoggerManager](act_logger_manager/README.md): This package contains a logger manager for your
  app
* [ActMusicPlayerManager](act_music_player_manager/README.md): This package contains a music player
  manager.
* [ActQrCode](act_qr_code/README.md): This package contains a QR Code widget ready to use
* [ActRoutesManager](act_routes_manager/README.md): This package contains the
  abstract_routes_manager to use in flutter application.
* [ActServerRequestManager](act_server_request_manager/README.md): This package contains methods to
  request a server API
* [ActStoresManager](act_stores_manager/README.md): This package contains two managers to store
  properties and secrets
* [ActThemesManager](act_themes_manager/README.md): This package contains classes and widgets linked
  to the App Theme
* [ActThingsboard](act_thingsboard/README.md): This package contains all the needed class to
  communicate with Thingsboard
* [ActTicManager](act_tic_manager/README.md): This package contains a tic manager which helps to
  display HMI in pace
* [ActUi](act_ui/README.md): This package contains generic widget components and other specific
  classes linked

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
