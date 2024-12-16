<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Firebase Core  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Install dependencies](#install-dependencies)
  - [Install Firebase CLI](#install-firebase-cli)
  - [Install FlutterFire CLI](#install-flutterfire-cli)
  - [FlutterFire configure](#flutterfire-configure)

## Presentation

This package contains the link to flutter firebase and allow to use firebase with the act
libraries. 

This only contains the core library, to use and add other features, you have to add other 
`act_firebase_*` packages.

## Install dependencies

### Install Firebase CLI

_Source: https://firebase.google.com/docs/cli#setup_update_cli_

_This part is only needed if you haven't done yet_

First, you need to have nodejs installed on your PC.

Open a bash prompt on the root of the project.

Then, call the following command to install Firebase cli:

> npm install -g firebase-tools

Call the next command to log to firebase.

> firebase login

Then log to the ACT developer account.

To verify that everything is alright call the command:

> firebase projects:list

### Install FlutterFire CLI

_Source: https://firebase.google.com/docs/flutter/setup?platform=android_

Install the FlutterFire CLI:

> dart pub global activate flutterfire_cli

### FlutterFire configure

_Source: https://firebase.google.com/docs/flutter/setup?platform=android_

Finally calls:

> flutterfire configure

You have to call it each time you add a new plugin or dependencies to a new firebase service.
