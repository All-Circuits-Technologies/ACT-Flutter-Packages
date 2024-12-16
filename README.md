# ActFlutterPackages

Shared flutter packages for all the Flutter projects:

* [ActAbstractManager](act_abstract_manager/README.md): This package contains the abstract_manager and manager_builder classes which allows to easily create managers
* [ActDartUtility](act_dart_utility/README.md): This package contains useful methods and classes which extends dart functionality.
* [ActEntity](act_entity/README.md): This package contains the entity base class for models.
* [ActFlutterUtility](act_entity/README.md): This package contains useful methods and classes which extends flutter functionality.
* [ActGlobalManager](act_global_manager/README.md): This package contains the default global_manager which has to be extended in the app.
* [ActIntl](act_intl/README.md): This package contains useful classes and widgets which are linked to translations
* [ActLifeCycleManager](act_life_cycle_manager/README.md): This package contains the manager for the life cycle.
* [ActLocationManager](act_location_manager/README.md): This package is useful to get location from phones
* [ActLoggerManager](act_logger_manager/README.md): This package contains a logger manager for your app
* [ActMusicPlayerManager](act_music_player_manager/README.md): This package contains a music player manager.
* [ActQrCode](act_qr_code/README.md): This package contains a QR Code widget ready to use
* [ActRoutesManager](act_routes_manager/README.md): This package contains the abstract_routes_manager to use in flutter application.
* [ActServerRequestManager](act_server_request_manager/README.md): This package contains methods to request a server API
* [ActStoresManager](act_stores_manager/README.md): This package contains two managers to store properties and secrets
* [ActThemesManager](act_themes_manager/README.md): This package contains classes and widgets linked to the App Theme
* [ActThingsboard](act_thingsboard/README.md): This package contains all the needed class to communicate with Thingsboard
* [ActTicManager](act_tic_manager/README.md): This package contains a tic manager which helps to display HMI in pace
* [ActUi](act_ui/README.md): This package contains generic widget components and other specific classes linked
* [ActWiFiManager](act_wifi_manager/README.md): This package contains the WiFi manager

Versionning is managed with Git tags, to access a specific version of a package, you have to add this in the "dependencies" section of your pubspec.yaml file. For instance, with the `act_abstract_manager` package:

```yaml
act_abstract_manager:
  git:
    url: ssh://git@gitlab.act.lan:2211/internal-libraries/software/actflutterpackages.git
    ref: act_abstract_manager_0.0.1
    path: act_abstract_manager
```

This also means that when you update the version of a package you have to create "mirror" tag.

In projects where you have to delivery the source code to client, you can put the packages in a specific folders of your project and instead of using `git` element, you can use path to refer to a folder, for instance:

```yaml
act_abstract_manager:
  path: ../act_abstract_manager
```

It also means that you have to update each pubspec.yaml linked to packages you are using. And to update (copy/paste) the packages manually when it changes on server.
