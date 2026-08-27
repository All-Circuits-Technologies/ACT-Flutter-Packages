<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Splash screen core  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
- [The packages of the family](#the-packages-of-the-family)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Register the manager](#register-the-manager)
  - [Cover the moment the splash screen is removed at](#cover-the-moment-the-splash-screen-is-removed-at)
- [How to support a new platform](#how-to-support-a-new-platform)
- [Testing](#testing)

## Presentation

This package keeps the native splash screen of an application displayed until its first view is
built.

The splash screen the platform displays is removed as soon as Flutter is ready, which is before the
managers of the application are. Without this manager, the application shows an empty screen during
that time; with it, the splash screen covers the whole initialization.

The package does not draw the splash screen and does not generate it either: the images and the
colors belong to the generator of the platform. It does not know the platforms it runs on either:
it holds the frames back, and asks the platform to remove its splash screen through a method the
packages of the family implement.

## Architecture

`AbsSplashScreenManager` is the base of the managers, with the life cycle of the views, and it does
one thing at each of its two steps:

- when it is initialized, it holds the first frame back, which leaves the native splash screen on
  the screen,
- when the first view is built, it lets the frames through, then calls `hideNativeSplashScreen`.

`AbsSplashScreenBuilder` is the base of the factories to register the managers with. It depends on
the logger manager, so that the messages of the initialization it covers are already written where
the application writes them.

`SplashScreenCover` draws the image of the splash screen as a widget. Displaying it in the first
view makes the moment the platform removes its own splash screen at invisible.

## The packages of the family

This package brings no platform specific code. Depending on where the application runs, add the
package which does:

| Package                             | Platforms      | What it does                                                            |
| ----------------------------------- | -------------- | ----------------------------------------------------------------------- |
| `act_splash_screen_manager_mobile`  | Android, iOS   | nothing to ask: the platform removes its splash screen by itself        |
| `act_splash_screen_manager_web`     | web            | asks the generated page to remove the splash screen                     |
| `act_splash_screen_manager_desktop` | Linux, Windows | asks the runner of the application to remove the splash screen it draws |
| `act_splash_screen_manager`         | all of them    | chooses the right one for the platform the application runs on          |

An application which targets a single family depends on this package plus that family; an
application which targets several depends on `act_splash_screen_manager`, which brings them all.
Never depend on both: `SplashScreenBuilder` would then be declared twice.

## How to use

### Installation

Add the package to the `dependencies` of your package, together with the package of your platform:

```yaml
dependencies:
  act_splash_screen_manager_core:
    path: ../act_splash_screen_manager_core
```

### Register the manager

The builder of the platform is registered like any other manager:

```dart
class AppGlobalManager extends AbsUiGlobalManager {
  @override
  Future<void> registerManagers() async {
    registerManagerAsync<LoggerManager>(...);
    registerManagerAsync<AbsSplashScreenManager>(const DesktopSplashScreenBuilder());
  }
}
```

The registered type is `AbsSplashScreenManager` and not the manager of the platform: every family
brings its own, and an application which reads the manager back asks for the abstraction.

Nothing else is needed: the manager is initialized with the others, and the first view removes the
splash screen through `initInFirstView` of the global manager.

### Cover the moment the splash screen is removed at

Display the image of the splash screen in the first view, so that the screen shows the same thing
before and after the platform removes its own:

```dart
SplashScreenCover(image: AssetImage("assets/graphics/splash.png"))
```

## How to support a new platform

Derive `AbsSplashScreenManager` and implement `hideNativeSplashScreen`, then derive
`AbsSplashScreenBuilder` and give it the constructor of the manager:

```dart
class MySplashScreenManager extends AbsSplashScreenManager {
  @override
  Future<void> hideNativeSplashScreen() async => ...;
}

class MySplashScreenBuilder extends AbsSplashScreenBuilder {
  const MySplashScreenBuilder() : super(MySplashScreenManager.new);
}
```

The frames are held back and let through by the base class: a derived class only has to remove what
the platform draws.

## Testing

The tests drive the manager through its two steps and read the binding of the test to check what an
application would see: the frames are held back once the manager is initialized, they are let
through once the first view is built, and the platform is then asked to remove its splash screen. A
manager which is asked to remove a splash screen it never preserved is covered too.

The images and the native files are out of reach of a test: they are generated at build time, by
the generator of each platform.

```console
> flutter test
```
