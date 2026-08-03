<!--
SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Halo manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
  - [The manager and its configuration](#the-manager-and-its-configuration)
  - [Asking the device](#asking-the-device)
  - [One request at a time](#one-request-at-a-time)
  - [Asking again](#asking-again)
  - [How long a request may take](#how-long-a-request-may-take)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Register the manager](#register-the-manager)
  - [Ask the device](#ask-the-device)
- [Testing](#testing)

## Presentation

This package is the high level side of the HALO protocol: what an application calls to ask
something of its device, and what keeps those calls from stepping on one another.

The protocol itself, its packets and the hardware layers which carry them belong to
`act_halo_abstract`; this package holds the manager an application registers and the features it
offers on top.

## Architecture

### The manager and its configuration

`AbstractHaloManager` is the manager an application registers. It asks the application for its
configuration when it starts, and builds the feature which asks the device out of it.

The configuration names three things: the ways the application can reach its device, the requests
it knows of, and how many times a request is worth asking again.

An application which cannot build a configuration says so by giving none. The manager then holds
no configuration and builds no feature: it says so in its logs, and an application which asks it
for a feature anyway has a bug of its own to fix.

Disposing the manager closes the ways to the device.

### Asking the device

`HaloRequestToDeviceFeature` is what an application calls. The protocol tells three kinds of
requests apart, and so does the feature:

- a function answers with values, and `callFunction` gives back the whole answer;
- a procedure answers nothing but says whether it worked, and `callProcedure` gives back that;
- an order is neither acknowledged nor answered, and `callOrder` gives back what the hardware
  layer made of sending it.

A function which answers a single value is read straight into it: `callBooleanFunction`,
`callStringFunction`, `callIntFunction` and `callUIntFunction` give back the value, or nothing
when the request failed or when the device did not answer exactly one value.

The way to the device is named on every call, which is what lets an application which reaches its
device over two of them choose. A call which names a way the configuration does not know answers
an error, and nothing is sent.

### One request at a time

A device does one thing at a time, so the feature holds a lock: a call waits for the one before it
to be over, whatever way to the device either of them named.

The lock is released whichever way the call ends, including the calls which never reach the
device.

### Asking again

An error says whether it is worth asking again: a device which is busy or a link which dropped a
message may well answer the next time, whereas a request the device does not understand will
answer the same forever.

The feature asks again while the error is one which may pass, up to the number of times the
configuration allows, and gives back the last error it got.

### How long a request may take

The time a call waits for its answer is the first of these which is set:

1. what the caller asked for;
2. what the application set for that request;
3. what the application set for all its requests;
4. the time the protocol says.

## How to use

### Installation

Add the package to the `dependencies` of the application:

```yaml
dependencies:
  act_halo_manager:
    path: ../act_halo_manager
```

### Register the manager

```dart
class MyHaloManager extends AbstractHaloManager<MyHwType> {
  @override
  Future<HaloManagerConfig<MyHwType>?> initHaloManagerConfig() async {
    final hardwareLayer = await MyHwTypeHelper.build();

    if (hardwareLayer == null) {
      return null;
    }

    return HaloManagerConfig<MyHwType>(
      hardwareLayer: hardwareLayer,
      requestIdHelper: MyRequestIdHelper(),
    );
  }
}

globalManager.registerManagerAsync<MyHaloManager>(MyHaloBuilder(MyHaloManager.new));
```

### Ask the device

```dart
final feature = globalGetIt().get<MyHaloManager>().requestToDeviceFeature!;

final temperature = await feature.callIntFunction(
  hardwareType: MyHwType.ble,
  request: HaloRequestParamsPacket.voidParams(requestId: MyRequestId.readTemperature),
);

final error = await feature.callProcedure(
  hardwareType: MyHwType.ble,
  request: HaloRequestParamsPacket.voidParams(requestId: MyRequestId.startHeating),
);
```

## Testing

The tests drive the manager and the feature over a device which answers what the test lined up,
one error per call, and which records what it was asked and how long it was given.

They cover the three kinds of request, the single values read out of a function, the way to the
device the configuration does not know, the errors which are asked again and the ones which are
not, the number of times the application allows, the four ways the waiting time is decided, and
the ways to the device being closed with the manager.

The application which cannot build a configuration is covered too: the manager keeps none, warns,
and builds no feature.

```console
> flutter test
```
