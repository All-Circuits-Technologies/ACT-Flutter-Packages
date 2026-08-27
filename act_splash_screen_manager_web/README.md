<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Splash screen web  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Register the manager](#register-the-manager)
  - [Generate the splash screen of the page](#generate-the-splash-screen-of-the-page)
- [Testing](#testing)

## Presentation

This package brings the splash screen manager of the web applications. It completes
[act_splash_screen_manager_core](../act_splash_screen_manager_core/), which holds the first frame
back until the application is ready.

The splash screen of a web application is drawn by the page which hosts it, and that page keeps
drawing it until it is asked to stop. This is the difference with the mobile platforms, which
remove theirs by themselves: here the manager has to ask, which it does once the first view is
built.

## How to use

### Installation

Add the package to the `dependencies` of your application, together with the core package:

```yaml
dependencies:
  act_splash_screen_manager_core:
    path: ../act_splash_screen_manager_core
  act_splash_screen_manager_web:
    path: ../act_splash_screen_manager_web
```

The generator is brought by this package, so there is nothing to add to the `dev_dependencies` of
the application.

### Register the manager

```dart
registerManagerAsync<AbsSplashScreenManager>(const WebSplashScreenBuilder());
```

The call belongs to the `registerManagers` method of the global manager of the application, and the
registered type is `AbsSplashScreenManager`, the one every family shares.

### Generate the splash screen of the page

_The steps below follow the documentation of
[flutter_native_splash](https://pub.dev/packages/flutter_native_splash)._

The splash screen is described in the `pubspec.yaml` of the application, or in a
`flutter_native_splash.yaml` file at its root. Then generate the files of the page, from the root
of the application:

```console
> dart run flutter_native_splash:create
```

The generated files belong to the application and are version controlled with it.

## Testing

The tests check that the manager is one of the family and that it holds the first frame back until
the first view is built. The page is asked to remove its splash screen through a plugin which only
answers on a browser, so a test running on the virtual machine cannot observe that call.

```console
> flutter test
```
