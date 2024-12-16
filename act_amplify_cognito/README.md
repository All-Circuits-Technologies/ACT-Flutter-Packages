<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Amplify cognito <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [ACT Shared Auth](#act-shared-auth)
- [How to add a Amplify cognito support](#how-to-add-a-amplify-cognito-support)
  - [Create the Amplify Cognito user or identity pool](#create-the-amplify-cognito-user-or-identity-pool)
  - [Import Cognito resources](#import-cognito-resources)

## Presentation

This package is linked to [amplify core package](../act_amplify_core/README.md) and allow to add the
support of amplify cognito.

## ACT Shared Auth

This package offers an implementation of the
[MixinAuthService](../act_shared_auth/lib/src/services/mixin_auth_service.dart) class with Cognito.

Which means you can use [AmplifyCognitoService](lib/src/amplify_cognito_service.dart) class with
the Authentication manager of your project.

## How to add a Amplify cognito support

### Create the Amplify Cognito user or identity pool

First create in your AWS Web console the user or identity pool. Don't do it through the CLI.

### Import Cognito resources

_We follow this page:
[Use an existing Cognito User Pool and Identity Pool](https://docs.amplify.aws/gen1/flutter/build-a-backend/auth/import-existing-resources/)_

If you aren't already connected, you have to be logged in (and to the right AWS account).

In your bash, call the following command:

> amplify import auth

Choose user or identity pool.

If you have several resources, it will ask you to choose one. If not it will select the only one
available for you.

Finally call the push command to send your new configuration to the cloud:

> amplify push
