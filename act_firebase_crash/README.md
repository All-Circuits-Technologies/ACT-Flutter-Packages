<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Firebase Crash  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Google Analytics](#google-analytics)
- [Install dependencies](#install-dependencies)
- [Config manager usage](#config-manager-usage)

## Presentation

This package adds Firebase Crashlytics to the mobile app. It needs `act_firebase_core` to work.

## Google Analytics

Because we may not need to install Google Analytics, this package doesn't install the dependencies.
Therefore, crashlytics may have less features than the full mode with analytics, see the
Firebase documentation to know more about this.

## Install dependencies

After having get the dependencies and configure firebase (read the doc:
[install dependencies](../act_firebase_core/README.md#install-dependencies)).

You only have to call:

> flutterfire configure

## Config manager usage

| Key                            | Type   | Description                                                                                                                                                                                  |
| ------------------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `firebase.crash.enable`        | `bool` | If true, the data collection is enabled and all the crash will be stored in the app.<br\>If false, no data collection will be stored if there are some elements left, there will be deleted. |
| `firebase.crash.autoLogEnable` | `bool` | If true, the collected logs will be sent automatically.<br\>If false, the collected logs have to be sent manually.                                                                           |
