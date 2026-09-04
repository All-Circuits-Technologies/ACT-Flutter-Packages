<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Ble manager User Interface <!-- omit from toc -->

## Table of contents <!-- omit from toc -->

- [Presentation](#presentation)
- [Architecture](#architecture)
  - [The page which lists the devices](#the-page-which-lists-the-devices)
  - [The page which connects to a device](#the-page-which-connects-to-a-device)
  - [Leaving a page which lost its device](#leaving-a-page-which-lost-its-device)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [List the devices around](#list-the-devices-around)
  - [Connect to a device](#connect-to-a-device)
  - [Leave a page when the device is gone](#leave-a-page-when-the-device-is-gone)
- [Testing](#testing)

## Presentation

This package completes the [ACT BLE manager package](../act_ble_manager/README.md) with what a page
needs: a bloc which lists the devices around, a bloc which connects to one of them, and two ways of
leaving a page which needs a device once that device is gone.

It displays nothing itself. There is no widget in it: the pages are those of the application, and
this package only feeds them.

## Architecture

### The page which lists the devices

`BleScannedDevicesBloc` asks the user for the permissions and for the Bluetooth as soon as it is
built, and it starts the scanning as soon as both are there. A page therefore has nothing to do to
open: it reads the state.

The list it holds is not the list of what the scanning answers. A device is added once, whatever the
number of times it is scanned again, and a device the page filters out is never added at all. A
device the scanning says is gone is removed.

The state carries two booleans which are worth telling apart. `isScanActive` says that the scanning
is asked for, not that it is running: a user who switches the Bluetooth off while a page is open
leaves the scanning asked for, and it starts again by itself once the Bluetooth is back.
`isBluetoothActive` is what a page shows the user in the meantime.

### The page which connects to a device

`BleConnectToDeviceBloc` connects to the device the page chose. The device which is already
connected is answered as it is rather than connected again, which is what lets a page be opened
twice without dropping the connection.

The state carries the connection and the pairing as its own values rather than reading them from the
device. That is on purpose: a device goes from connecting to connected faster than a page is
rebuilt, and a page which reads the device would only ever see the last state. A page which wants to
show "connecting" needs to be told about it.

`isLoadingOrConnecting` is the one a page usually reads: the connection is asked for and the device
has not answered yet, or the device says it is connecting.

### Leaving a page which lost its device

Two mixins do that, for two different needs.

`MixinBleConnectionRedirectService` is for an application whose routes say which page to fall back
to: a route mixes `MixinBleConnectionRoute` in and names it, and the service leaves the page as soon
as no device is connected. Falling back walks the pages which are open, so a user who lost the
device deep in a flow lands on the page of the flow rather than on a stack of pages which need a
device.

`MixinBleDeviceConnectionObserver` is for one page which watches one device: it replaces the page as
soon as that device disconnects, and it replaces it at once when there is no device to watch in the
first place.

## How to use

### Installation

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_ble_manager_ui:
    path: ../act_ble_manager_ui
```

### List the devices around

```dart
final bloc = BleScannedDevicesBloc(
  scanMode: ScanMode.lowLatency,
  isDeviceHasToBeDisplayed: (device) => device.name.startsWith("a prefix"),
);
```

The page reads its state:

```dart
BlocBuilder<BleScannedDevicesBloc, BleScannedDevicesState>(
  builder: (context, state) {
    if (!state.isBluetoothActive) {
      return const BluetoothIsOffView();
    }

    return ListView(children: state.devices.map(DeviceTile.new).toList());
  },
)
```

And it asks for what the user does:

```dart
bloc
  ..add(const StopBleScanEvent())
  ..add(const ClearScannedDevicesListEvent())
  ..add(const RequestPermsAndServiceEnablingEvent());
```

### Connect to a device

```dart
final bloc = BleConnectToDeviceBloc(onLowLevelConnectionCallback: _onDeviceAnswered);

bloc
  ..add(ChooseDeviceToConnectToEvent(deviceToConnectTo: aScannedDevice))
  ..add(const DisconnectDeviceEvent());
```

### Leave a page when the device is gone

```dart
enum AppRoutes with MixinRoute, MixinBleConnectionRoute<AppRoutes> {
  home(redirectToIfBleDeviceDisconnected: null),
  deviceDetails(redirectToIfBleDeviceDisconnected: AppRoutes.home);

  @override
  final AppRoutes? redirectToIfBleDeviceDisconnected;

  const AppRoutes({required this.redirectToIfBleDeviceDisconnected});
}

class AppRedirectService extends MixinRedirectService<AppRoutes>
    with MixinBleConnectionRedirectService<AppRoutes> {
  ...
}
```

A page which watches one device on its own:

```dart
class DevicePageBloc extends Bloc<AnEvent, AState>
    with MixinBleDeviceConnectionObserver<AppRoutes, AppRouterManager> {
  Future<void> init() => initObserver(
    routerManager: globalGetIt().get<AppRouterManager>(),
    disconnectedPage: AppRoutes.home,
  );
}
```

## Testing

The tests drive the two blocs over a real Bluetooth manager, itself over the Bluetooth of a device
which answers what each test decided, and over the devices of an application which answer what the
test lined up. The plugin of the Bluetooth is the boundary of the packages this one builds on, so
what is covered here is the blocs.

The page which lists the devices is covered on the scanning which starts by itself, on the device
which is displayed, on the device which is scanned twice and displayed once, on the device the page
filters out, on the device which is gone, on the list which is cleared, on the scanning which is
stopped and started again, and on the Bluetooth which the user switches off and on while the page is
open.

The page which connects is covered on the device which is chosen and connected, on the caller which
is told that the device answered, on the connection the device refuses, on the device which is
already connected and is not connected again, on the connection and the pairing which are told to
the page, and on the disconnection which has the device forgotten and no longer followed.

What is out of reach is the two ways of leaving a page: both replace a page through the router of
the application, which needs a view to push a page into.

```console
> flutter test
```
