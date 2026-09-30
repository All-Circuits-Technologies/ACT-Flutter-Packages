<!--
SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT tb-extender client <!-- omit from toc -->

## Table of contents <!-- omit from toc -->

- [Presentation](#presentation)
- [The endpoints](#the-endpoints)
- [How to use](#how-to-use)
- [What this package does not know](#what-this-package-does-not-know)
- [Testing](#testing)

## Presentation

ThingsBoard validates no token but its own: it speaks neither PKCE nor the exchange of an external
OIDC token. An application whose users sign in with an identity provider (Keycloak, say) and whose
data lives in ThingsBoard therefore holds two sets of tokens, and something has to turn the first
into the second. That something is the `tb-extender` broker, which reads the access token of the
identity provider, provisions the ThingsBoard customer user behind it and answers a pair of
ThingsBoard tokens.

This package is the side of that contract which speaks HTTP: the client of the five endpoints of the
broker, the models it answers with and the errors it names. It takes the access token of the
identity provider as a string and knows nothing of how it was obtained: `act_tb_extender_auth` is
where Keycloak comes in.

## The endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `login` | `POST /api/v1/auth/login` | Exchanges the token for a pair of ThingsBoard tokens and the user behind them |
| `deleteAccount` | `DELETE /api/v1/account` | Erases the account; answers `reauthRequired` on a sign in older than the broker allows |
| `acceptTerms` | `POST /api/v1/terms/accept` | Records the version of the terms the account accepted |
| `claimDevice` | `POST /api/v1/devices/{serial}/claim` | Assigns a device to the account, on proof of its secret |
| `releaseDevice` | `POST /api/v1/devices/{serial}/release` | Frees a device of the account |

## How to use

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_tb_extender_client:
    path: ../act_tb_extender_client
```

```dart
final client = TbExtenderBrokerClient(baseUrlGetter: () => conf.authBrokerUrl.load());
final result = await client.login(idpAccessToken);
```

## What this package does not know

Who signs the user in, where the tokens are kept, and what an application does with a
`BrokerAuthError`: it answers typed results and nothing else. A broker which doesn't answer within
fifteen seconds is read as a network failure; the client can be built with another timeout.

## Testing

The broker client is covered over a stubbed transport, on the five endpoints, on the trailing
slash of the base URL, on a base URL which was never configured, on every documented error code
and on the transport failures which never reach the broker. The parsing of the payload is covered
there too, on a body which isn't a JSON object, on one which misses a mandatory field and on one
which names no first and last name.

```console
> flutter test
```
