<!--
SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# AWS IoT Core <!-- omit in toc -->

This library provides a set of functions to interact with AWS IoT Core.

# Table of Contents <!-- omit in toc -->

- [Features](#features)
  - [Aws Iot Mqtt Client](#aws-iot-mqtt-client)
  - [Aws Iot Shadow](#aws-iot-shadow)

## Features

Features are divided into services which are owned by the
[AwsIotManager](lib/src/aws_iot_manager.dart) class but to give a quick overview, here are the
features provided by this library:

- **Aws Iot Mqtt Client**: Connect to the AWS IoT Core mqtt broker and publish/subscribe to topics.
- **Aws Iot Shadow**: Get and update the device shadow.

### Aws Iot Mqtt Client

The connection is done through mqtt over websocket. The authentication is done using the AWS
Signature V4 algorithm with the AWS credentials of the user currently signed in.

Given our authentication method, the authenticated role in Aws Iam must have a policy that allows
it to connect, subscribe and publish to aws iot core.

The [AwsIotMqttService](lib/src/services/aws_iot_mqtt_service.dart) is the service responsible for
the connection to the AWS IoT Core mqtt broker. It's job is to keep us connected to the broker and
can be configured to automatically reconnect in case of disconnection.

The service needs some parameters to be able to connect to the broker (the endpoint, region, ...)
and to get this parameters, the [AwsIotManager](lib/src/aws_iot_manager.dart) expects a
configuration manager that extends the [MixinAwsIotConf](lib/src/mixins/mixin_aws_iot_conf.dart)
mixin.

The mqtt service also owns the
[AwsIotMqttSubscriptionService](lib/src/services/aws_iot_mqtt_subscription_service.dart) which
manages [AwsIotMqttSubWatcher](lib/src/models/aws_iot_mqtt_sub_watcher.dart)
instances. A subscription watcher is a smart object that will automatically subscribe or unsubscribe
to a topic when it is needed. It will also recover the subscription if needed after a connection
event.

### Aws Iot Shadow

We access shadows as a thing
[aws doc (1)](https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-comms-device.html)
and not as an app/service
[aws doc (2)](https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-comms-app.html)
because amplify doesnt provide any pluggin for it therefore it is easier to access the shadows as
a thing would using the
[mqtt approach](https://docs.aws.amazon.com/iot/latest/developerguide/thing-shadow-mqtt.html).

I highly recommend reading the
[shadow doc](https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-shadows.html)
but as a quick overview, a given shadow is a json object that contains the state of a device. It is
stored in the cloud and can be updated by the device or by the cloud. The device can subscribe to
the shadow and be notified when the shadow is updated. The shadow has two main parts: the desired
state and the reported state. The desired state is the state that the device should have and the
reported state is the state that the device has.

Our library allows you to get both the reported and desired state of a shadow and to set the
desired state of a shadow.

This library can handle multiple shadows for multiple things at the same time. For example, you
might have a shadow A and a shadow B in your project. For each devices, you will have have to track
the shadow A and shadow B. This is done by the
[AwsIotShadowsService](lib/src/services/aws_iot_shadows_service.dart) which manages the required
[AwsIotNamedShadow](lib/src/models/aws_iot_named_shadow.dart) instances for each device you want to
track/interact with.
