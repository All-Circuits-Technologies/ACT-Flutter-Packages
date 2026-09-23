<!--
SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT OAuth 2.0 Keycloak <!-- omit from toc -->

## Table of contents <!-- omit from toc -->

- [Presentation](#presentation)
- [Architecture](#architecture)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Declare the configuration](#declare-the-configuration)
  - [Register the provider](#register-the-provider)
  - [Plain http development stacks](#plain-http-development-stacks)
- [Configuration](#configuration)
- [What this package does not know](#what-this-package-does-not-know)
- [Testing](#testing)

## Presentation

This package is the Keycloak side of `act_oauth2_core`: it reads the realm and the client of the
application out of its configuration, and it hands the core the redirect URLs the realm was
registered with. Everything which happens afterwards, from the browser which is opened to the
tokens which come back, belongs to `act_oauth2_core`.

A Keycloak realm is hosted by the one who runs it, so there is no issuer to fill in and no URL to
remember: the configuration names the realm, and this package exists so that an application which
signs its users in through Keycloak has one class to register rather than a provider and a
configuration mixin to write again.

## Architecture

`KeycloakOAuth2Provider` is an `AbsOAuth2ProviderService` which answers two questions: which
configuration should the provider be built with, and which URLs should the realm send the user back
to. It reads the configuration from the configuration manager of the application, which mixes
`MixinKeycloakOAuth2Conf` in, and it raises `NoKeycloakOAuth2ConfError` when there is none to read.

The redirect URLs are given to the constructor, which hands them to `act_oauth2_core`. Left to
itself, `act_oauth2_core` builds `<scheme>:/oauthredirect`, with a single slash, out of the scheme the configuration names. A Keycloak client validates the redirect URI it receives
against the ones its realm was registered with, character for character, and refuses that form. The
URI which is registered, `<scheme>://<path>` and whatever path the realm chose, is therefore what
the application passes, because the scheme belongs to the application: it is the one declared in
the Android manifest placeholder and in the iOS URL types, and this package has no way to know it.

## How to use

### Installation

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_oauth2_keycloak:
    path: ../act_oauth2_keycloak
```

### Declare the configuration

```dart
class AppConfigManager extends AbstractConfigManager with MixinKeycloakOAuth2Conf {}
```

```yaml
auth:
  oauth2:
    keycloak:
      config:
        clientId: "an-app-mobile"
        appAuthRedirectScheme: "com.example.app"
        issuer: "https://keycloak.example.com/realms/a-realm"
        scopes:
          - openid
          - profile
          - offline_access
```

### Register the provider

```dart
class AppAuthManager extends AbsAuthManager {
  @override
  Future<MixinAuthService> getAuthService() async => MultiOAuth2Service<AppProviders>(
    providers: {
      AppProviders.keycloak: KeycloakOAuth2Provider<AppConfigManager>(
        redirectUrl: "com.example.app://oauth2redirect",
      ),
    },
  );
}
```

The `redirectUrl` is the URI registered on the Keycloak client, and the scheme it starts with is
the one the application declares to the platform: `appAuthRedirectScheme` in the Android manifest
placeholder, and the URL types of the iOS `Info.plist`. Keycloak validates the post-logout redirect
the same way, so it is the same URI unless the realm registered another one, which
`postLogoutRedirectUrl` then names.

### Plain http development stacks

A realm served over plain `http` needs the wrapper of `act_oauth2_core`, whose README says how:
`shouldAllowInsecureAppAuthConnections` and `InsecureDevAppAuth` are shared by every provider.

## Configuration

| Key                                                  | Type   | What it is                                    |
| ---------------------------------------------------- | ------ | --------------------------------------------- |
| `auth.oauth2.keycloak.config.clientId`               | String | The client of the application in the realm    |
| `auth.oauth2.keycloak.config.appAuthRedirectScheme`  | String | The scheme the browser comes back on          |
| `auth.oauth2.keycloak.config.scopes`                 | list   | The scopes which are asked of the user        |
| `auth.oauth2.keycloak.config.issuer`                 | String | The URL of the realm                          |
| `auth.oauth2.keycloak.config.discoveryUrl`           | String | Optional, instead of the issuer               |
| `auth.oauth2.keycloak.config.serviceConfiguration`   | map    | Optional, the URLs named one by one           |

The client and the scheme are always needed, and so is one of the three ways of reaching the realm:
a configuration which misses one of them is read as no configuration at all. Unlike a well known
provider, Keycloak has no issuer to fill in.

## What this package does not know

The redirect scheme is declared by the application, in the Android manifest placeholder and in the
iOS URL types, and the package only receives the URL which is built on it: it cannot check that the
platforms declare it, and the test which does belongs to the application.

What the application does with the tokens afterwards is not here either. Exchanging the Keycloak
token for the token of another server, through a broker or otherwise, and everything ThingsBoard,
belong to the application or to the package which speaks to that server.

## Testing

The tests read the configuration of an application through a real configuration manager, over the
asset file each test serves, and they stand in for the library which opens a browser.

The reading is covered on the client which is named, on the realm which is named as an issuer or
through the endpoints one by one, on the configuration which names no client, on the one which
names no realm at all, and on the one which says nothing of Keycloak. The provider is covered on
the configuration it answers, on the error it raises when there is none, and on the redirect URLs
it was built with, the one for the sign out being the one for the sign in until the application
names another.

What is out of reach is everything which happens once the configuration is answered: the browser
which is opened and the tokens which come back belong to `act_oauth2_core` and are covered there.

```console
> flutter test
```
