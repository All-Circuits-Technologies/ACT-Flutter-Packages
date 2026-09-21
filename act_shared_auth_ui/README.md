<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Shared authentication User Interface  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
  - [The pages which need a signed in user](#the-pages-which-need-a-signed-in-user)
  - [The two moments a user is sent away](#the-two-moments-a-user-is-sent-away)
  - [Where a signed in user is sent](#where-a-signed-in-user-is-sent)
  - [What a page of the authentication is given](#what-a-page-of-the-authentication-is-given)
- [Guards](#guards)
  - [The terms the application has to ask about](#the-terms-the-application-has-to-ask-about)
  - [Stack them](#stack-them)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Declare the pages of an application](#declare-the-pages-of-an-application)
  - [Register the redirection](#register-the-redirection)
  - [Go to a page of the authentication](#go-to-a-page-of-the-authentication)
- [Testing](#testing)

## Presentation

This package is the interface side of `act_shared_auth`: it keeps the pages of an application which
need a signed in user away from the ones which do not, and it carries what a page of the
authentication needs to know from the page which sent the user to it.

It draws nothing: the sign in, the sign up and the resetting of a password are pages of the
application. What this package brings is the redirection which sends a user to them, and the models
which travel with the user.

## Architecture

### The pages which need a signed in user

`MixinAuthRoute` is what the routes of an application mix in: one answer per page, saying whether it
needs a signed in user. That answer is read in two places, and nowhere else, so a page which is
added to an application is protected as soon as it is declared.

### The two moments a user is sent away

```mermaid
flowchart TD
    ask(["The application goes to a page"])
    redirect["onRedirect"]
    signIn(["The sign in page"])
    page(["The page which was asked for"])
    status(["The user signs out, or the session expires"])
    push["pushAndRemoveUntilFirstRoute"]

    ask --> redirect
    redirect -- "the page needs a user who is not there" --> signIn
    redirect -- "anything else" --> page
    status --> push
    push -- "the page which is open needs a user" --> signIn
```

- when the application goes to a page, the redirection is asked, and it answers the sign in page for
  a page which needs a user who is not signed in. The sign in page itself is always let through, and
  so is a page which needs no user,
- when the status of the user changes while the application is already somewhere, the page which is
  open is the one which is read: a user who signs out or whose session expires while reading a page
  which needs a user is sent to the sign in page, and everything else is forgotten, so that the back
  button does not lead back into the application.

A redirection an application registers before this one has the last word: `onRedirect` reads what
the redirections above it answered first, and the authentication is only asked when they answered
nothing. The order of the mixins is the order of priority.

A router only holds one redirection: registering this one on a router which already has one answers
false and the redirection never starts, which is what an application reads to know that it has to
compose them instead.

### Where a signed in user is sent

An application which names a start page with `getStartRoute` gets one more rule: a signed in user
is never left on the sign in page, it is sent to the start page instead. The rule is applied at the
two moments the others are:

- when the application asks for the sign in page while the user is signed in, the redirection
  answers the start page,
- when the status becomes signed in while the sign in page is the one which is open, the sign in
  page is replaced by the start page.

The redirection is the one which leaves the sign in page: a sign in page of such an application
reports its result and navigates nowhere, otherwise two navigations race for the same click.

`getStartRoute` answers null by default, and an application which leaves it alone keeps the
behaviour it had: a signed in user is left on the sign in page. Only the sign in page is read here,
a signed in user on any other page is left where it is.

### What a page of the authentication is given

Every page of the authentication is given an extra when it is pushed, and they all carry the same
two things: the page to go to once it succeeded, and the error which led the user here, of the type
that page answers.

| The extra                 | What it adds                                                 |
| ------------------------- | ------------------------------------------------------------ |
| `SignInPageExtra`         | Nothing more                                                 |
| `SignUpPageExtra`         | The account and the password a form is filled from           |
| `ConfirmSignUpPageExtra`  | The same, with the account which cannot be left out          |
| `ResetPwdPageExtra`       | The user, and the code it read when it has one               |

The account and the password of a sign up are what lets a user who was refused on the sign in page
find a form which is already filled, and the account of a confirmation is what the code is checked
against, which is why that one is mandatory.

## Guards

A guard is a mixin on `MixinRedirectService`: it reads what the guards written before it answered,
and only imposes a page of its own when they answered nothing. The order of the mixins is the order
of priority, and this package brings two of them.

- `MixinAuthRedirectService` imposes the sign in page on a user who is not signed in, and reads
  `isAuthNeeded` of the route,
- `MixinTermsRedirectService` imposes the terms page while the terms have to be accepted, and reads
  `needsAcceptedTerms` of the route.

The authentication comes first: there is no account to read an acceptance of as long as the user is
not signed in.

### The terms the application has to ask about

`MixinTermsRedirectService` knows neither where the acceptance is kept nor how the version in force
is known. It asks the application three things:

| Hook | What it answers |
| --- | --- |
| `getTermsRoute()` | The page the user is sent to, which answers false to `needsAcceptedTerms` |
| `mustAcceptTerms()` | Whether the terms have to be accepted, awaited at each navigation |
| `getTermsChanges()` | A stream which says that the previous answer may have changed, or null |

What an unknown answer means is the application's call, not the package's: blocking is right for an
application whose terms have to be agreed to before anything, letting through is right for one
whose terms are a formality. `getTermsChanges` is what sends a user already sitting on a page to
the terms, at the end of a sign in or of a load, without waiting for their next navigation.

`readTermsAcceptedVersion(rawIdpToken)` reads the version an account accepted out of the claims of
an identity provider token, for the applications whose acceptance is written on the account:
`MixinRawIdpTokenProvider` of `act_shared_auth` is what hands that token over. The claim is named
`terms_accepted_version` unless the application says otherwise.

Backed by [`act_consent_manager`](../act_consent_manager/), which holds the version in force, the
version the account accepted and the state which comes out of the two:

```dart
  @override
  Future<bool> mustAcceptTerms() async {
    final terms = globalGetIt().get<AppConsentManager>().termsService;
    await terms.loadAllConsentInfo();

    return terms.consentState != ConsentStateEnum.accepted;
  }

  @override
  Stream<Object?>? getTermsChanges() =>
      globalGetIt().get<AppConsentManager>().termsService.stateStream;
```

### Stack them

```dart
enum AppRoute with MixinRoute, MixinAuthRoute, MixinTermsRoute {
  signIn(isAuthNeeded: false, needsAcceptedTerms: false),
  terms(isAuthNeeded: true, needsAcceptedTerms: false),
  home(isAuthNeeded: true, needsAcceptedTerms: true);

  @override
  final bool isAuthNeeded;

  @override
  final bool needsAcceptedTerms;

  const AppRoute({required this.isAuthNeeded, required this.needsAcceptedTerms});
}

class AppRedirectService
    with
        MixinRedirectService<AppRoute>,
        MixinAuthRedirectService<AppRoute>,
        MixinTermsRedirectService<AppRoute> {
  @override
  AbstractRouterManager<AppRoute> getRouterManagerFromGlobal() =>
      globalGetIt().get<AppRouterManager>();

  @override
  AbsAuthManager getAuthenticationManagerFromGlobal() => globalGetIt().get<AppAuthManager>();

  @override
  AppRoute getSignInPage() => AppRoute.signIn;

  @override
  AppRoute getTermsRoute() => AppRoute.terms;

  // mustAcceptTerms and getTermsChanges, as above
}
```

The terms page answers false to `needsAcceptedTerms`, otherwise the guard would impose it over and
over.

## How to use

### Installation

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_shared_auth_ui:
    path: ../act_shared_auth_ui
```

### Declare the pages of an application

```dart
enum AppRoute with MixinRoute, MixinAuthRoute {
  signIn(isAuthNeeded: false),
  signUp(isAuthNeeded: false),
  home(isAuthNeeded: true);

  @override
  final bool isAuthNeeded;

  const AppRoute({required this.isAuthNeeded});
}
```

### Register the redirection

```dart
class AppRedirectService with MixinRedirectService<AppRoute>, MixinAuthRedirectService<AppRoute> {
  @override
  AbstractRouterManager<AppRoute> getRouterManagerFromGlobal() =>
      globalGetIt().get<AppRouterManager>();

  @override
  AbsAuthManager getAuthenticationManagerFromGlobal() => globalGetIt().get<AppAuthManager>();

  @override
  AppRoute getSignInPage() => AppRoute.signIn;

  // Optional: where a signed in user is sent instead of the sign in page.
  // Leaving this one out keeps a signed in user on the sign in page.
  @override
  AppRoute? getStartRoute() => AppRoute.home;
}
```

The service is initialized once the router and the authentication of the application are, and it is
closed with them:

```dart
if (!await redirectService.initRedirectService()) {
  // Another redirection is already registered on the router
}
```

### Go to a page of the authentication

```dart
routerManager.push(
  AppRoute.signUp,
  extra: SignUpPageExtra<AppRoute>(
    accountId: username,
    password: password,
    nextRouteWhenSuccess: AppRoute.home,
    previousError: AuthSignInStatus.userNotFound,
  ),
);
```

A page reads its extra the way it reads any other one:

```dart
final extra = checkAndCastExtra<SignUpPageExtra<AppRoute>>(state);
```

## Testing

The tests drive the redirection over a router which records where it was asked to go and an
authentication which answers the status the test decided: a real router needs a view to push a page
into, and what is covered here is what the redirection answers around it.

The redirection is covered on the signed in user which is let through, the signed out user which is
sent to the sign in page, the pages which need no user, the sign in page itself, and the page a
redirection of the application asked for before it. The status of the user is covered on the sign
out and the session which expires while a page which needs a user is open, on the same while a page
which needs none is open, on the user who signs in, and on the status which did not change.

The start page is covered on the user which signs in from the sign in page, on the same one on
another page, and on the signed in user which asks for the sign in page; each of them is covered
again on an application which names no start page, which is what says that the behaviour of before
is left alone.

The registering is covered on the router which already has a redirection of its own, which stops the
service before it starts, and on the closing of a service which never started. The extras are
covered on what each of them carries and on what tells two of them apart.

The terms guard is covered over an application which answers what the test decided: the page which
is imposed and the one which is let through, the routes it asks nothing about, the answer which
changes while a page which needs accepted terms is open and while one which needs none is, the
application which hands no stream over, and the redirection which is closed and stops asking. The
reading of the claim and the decision of the guard are covered on their own, tokens and all.

```console
> flutter test
```
