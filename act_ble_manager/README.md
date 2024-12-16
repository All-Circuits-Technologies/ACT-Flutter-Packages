<!--
SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT BLE manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Add permissions to the app](#add-permissions-to-the-app)
  - [Introduction](#introduction)
  - [Android](#android)
  - [iOS](#ios)
- [Config manager usage](#config-manager-usage)

## Presentation

This package helps to manage BLE in app. It also manages the permission and BLE enabling.

## Add permissions to the app

### Introduction

To use BLE in the app, we need to add some permissions. The needed permissions depend of the
android or iOS versions.

In this library, we use the library:
[flutter_reactive_ble](https://pub.dev/packages/flutter_reactive_ble)

### Android

_Source: https://pub.dev/packages/flutter_reactive_ble#android_

You need to add the following permissions to your AndroidManifest.xml file:

```xml
<!-- We need to remove those permissions because the reactive flutter BLE have directly added
        the permission in its manifest file and this creates a conflict:
        https://github.com/PhilipsHue/flutter_reactive_ble/issues/560 -->
<uses-permission-sdk-23 android:name="android.permission.ACCESS_FINE_LOCATION"
    tools:node="remove"/>
<uses-permission-sdk-23 android:name="android.permission.ACCESS_COARSE_LOCATION"
    tools:node="remove"/>

<!-- We add the needed permissions -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"
    android:maxSdkVersion="30" />
```

If you use BLUETOOTH_SCAN to determine location, modify your AndroidManfiest.xml file to include
the following entry:

```xml
 <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                     tools:remove="android:usesPermissionFlags"
                     tools:targetApi="s" />
```

If you use location services in your app, remove android:maxSdkVersion="30" from the location
permission tags

### iOS

_Source: https://pub.dev/packages/flutter_reactive_ble#ios_

For iOS it is required you add the following entries to the `Info.plist` file of your app. It is
not allowed to access Core BLuetooth without this.
For more indepth details:
[Blog post on iOS bluetooth permissions](https://betterprogramming.pub/handling-ios-13-bluetooth-permissions-26c6a8cbb816)

iOS13 and higher:

- NSBluetoothAlwaysUsageDescription

iOS12 and lower:

- NSBluetoothPeripheralUsageDescription

## Config manager usage

| Key                             | Type   | Description                                                |
| ------------------------------- | ------ | ---------------------------------------------------------- |
| `ble.logs.displayScannedDevice` | `bool` | True to display the scanned devices by BLE in the app logs |
