<!--
SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT File Transfer Manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
  - [Picking a file](#picking-a-file)
  - [Saving a file](#saving-a-file)
  - [Naming the extensions](#naming-the-extensions)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Register the managers](#register-the-managers)
  - [Ask the user for a file](#ask-the-user-for-a-file)
  - [Give a file to the user](#give-a-file-to-the-user)
- [Testing](#testing)

## Presentation

This package moves a file between an application and the device it runs on: the file a user picks
to give to the application, and the file the application writes for the user.

It transfers nothing over a network and knows no server. Downloading a file from a remote storage is
the business of another package; this one starts where that file has to reach the device of the
user, and ends where a file of the user has to reach the application.

The dialogs themselves are the ones of [file_selector](https://pub.dev/packages/file_selector) and
of [file_saver](https://pub.dev/packages/file_saver).

## Architecture

### Picking a file

`FileSelectorManager` opens the dialog of the platform, with the kinds of file the application
accepts, and answers a `ResultWithBoolStatus`, which tells three answers apart:

| Answer                     | Status    | Value       |
| -------------------------- | --------- | ----------- |
| The user picked a file     | `success` | The file    |
| The user closed the dialog | `success` | Null        |
| The dialog failed          | `error`   | Null        |

Closing the dialog is not an error: a user is allowed to change their mind, and an application which
treats that as a failure shows a message nobody asked for.

The dialog of a platform is a hint rather than a rule: on some of them a user can pick a file of any
kind, whatever the application declared. The manager therefore reads the extension of the file it is
given back and refuses one which is not among those the application accepts, unless the caller says
it does not insist.

`openSelectorAndGetBytes` goes one step further and reads the content of the file, so the caller
never holds a file it cannot read.

### Saving a file

`FileSaverManager` writes bytes as a file on the device, and answers the path it wrote them at, or
null when it could not. Where that file lands is decided by the platform, not by this package.

On iOS and on macOS, writing a file needs the application to declare it; the documentation of
[file_saver](https://pub.dev/packages/file_saver) says what to add where, under its storage and
network permissions.

### Naming the extensions

`FileExtensions` names the extensions an application passes around, without the dot which precedes
them, because that is how the dialog of the platform wants them. `getFileExtensionWithDot` adds the
dot back for the places which want it, such as the name of a file being built.

## How to use

### Installation

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_file_transfer_manager:
    path: ../act_file_transfer_manager
```

### Register the managers

```dart
GlobalManager.instance
  ..register(const FileSelectorBuilder())
  ..register(const FileSaverBuilder());
```

### Ask the user for a file

```dart
final result = await globalGetIt().get<FileSelectorManager>().openSelectorAndGetBytes(
  allowedExtensions: const [FileExtensions.raucBinary],
  label: Tr.of(context).firmwareFiles,
);

if (result.status.isError) {
  // The dialog failed, or the file cannot be read
} else if (result.value != null) {
  await _installFirmware(result.value!);
}
```

### Give a file to the user

```dart
final path = await globalGetIt().get<FileSaverManager>().saveFileFromBytes(
  fileName: "logs.${FileExtensions.zip}",
  bytes: archive,
);
```

## Testing

The tests answer for the dialog of the platform, which covers the file a user picks, the dialog they
close without picking one, the dialog which fails to open, the kinds of file the manager declares,
and the file which is refused, with a warning, because its extension is not one the application
accepts. Reading the content is covered on the file which is read and on the one which is not there.

Saving a file is only covered on the builder: writing goes to a folder of the device which the
platform chooses, and which a test must not leave anything in.

```console
> flutter test
```
