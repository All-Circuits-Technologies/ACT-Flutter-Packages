<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# Creating an ACT Flutter project <!-- omit from toc -->

How to bootstrap a new Flutter application on top of the ACT Flutter packages, from an empty
`flutter create` to a running skeleton (global manager, configuration, logging, i18n, theme,
routing, error handling, tests).

The guide has two complementary parts:

- **[Project profile](#project-profile-the-questions-to-answer)** - the decisions to make before
  writing any code. Each decision has a stable id (`Q<n>`) and lists what it drives.
- **[Bootstrap procedure](#bootstrap-procedure)** - the ordered steps that turn those answers into
  a skeleton. Each step has a stable id (`PS<n>`) so it can be cited in review or automation.

This document is project-agnostic and reusable across every ACT app (desktop, web, mobile). It
never restates the coding rules: it references the [Flutter coding standards][flutter-rules] (rules
`RD<n>`/`RFL<n>`) and the per-package `README.md` files instead. Examples use a placeholder app
named `foo_app` with project code `Foo`; substitute your own.

## Table of content <!-- omit from toc -->

- [Project profile (the questions to answer)](#project-profile-the-questions-to-answer)
- [Bootstrap procedure](#bootstrap-procedure)
- [Optional capabilities](#optional-capabilities)
- [Platform specifics](#platform-specifics)
- [Generated code and tooling](#generated-code-and-tooling)
- [Verification checklist](#verification-checklist)
- [Sources](#sources)

## Project profile (the questions to answer)

Answer these before writing code; unanswered optional rows can be skipped and added later.

| Id  | Question                 | Options / format                                                | Default    |
| --- | ------------------------ | --------------------------------------------------------------- | ---------- |
| Q1  | Package name             | `snake_case` (`foo_app`)                                        | -          |
| Q2  | Project code             | short PascalCase prefix (`Foo`)                                 | -          |
| Q3  | Organisation / bundle id | reverse-DNS (`com.acme.fooapp`)                                 | -          |
| Q4  | actlibs submodule folder | path + folder name for the ACT packages submodule               | `actlibs/` |
| Q5  | Target platforms         | any of desktop (linux/windows/macos), web, mobile (android/ios) | -          |
| Q6  | Locales                  | list of `xx_YY` + main locale                                   | one locale |
| Q7  | In-app language switcher | yes / no                                                        | no         |
| Q8  | Persistent local storage | none / properties / secrets / both                              | none       |
| Q9  | Theming                  | single theme / multiple themes                                  | single     |
| Q10 | Splash screen            | yes / no                                                        | yes        |

The mandatory core - the configuration manager, the logger, the fatal-error manager and the router,
all assembled under the global manager - is always set up, in that dependency order, regardless of
the optional answers.

## Bootstrap procedure

Run the steps in order: later steps register managers that depend on earlier ones. The registration
order assembled in PS12 mirrors this sequence.

### PS1 - Create the Flutter app for the target platforms <!-- omit from toc -->

Create the app restricted to the platforms from Q5, with the organisation from Q3:

```console
> flutter create --org com.acme --platforms=linux,web,android foo_app
```

Add or drop platforms later with `flutter create --platforms=<list> .` from the app root.

### PS2 - Fix the package name and project code <!-- omit from toc -->

Set the package name (Q1) in `pubspec.yaml` (`name: foo_app`) and always add `publish_to: "none"`:
these apps are never published to pub.dev. Adopt the project code (Q2) as the prefix for every
project-specific public type (`FooConfigManager`, `FooRoutesManager`, `FooGlobalManager`), so
packages from several ACT apps can coexist once imported side by side (RD1).

### PS3 - Wire the ACT packages into pubspec <!-- omit from toc -->

Decide where the ACT packages submodule lives and how to name its folder (Q4): the default is
`actlibs/` at the app root, but any relative path works as long as the `pubspec.yaml` paths below
match it. Add this repository as a git submodule at that location (see
[the repository README](../README.md#how-to-use-the-packages-in-your-project)) and reference every
package by its local path - never by a `git:` dependency. Create a project branch in the submodule
to point at, so the app is independent while still able to pull shared fixes.

Start from the mandatory core; the other packages are added by the steps that need them:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Cross-cutting Dart/Flutter helpers used throughout the skeleton
  equatable: ^2.0.8
  flutter_bloc: ^9.1.1
  intl: ^0.20.2

  # ACT mandatory core: config, logger, fatal-error, router, global manager
  act_life_cycle:
    path: actlibs/act_life_cycle
  act_global_manager:
    path: actlibs/act_global_manager
  act_config_manager:
    path: actlibs/act_config_manager
  act_logger_manager:
    path: actlibs/act_logger_manager
  act_router_manager:
    path: actlibs/act_router_manager
  act_flutter_utility:
    path: actlibs/act_flutter_utility
  act_dart_result:
    path: actlibs/act_dart_result
  act_dart_utility:
    path: actlibs/act_dart_utility

  # Added by their step when needed: act_intl + act_intl_ui (PS9),
  # act_themes_manager (PS10), act_splash_screen_manager (PS8),
  # flutter_screenutil (PS10, mobile only)
```

### PS4 - Lay out the canonical project tree <!-- omit from toc -->

Create the concern-based `lib/` layout (RFL21), omitting folders you do not need yet:

```text
lib/
├── main.dart
├── constants/    # theme, assets, business constants
├── generated/    # auto-generated - do not edit (RD19), gitignored
├── l10n/         # ARB translation source files
├── managers/     # managers + their builders + services (routes/ sub-folder)
├── models/       # data models (Equatable)
├── types/        # enums (routes, ...), exceptions, type aliases
└── ui/
    ├── main_app/ # MaterialApp root widget
    ├── pages/    # page widgets, organized by feature
    └── widgets/  # reusable widgets
```

Create the `assets/` tree and a top-level `fonts/` folder (a sibling of `assets/`, not nested under
it). Git does not track empty folders, so drop an empty `.gitkeep` in each folder that would
otherwise start empty; the config files are created in PS5:

```text
<app root>/
├── assets/
│   ├── config/          # environment YAML files (PS5)
│   └── graphics/
│       ├── .gitkeep
│       └── svg/
│           └── .gitkeep
└── fonts/
    └── .gitkeep
```

Declare the asset folders in `pubspec.yaml` so Flutter bundles them; font families are declared
separately under a `fonts:` section once real font files land in `fonts/`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/config/
    - assets/graphics/
    - assets/graphics/svg/
```

If the app integrates a native library (FFI) or an IPC channel (TCP + protobuf, ...), add a
dedicated sub-folder under `managers/` for its services (for example `managers/runtime/` for FFI,
`managers/connection/` for TCP + protobuf).

### PS5 - Add the configuration manager <!-- omit from toc -->

Add a config manager extending `AbsUsualConfigManager` and expose each value as a
`const ConfigVar<T>("path.to.value")` (RFL24). No configuration value is hardcoded elsewhere.

```dart
class FooConfigManager extends AbsUsualConfigManager with MixinLocaleConfig {
  final serverHostname = const ConfigVar<String>("server.hostname");
}
```

This is the first manager registered, because most others read configuration.

Create the environment files the manager reads under `assets/config/`. They are merged in a fixed
precedence, each layer overriding the previous one: `default` < environment < `local` < process
environment / `.env`.

| File                 | Role                                                         |
| -------------------- | ------------------------------------------------------------ |
| `default.yaml`       | Base values shared by every environment (always present)     |
| `development.yaml`   | Development (`DEV`) overrides                                |
| `qualification.yaml` | Qualification (`QUALIF`) overrides                           |
| `production.yaml`    | Production (`PROD`) overrides                                |
| `local.yaml`         | Per-developer overrides, highest-precedence, never committed |

Create all five so every environment resolves. Keep `default.yaml` complete enough that the app runs
with no environment selected, and keep `local.yaml` out of version control by adding it (and any
`.env`) to `.gitignore`:

```gitignore
assets/config/local.*
assets/config/*.env
```

### PS6 - Add the logger right after the config <!-- omit from toc -->

Register `LoggerManager` immediately after the config manager (RFL25); every manager registered
afterwards may depend on it. Each class that logs owns one `LogsHelper` built from a
`static const _loggerCategory`, and hands sub-loggers to its services (RFL26). Never use `print`.

### PS7 - Add the fatal-error page <!-- omit from toc -->

Create a default fatal-error page and register `UiFatalErrorManager` (from `act_global_manager`)
with it right after the logger, so a startup failure or uncaught error shows that page instead of
crashing (RFL39). The page must be self-contained - its own `MaterialApp`, no routes and no
translations - because it runs before any other manager is ready; give it a generic message and,
when useful, the error passed to its builder. Every app ships at least this default page; a project
may replace it later with a branded one.

```dart
class FatalErrorPage extends StatelessWidget {
  const FatalErrorPage({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(child: Text('The application failed to start.\n$error')),
    ),
  );
}

// In registerManagers():
registerManagerAsync<UiFatalErrorManager>(
  UiFatalErrorBuilder((error) => FatalErrorPage(error: error)),
);
```

### PS8 - Add the splash screen <!-- omit from toc -->

When Q10 is yes, register a splash-screen manager (`act_splash_screen_manager`) so the platform
splash stays up until the app is ready. Register it early, right after the fatal-error page.

### PS9 - Set up internationalization <!-- omit from toc -->

Enable `flutter_intl` in `pubspec.yaml` and put every user-facing string in ARB files under
`l10n/` (RFL32); no literal user-visible string lives in Dart code.

```yaml
flutter_intl:
  enabled: true
  class_name: Tr
  main_locale: en_GB
```

For each locale from Q6, create `lib/l10n/intl_<locale>.arb`. Register the four localization
delegates (`Tr.delegate`, `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`,
`GlobalCupertinoLocalizations.delegate`) and `supportedLocales` on the root `MaterialApp` (RFL33).
Regenerate with `dart run intl_utils:generate`. To add a string later: add its key and an
`@key` description to the main ARB file, translate it in the other locale files, regenerate, then
use `Tr.of(context).key`.

When Q7 requests an in-app language switcher, also register the locales manager (`LocalesManager`
from `act_intl`, with `act_intl_ui` for the widget) so the chosen locale is persisted and applied
at runtime. Without it, the app still supports the Q6 locales but the language follows the platform.

### PS10 - Set up the theme and responsive sizing <!-- omit from toc -->

Define the theme in `constants/theme_constants.dart` as an `ActThemeModel` and import it with a
namespace alias, not a star import (RFL34). When Q9 selects multiple themes, model them through
`act_themes_manager` and expose the current theme as state.

Responsive sizing depends on the target platforms (Q5):

- **Mobile only** - add `flutter_screenutil`, initialize `ScreenUtilInit` once at the app root, and
  size widgets with its `.w`/`.h`/`.sp` extensions (RFL5).
- **Web only or desktop only** - do not add `flutter_screenutil`; size with `LayoutBuilder`
  breakpoints and flexible layouts.
- **Mobile plus web or desktop** - add `flutter_screenutil` and use `.w`/`.h`/`.sp`, but allow it
  to be disabled per platform (fall back to breakpoints on web/desktop) so the fixed design size
  does not distort the larger form factors.

### PS11 - Set up routing <!-- omit from toc -->

Declare routes as an `enum with MixinRoute` carrying `parent`, `transition`, and
`screenOrientation` (RFL28); map each route to a page in a `RoutesNameHelper` (RFL29). Navigate
only through the routes manager (`globalGetIt().get<FooRoutesManager>().push(...)`), never through
Flutter's `Navigator` directly (RFL31).

```dart
enum FooRoute with MixinRoute {
  error,
  mainMenu,
  settings;
  // parent / transition / screenOrientation fields + constructor
}
```

### PS12 - Assemble the global manager and `main()` <!-- omit from toc -->

The app's global manager extends `AbsUiGlobalManager` and registers every manager in
`registerManagers()` with `registerManagerAsync<T>(const XxxBuilder())`, **in dependency order**
(RFL20). Declare non-obvious ordering on each builder with `dependsOn()` (RFL17). Retrieve managers
only via `globalGetIt()` (RFL19).

```dart
class FooGlobalManager extends AbsUiGlobalManager {
  @override
  Future<void> registerManagers() async {
    // Core managers, in dependency order:
    registerManagerAsync<FooConfigManager>(const FooConfigBuilder());     // PS5
    registerManagerAsync<LoggerManager>(ExtDefaultLoggerBuilder<FooConfigManager>()); // PS6
    registerManagerAsync<UiFatalErrorManager>(                            // PS7
      UiFatalErrorBuilder((error) => FatalErrorPage(error: error)),
    );
    registerManagerAsync<AbsSplashScreenManager>(const SplashScreenBuilder()); // PS8 (if Q10)
    registerManagerAsync<LocalesManager>(/* ... */);                     // PS9 (if Q7)
    registerManagerAsync<FooRoutesManager>(const FooRoutesBuilder());     // PS11
    // Optional (storage) and feature managers slot in here, dependencies first.
  }
}
```

`main()` always lives in its own `main.dart` and contains nothing but the startup call:

```dart
Future<void> main() async => FooGlobalManager.instance.runActApp(const MainAppUi());
```

### PS13 - Add the baseline tests and analysis options <!-- omit from toc -->

Base the app `analysis_options.yaml` on the shared ACT lint ruleset -
[`analysis_options.yaml`](../analysis_options.yaml) at the root of this repository - so the app is
linted with the same rules as the packages it depends on. Treat infos as fatal
(`flutter analyze --fatal-infos`). Add a smoke test that boots the global manager and reaches the
first route, so the skeleton is verifiable from the start (see the repository
[Tests](../README.md#tests) section for how and where tests live).

## Optional capabilities

These capabilities are rare across our apps, so they are not part of the initial questions. Add one
only when a project actually needs it: add its package(s) to `pubspec.yaml` (PS3), register its
manager in the global manager (PS12) after its dependencies, and follow the linked package
`README.md`. Local storage is the exception - it is driven by Q8. Route secrets and tokens through
the auth/config packages, never through `SharedPreferences` or plain local storage (RFL35).

| Capability            | Package(s)                                                                                                                                                                              | Registration note                           |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| Local storage (Q8)    | [`act_local_storage_manager`](../act_local_storage_manager/README.md)                                                                                                                   | After logger; secrets only here (RFL35)     |
| OAuth2 (Google)       | [`act_oauth2_core`](../act_oauth2_core/README.md), [`act_oauth2_google`](../act_oauth2_google/README.md)                                                                                | After storage; `clear()` on logout          |
| Amplify Cognito       | [`act_amplify_core`](../act_amplify_core/README.md), [`act_amplify_cognito`](../act_amplify_cognito/README.md)                                                                          | After storage                               |
| Shared auth + JWT     | [`act_shared_auth`](../act_shared_auth/README.md), [`act_shared_auth_local_storage`](../act_shared_auth_local_storage/README.md), [`act_jwt_utilities`](../act_jwt_utilities/README.md) | After storage                               |
| Internet connectivity | [`act_internet_connectivity_manager`](../act_internet_connectivity_manager/README.md)                                                                                                   | Early, so dependents can observe it         |
| HTTP client           | [`act_http_client_manager`](../act_http_client_manager/README.md), [`act_http_core`](../act_http_core/README.md)                                                                        | After connectivity/auth                     |
| WebSocket client      | [`act_websocket_client_manager`](../act_websocket_client_manager/README.md), [`act_websocket_core`](../act_websocket_core/README.md)                                                    | After connectivity                          |
| Native library (FFI)  | [`act_ffi_utility`](../act_ffi_utility/README.md) + `ffigen` (dev)                                                                                                                      | Dedicated `managers/<name>/` services (PS4) |
| Bluetooth Low Energy  | [`act_ble_manager`](../act_ble_manager/README.md), [`act_permissions_manager`](../act_permissions_manager/README.md)                                                                    | Needs runtime permissions                   |
| Remote file storage   | [`act_remote_storage_manager`](../act_remote_storage_manager/README.md)                                                                                                                 | After connectivity/auth                     |

For TCP + protobuf integration, add a `connection/` services sub-folder (PS4) and generate the
protobuf stubs into `generated/` (see [Generated code and tooling](#generated-code-and-tooling)).
See the full [package list](../README.md#packages-list) for capabilities not listed above.

## Platform specifics

The mandatory core is identical on every platform; only these differ, driven by the target
platforms (Q5).

- **Desktop (linux/windows/macos)** - add `window_manager` to control the window, size layouts with
  `LayoutBuilder` breakpoints (no `flutter_screenutil`, see PS10), and keep the per-platform runner
  folders that `flutter create` generated.
- **Web** - `dart:ffi` is unavailable, so a native FFI integration does not apply; use
  [`act_web_local_storage_manager`](../act_web_local_storage_manager/README.md) for local storage
  instead of the native one, and size with `LayoutBuilder` breakpoints.
- **Mobile (android/ios)** - set the bundle id (Q3) in the native projects, declare the runtime
  permissions your capabilities need (BLE, location, ...) via
  [`act_permissions_manager`](../act_permissions_manager/README.md), and generate launcher icons
  with [`act_launcher_icon`](../act_launcher_icon/README.md).

## Generated code and tooling

All generated code lives under `generated/`, is never hand-edited, and is excluded from version
control (RD19). Regenerate it with:

| Kind                  | Command                               |
| --------------------- | ------------------------------------- |
| Localization          | `dart run intl_utils:generate`        |
| FFI bindings (if any) | `dart run ffigen` (or the app's task) |
| Protobuf/gRPC stubs   | the project's protobuf generate step  |

Common day-to-day commands:

```console
> flutter pub get          # install dependencies
> flutter run -d <device>  # run the app
> flutter analyze          # lint (use --fatal-infos in CI)
> flutter build <target>   # release build
```

## Verification checklist

The skeleton is ready when:

- `flutter pub get` resolves with the selected ACT packages.
- `assets/config/` holds the five environment files and the app resolves configuration with no
  environment selected; `local.*` is gitignored.
- Every generator (l10n, and FFI/protobuf if used) has been run and `generated/` is populated.
- `flutter analyze --fatal-infos` is clean.
- The app boots through the global manager, shows the splash (if enabled), and reaches the first
  route.
- A startup failure shows the fatal-error page instead of crashing.
- The baseline smoke test passes.

## Sources

- [Flutter coding standards][flutter-rules] (`RD<n>`/`RFL<n>` rules referenced above)
- [Shared lint ruleset](../analysis_options.yaml) - `analysis_options.yaml` at the repository root
- [Repository README](../README.md) - package list, how to consume the packages, tests, CI
- Per-package `README.md` files linked from the [Optional capabilities](#optional-capabilities) table
- [Effective Dart](https://dart.dev/effective-dart) and [Flutter documentation](https://docs.flutter.dev/)

[flutter-rules]: https://github.com/All-Circuits-Technologies/ACT-Contributing/blob/6-flutter---add-coding-rules/software/coding-standards-flutter.md
