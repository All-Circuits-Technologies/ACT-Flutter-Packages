<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Amplify API <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [How to add a REST API Support](#how-to-add-a-rest-api-support)
- [Config manager usage](#config-manager-usage)

## Presentation

This package is linked to [amplify core package](../act_amplify_core/README.md) and allow to add the
support of amplify REST API (which can be AWS API Gateway).

## How to add a REST API Support

Amplify has no command to automatically import external REST API (not created with Amplify) to the
app; even if the external API is an AWS API Gateway.

Therefore the only way to add REST API support is by updating the generated amplify configuration
file. But this file is not commited and depends of the environment. That why we need to parse this
file and update it in this manager.

To knowm more about it you can read:
https://docs.amplify.aws/gen1/flutter/build-a-backend/restapi/existing-resources/

To do it we have added a configuration element to add in your configuration files. The value of this
element will be merged with the generated amplify config file.

## Config manager usage

| Key                  | Type                   | Description                                                                                                                                             |
| -------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `amplify.api.config` | `Map<String, dynamic>` | This object is merged with the content of the amplify generated file.<br/>This package only uses the child object linked to the sub-key: `awsAPIPlugin` |
