<!--
SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
SPDX-FileCopyrightText: 2023, 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT internet connectivity manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Config manager usage](#config-manager-usage)

## Presentation

The package contains the internet connectivity manager to know when we are connected to internet, or
not.

## Config manager usage

| Key                                                        | Type     | Description                                                                                                                     |
| ---------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `internetConnectivity.serverFqdnToTest`                    | `string` | Override the default server FQDN to test.                                                                                       |
| `internetConnectivity.testPeriodInMs`                      | `int`    | This defines a period for retesting internet connection and verify if the internet connection is constant                       |
| `internetConnectivity.constantValueNb`                     | `int`    | This defines the number of time we want to have a stable internet connection "status" when testing the connection with a period |
| `internetConnectivity.periodicVerification.enable`         | `bool`   | This is the periodic verification enabling, used to know if we should periodically verify if we have internet or not            |
| `internetConnectivity.periodicVerification.maxDurationInS` | `int`    | This is the periodic verification max duration to wait before checking again if we have internet                                |
| `internetConnectivity.periodicVerification.minDurationInS` | `int`    | This is the periodic verification min duration to wait before checking again if we have internet                                |
