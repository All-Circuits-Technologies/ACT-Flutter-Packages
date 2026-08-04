<!--
SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT OAuth 2.0 Google <!-- omit from toc -->

## Table of contents <!-- omit from toc -->

- [Presentation](#presentation)
- [Architecture](#architecture)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Declare the configuration](#declare-the-configuration)
  - [Register the provider](#register-the-provider)
- [Configuration](#configuration)
- [Testing](#testing)

## Presentation

This package is the Google side of `act_oauth2_core`: it names Google as the issuer and reads the
client of the application out of its configuration. Everything which happens afterwards, from the
browser which is opened to the tokens which come back, belongs to `act_oauth2_core`.

There is nothing Google-specific in it beyond those two things. It exists so that an application
which lets its users sign in with Google has one class to register and one key to fill rather than
an issuer URL to remember.

## Architecture

`GoogleOAuth2Provider` is an `AbsOAuth2ProviderService` which answers one question: which
configuration should the provider be built with? It reads it from the configuration manager of the
application, which mixes `MixinGoogleOAuth2Conf` in, and it raises `NoGoogleOAuth2ConfError` when
there is none to read: an application which registered the provider and forgot the configuration is
broken, and it says so at once rather than failing later in a browser.

The issuer is what makes the configuration short. `https://accounts.google.com` is filled in when
the configuration names none, and that is enough for the provider to find every URL it needs
through the discovery document Google publishes. An application which names an issuer, a discovery
URL or the URLs themselves keeps what it named.

## How to use

### Installation

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_oauth2_google:
    path: ../act_oauth2_google
```

### Declare the configuration

```dart
class AppConfigManager extends AbstractConfigManager with MixinGoogleOAuth2Conf {}
```

### Register the provider

```dart
class AppAuthManager extends AbsAuthManager {
  @override
  Future<MixinAuthService> getAuthService() async => MultiOAuth2Service<AppProviders>(
    providers: {AppProviders.google: GoogleOAuth2Provider<AppConfigManager>()},
  );
}
```

## Configuration

| Key                                                | Type   | What it is                              |
| -------------------------------------------------- | ------ | --------------------------------------- |
| `auth.oauth2.google.config.clientId`               | String | The client of the application at Google |
| `auth.oauth2.google.config.appAuthRedirectScheme`  | String | The scheme the browser comes back on    |
| `auth.oauth2.google.config.scopes`                 | list   | The scopes which are asked of the user   |
| `auth.oauth2.google.config.issuer`                 | String | Optional, `https://accounts.google.com` |
| `auth.oauth2.google.config.discoveryUrl`           | String | Optional, when the issuer is not enough |
| `auth.oauth2.google.config.serviceConfiguration`   | map    | Optional, the URLs named one by one     |

```yaml
auth:
  oauth2:
    google:
      config:
        clientId: "a-client-id.apps.googleusercontent.com"
        appAuthRedirectScheme: "com.example.app"
        scopes:
          - openid
          - email
```

The client and the scheme are the two which are needed: a configuration which misses one of them is
read as no configuration at all.

## Testing

The tests read the configuration of an application through a real configuration manager, over the
asset file each test serves. Nothing else is stood in for: what this package does is the reading.

The reading is covered on the client which is named, on the issuer which is filled in when none is
named, on the issuer which is named and kept, on the configuration which names no client, and on the
one which says nothing of Google at all. The provider is covered on the configuration it answers and
on the error it raises when there is none.

What is out of reach is everything which happens once the configuration is answered: the browser
which is opened and the tokens which come back belong to `act_oauth2_core` and are covered there.

```console
> flutter test
```
