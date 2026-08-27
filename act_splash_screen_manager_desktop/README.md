<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Splash screen desktop  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Describe the splash screen](#describe-the-splash-screen)
  - [Register the manager](#register-the-manager)
  - [Call the splash screen from the Linux runner](#call-the-splash-screen-from-the-linux-runner)
  - [Cover the moment the splash screen is removed at](#cover-the-moment-the-splash-screen-is-removed-at)
- [Example](#example)
- [Limitations](#limitations)
- [Testing](#testing)

## Presentation

This package brings the splash screen manager of the desktop applications. It completes
[act_splash_screen_manager_core](../act_splash_screen_manager_core/), which holds the first frame
back until the application is ready. Linux is supported; Windows is added next.

Desktop platforms draw no splash screen of their own: the window of the application is created by
its runner, and stays empty until Flutter paints in it. This package draws the splash screen in
that window, before the engine is started, and removes it when the application asks for it. What
the user sees is what the mobile platforms give for free: an image from the very first moment, then
the application.

The splash screen is drawn **in the window of the application**, not in a window of its own. There
is one window, which suits an application displayed full screen with no window manager to arrange
anything.

## Architecture

The native code is organised in a few pieces, plus what the platforms share:

- `common/splash_config` holds what a splash screen is and reads it from the text of the
  configuration file. It knows no platform, and it is the part the unit tests cover,
- `splash_config_reader` finds the assets of the application and hands the text over,
- `ASplashPresenter` displays the splash screen and removes it,
- `OverlaySplashPresenter` is the presenter which draws in the window of the application.

Linux draws with GTK and Cairo. A presenter which opens a window of its own, the way desktop
applications used to, would be another `ASplashPresenter`: the runner would call it instead, and
neither the application nor this package would see the difference. The `common/` code is written to
be shared by a second platform without a change.

`DesktopSplashScreenManager` asks the runner to remove the splash screen through the
`act_splash_screen` channel. When the runner of the application draws no splash screen, the manager
says so in the logs and the application starts anyway.

The native code is documented on its own, for whoever changes it: see
[linux/README.md](linux/README.md).

## How to use

### Installation

Add the package to the `dependencies` of your application, together with the core package:

```yaml
dependencies:
  act_splash_screen_manager_core:
    path: ../act_splash_screen_manager_core
  act_splash_screen_manager_desktop:
    path: ../act_splash_screen_manager_desktop
```

### Describe the splash screen

The runner reads what to draw from the assets of the application, because it draws before the
engine exists and cannot ask Flutter anything. Write
`assets/act_splash_screen.properties` at the root of the application:

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

### Register the manager

```dart
registerManagerAsync<AbsSplashScreenManager>(const DesktopSplashScreenBuilder());
```

The call belongs to the `registerManagers` method of the global manager of the application, and the
registered type is `AbsSplashScreenManager`, the one every family shares.

### Call the splash screen from the Linux runner

In `my_application.cc`, build the splash screen once the window is created, and put the Flutter
view in the container it returns:

```diff
+#include <act_splash_screen_manager_desktop/act_splash_screen.h>
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

### Cover the moment the splash screen is removed at

Display `SplashScreenCover` from the core package in the first view, with the same image, so that
the screen shows the same thing before and after the runner removes the splash screen.

## Example

`example/` is a small application which stays on its splash screen for two seconds before showing
its own view. It is the quickest way to see the behaviour, and the way the native code is compiled
outside of a real application:

```console
> cd example
> flutter run -d linux
```

## Limitations

- The splash screen does not follow a window which is resized while it is displayed. An application
  displayed full screen, which is what a desktop splash screen is for, never notices.
- The image is read from the disk at startup. It is read once, and released as soon as the splash
  screen is removed.

## Testing

The Dart tests answer the channel as a runner would, and check that the manager asks for the splash
screen to be removed once the first view is built, and that an application whose runner draws no
splash screen starts anyway with a warning in its logs.

```console
> flutter test
```

The configuration parser is covered by GoogleTest, in `common/test/splash_config_test.cc`. The
tests are built with the example, on demand:

```console
> cd example
> ACT_SPLASH_BUILD_TESTS=1 flutter build linux --debug
> ./build/linux/x64/debug/plugins/act_splash_screen_manager_desktop/act_splash_screen_manager_desktop_test
```

What draws on the screen - GTK and Cairo - is not covered by a test: building and running
`example/` is what exercises it. The `Desktop native` workflow does both whenever this package
changes.
