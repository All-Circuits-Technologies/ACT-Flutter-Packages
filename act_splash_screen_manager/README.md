<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Splash screen  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
  - [The Dart side](#the-dart-side)
  - [The native side](#the-native-side)
  - [What is built for each platform](#what-is-built-for-each-platform)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Register the manager](#register-the-manager)
  - [Cover the moment the splash screen is removed at](#cover-the-moment-the-splash-screen-is-removed-at)
  - [Android and iOS](#android-and-ios)
  - [Web](#web)
  - [Linux and Windows](#linux-and-windows)
- [Example](#example)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)

## Presentation

This package keeps the splash screen of the platform displayed until the first view of the
application is built, on Android, iOS, the web, Linux and Windows.

The splash screen the platform displays is removed as soon as Flutter is ready, which is before the
managers of the application are. Without this package, the application shows an empty screen during
that time; with it, the splash screen covers the whole initialization.

Who draws the splash screen, and what has to be asked to remove it, differs from one platform to the
other:

| Platforms      | Who draws the splash screen                                       | What the manager asks                                                  |
| -------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Android, iOS   | the platform, from the files `flutter_native_splash` generates    | nothing: the platform removes it by itself once the first frame is out |
| web            | the page hosting the application, generated the same way          | the page to remove it                                                  |
| Linux, Windows | the runner of the application, with the native code of this package | the runner to remove it                                              |

The package brings the three behaviours and picks the right one at runtime. An application depends
on it, registers one builder, and runs everywhere.

## Architecture

### The Dart side

`AbsSplashScreenManager` is the base of the managers, with the life cycle of the views, and it does
one thing at each of its two steps:

- when it is initialized, it holds the first frame back, which leaves the splash screen of the
  platform on the screen,
- when the first view is built, it lets the frames through, then calls `hideNativeSplashScreen`.

The managers of the three families of platforms derive from it, and only differ by what they ask
when the first view is built. They live in `lib/src/platforms/` and are not part of the public API:

| Manager                       | Platforms      | What `hideNativeSplashScreen` does                                            |
| ----------------------------- | -------------- | ----------------------------------------------------------------------------- |
| `MobileSplashScreenManager`   | Android, iOS   | nothing, the platform removes its splash screen by itself                     |
| `WebSplashScreenManager`      | web            | asks the page to remove the splash screen, through `flutter_native_splash`    |
| `DesktopSplashScreenManager`  | Linux, Windows | asks the runner to remove the splash screen, through the `act_splash_screen` method channel |

`SplashScreenBuilder` is the factory to register with. It builds the manager of the platform the
application really runs on, the one `act_platform_manager` reports, and not the one Flutter draws
like: an application is free to tell Flutter to look like another platform, and that must not change
which runner the splash screen is asked to. The builder depends on the logger manager, so that the
messages of the initialization the splash screen covers are already written where the application
writes them.

`SplashScreenCover` draws the image of the splash screen as a widget. Displaying it in the first
view makes the moment the platform removes its own splash screen at invisible.

### The native side

Desktop platforms draw no splash screen of their own: the window of the application is created by
its runner, and stays empty until Flutter paints in it. The native code of this package draws the
splash screen in that window, before the engine is started, and removes it when the application
asks for it. What the user sees is what the mobile platforms give for free: an image from the very
first moment, then the application.

The splash screen is drawn **in the window of the application**, not in a window of its own. There
is one window, which suits an application displayed full screen with no window manager to arrange
anything.

The native code is organised in three pieces per platform, plus what the platforms share:

- `common/splash_config` holds what a splash screen is and reads it from the text of the
  configuration file. It knows no platform, and it is the part the unit tests cover,
- `splash_config_reader` finds the assets of the application and hands the text over,
- `ASplashPresenter` displays the splash screen and removes it,
- `OverlaySplashPresenter` is the presenter which draws in the window of the application.

Linux draws with GTK and Cairo, Windows with Win32 and GDI+. A presenter which opens a window of
its own, the way desktop applications used to, would be another `ASplashPresenter`: the runner would
call it instead, and neither the application nor this package would see the difference.

`DesktopSplashScreenManager` asks the runner to remove the splash screen through the
`act_splash_screen` channel. When the runner of the application draws no splash screen, the manager
says so in the logs and the application starts anyway.

The native code of each platform is documented on its own, for whoever changes it: see
[linux/README.md](linux/README.md) and [windows/README.md](windows/README.md).

### What is built for each platform

One package serves every platform because the Flutter tooling already builds only what the target
needs. The Dart side has no platform-specific import and compiles everywhere; the native code is
declared per platform in the `pubspec.yaml` of the package, and is only compiled for that platform:
`linux/` when the application is built for Linux, `windows/` for Windows, and neither for a mobile
or web build. Depending on this package from a mobile application costs nothing more than the Dart
side.

## How to use

### Installation

Add the package to the `dependencies` of your application:

```yaml
dependencies:
  act_splash_screen_manager:
    path: ../act_splash_screen_manager
```

### Register the manager

```dart
registerManagerAsync<AbsSplashScreenManager>(const SplashScreenBuilder());
```

The call belongs to the `registerManagers` method of the global manager of the application. The
manager which is built is the one of the platform the application runs on.

Nothing else is needed on the Dart side: the manager is initialized with the others, and the first
view removes the splash screen through `initInFirstView` of the global manager. Everything else -
the images, the configuration, the generated files - belongs to each platform, and is described
below. Read the section of every platform your application targets.

### Cover the moment the splash screen is removed at

Display `SplashScreenCover` in the first view, with the same image as the splash screen, so that
the screen shows the same thing before and after the platform removes its splash screen:

```dart
SplashScreenCover(image: AssetImage("assets/graphics/splash.png"))
```

### Android and iOS

Android, the SplashScreen API of Android 12 and later included, and iOS remove their splash screen
by themselves as soon as the first frame is rendered. The manager therefore has nothing to ask them:
holding the first frame back is all these platforms need, and the whole initialization of the
application is covered by the splash screen the platform draws.

The splash screen itself is generated by [flutter_native_splash](https://pub.dev/packages/flutter_native_splash),
which this package brings: there is nothing to add to the `dependencies` of the application.

_The steps below follow the documentation of `flutter_native_splash`._

The splash screen is described in the `pubspec.yaml` of the application, or in a
`flutter_native_splash.yaml` file at its root. The parameters of Android 12 and later live in their
own `android_12` section, because these versions handle splash screens differently.

Then generate the native files, from the root of the application:

```console
> dart run flutter_native_splash:create
```

or

```console
> dart run flutter_native_splash:create --path=flutter_native_splash.yaml
```

The generated files belong to the application and are version controlled with it. Run the command
again whenever the image or the colours change.

### Web

The splash screen of a web application is drawn by the page which hosts it, and that page keeps
drawing it until it is asked to stop. This is the difference with the mobile platforms, which remove
theirs by themselves: here the manager has to ask, which it does once the first view is built.

The page is generated by `flutter_native_splash` too, from the same description and with the same
command as [above](#android-and-ios). The generated files belong to the application and are version
controlled with it.

### Linux and Windows

The runner draws the splash screen before the engine exists, so it cannot ask Flutter anything: it
reads what to draw from the assets of the application, and the runner of the application has to
call the native code of this package.

#### Describe the splash screen

Write `assets/act_splash_screen.properties` at the root of the application:

```properties
# Image displayed by the runner before the application is ready, as the application names it.
image=assets/graphics/splash.png

# Colour drawn behind the image, seen where the image does not reach.
background_color=#000000

# How the image occupies the window: cover or contain.
fit=cover
```

Then declare the file and the image in the assets of the application:

```yaml
flutter:
  assets:
    - assets/
    - assets/graphics/
```

The image is the very one Flutter loads, at the very path Flutter knows it by: there is no second
copy to keep up to date, and changing the image changes the splash screen. An application which
bundles no configuration displays no splash screen, and starts as it did before.

#### Call the splash screen from the Linux runner

In `my_application.cc`, build the splash screen once the window is created, and put the Flutter
view in the container it returns:

```diff
+#include <act_splash_screen_manager/act_splash_screen.h>
+
 #include "flutter/generated_plugin_registrant.h"

   gtk_window_set_default_size(window, 480, 272);
+
+  GtkWidget* content = act_splash_screen_attach(window);
+  gtk_widget_show(GTK_WIDGET(window));

   FlView* view = fl_view_new(project);
   gtk_widget_show(GTK_WIDGET(view));
-  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
+  gtk_container_add(GTK_CONTAINER(content), GTK_WIDGET(view));
```

Showing the window before the view is created is what puts the image on the screen early. The
returned container is the window itself when the application bundles no splash screen, so the same
runner works either way.

#### Call the splash screen from the Windows runner

In `flutter_window.cpp`, draw the splash screen as soon as the window exists, and tell it which
window it covers:

```diff
+#include <act_splash_screen_manager/act_splash_screen.h>
+
 #include "flutter/generated_plugin_registrant.h"

+  ActSplashScreenAttach(GetHandle());
+  Show();
+
   RECT frame = GetClientArea();

   SetChildContent(flutter_controller_->view()->GetNativeWindow());
+  ActSplashScreenSetContent(flutter_controller_->view()->GetNativeWindow());
```

The runner of a Flutter application usually keeps its window hidden until the first frame; here the
window is shown right away, and the view of the application stays hidden until the splash screen is
removed.

## Example

`example/` is a small desktop application wired for Linux and Windows, which stays on its splash
screen for two seconds before showing its own view. It is the quickest way to see the behaviour,
and the way the native code is compiled outside of a real application:

```console
> cd example
> flutter run -d linux
```

## Limitations

- On Linux and Windows, the splash screen does not follow a window which is resized while it is
  displayed. An application displayed full screen, which is what a desktop splash screen is for,
  never notices.
- On Linux and Windows, the image is read from the disk at startup. It is read once, and released
  as soon as the splash screen is removed.
- macOS is not supported: the application starts as it would without this package, with nothing
  held back to hide.

## Troubleshooting

### Android 12 - No icon when debugging or at first launch

This problem has already been noticed by aloiseau (2023/04/11):

> Note: Splash screen logo is not shown on very first app execution. Is is however properly
> displayed on subsequent launches of the app. Also, Samsung UI make logo readable but a little bit
> small.

Because when you debug, you install a new app, it's considered as a first launch.

## Testing

The Dart tests cover the base manager, which holds the first frame back and lets it through, the
three managers of the platforms, and the choice `SplashScreenBuilder` makes over every platform
Flutter knows, so that a platform which is added to Flutter cannot be forgotten here. The desktop
manager is tested against a fake runner answering the channel, and against a runner which draws no
splash screen.

```console
> flutter test
```

The configuration shared by the desktop platforms is covered by GoogleTest, in
`common/test/splash_config_test.cc`. The tests are built with the example, on demand, and the same
sources are compiled by both toolchains:

```console
> cd example
> ACT_SPLASH_BUILD_TESTS=1 flutter build linux --debug
> ./build/linux/x64/debug/plugins/act_splash_screen_manager/act_splash_screen_manager_test
```

What draws on the screen - GTK, Cairo, Win32, GDI+ - is not covered by a test: building and running
`example/` is what exercises it. The `Desktop native` workflow does both on the two platforms
whenever this package changes.
