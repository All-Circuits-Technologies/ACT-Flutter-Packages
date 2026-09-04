<!--
SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Web Local storage manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
  - [What a session cookie is here](#what-a-session-cookie-is-here)
  - [Deleting](#deleting)
  - [The items](#the-items)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Keep a value for the session](#keep-a-value-for-the-session)
- [Testing](#testing)

## Presentation

This package is the part of the local storage which only exists on the web: the cookies of the
session, which the browser drops when it closes.

It is the answer for what an application wants to keep while the user is there and not afterwards.
What an application keeps from one visit to the next belongs to `act_local_storage_manager`, whose
items this package follows the shape of.

**This package only builds for the web.** An application which is built for another platform
cannot depend on it.

## Architecture

### What a session cookie is here

A cookie written without an expiry lasts as long as the browser is open, and that is the only kind
this package writes. The value is kept as text, so what an application keeps is a text, a number,
a boolean or a double, exactly as the rest of the local storage does.

The cookies of a page are shared with everything else which writes cookies for it, so this package
reads and writes the keys it is given and nothing else. Reading a key walks the cookies of the
page and takes the whole value of the one it names, separators and all.

### Deleting

A cookie cannot be removed, only emptied: the browser drops it when it closes, which is what a
session cookie is for anyway. An empty value therefore reads as nothing.

Clearing everything is not offered: the page holds cookies this package did not write, and it has
no way of telling them apart. Asking for it does nothing and says so in the logs.

### The items

`CookieSessionItem` is one value of the session, named by its key, in one of the types the storage
holds. `CookieSessionItemWithParser` is for the values which are not one of those: the application
gives the way in and the way out, and the item keeps the stored form.

`MixinSessionProperties` is what a properties manager takes to open the cookies of the session to
its application. Clearing the properties clears what is kept from one visit to the next and leaves
the cookies alone.

## How to use

### Installation

Add the package to the `dependencies` of the application:

```yaml
dependencies:
  act_web_local_storage_manager:
    path: ../act_web_local_storage_manager
```

### Keep a value for the session

```dart
class AppPropertiesManager extends AbstractPropertiesManager with MixinSessionProperties {
  final currentPage = const CookieSessionItem<String>("CURRENT_PAGE");

  final lastVisit = CookieSessionItemWithParser<DateTime, int>(
    "LAST_VISIT",
    parser: (value) => DateTime.fromMillisecondsSinceEpoch(value, isUtc: true),
    castTo: (value) => value.millisecondsSinceEpoch,
  );
}

await globalGetIt().get<AppPropertiesManager>().currentPage.store("the home page");
```

## Testing

The tests run in a browser, because the package builds for nothing else. They write real cookies
on the page of the test and read them back: the types the storage holds, the value which holds the
separator of a cookie, the keys told apart, the key which was deleted, and the clearing which
keeps the cookies of the page.

The tests of a package which only runs in a browser are named next to its test task, and both the
CI and `tool/test_all.sh` read them from there:

```console
> flutter test --platform chrome
```

Running them needs a browser Flutter can drive, which is `google-chrome` in the path or the
`CHROME_EXECUTABLE` variable.
