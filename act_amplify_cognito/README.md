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
- [AWS Cognito tips and tricks](#aws-cognito-tips-and-tricks)
  - [User pool kinds](#user-pool-kinds)

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

First create the user or identity pool in your AWS Web console. Don't do it through the CLI.
Choose pool kind very carefully (see [User pool kinds](#user-pool-kinds) chapter).

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

## AWS Cognito tips and tricks

### User pool kinds

Cognito user pools can be created either username-centric or email-centric.
This can not be changed afterward and this impacts API usage, especially self sign-up.

If user pool has been created username-centric (default), account is identified by its username.

- user must choose a unique username during sign-up
- app can not really compute a derived one from initial email address (replacing @ sign) since
  someone can have mistakenly used a wrong email (and would lock it due to username collision) and
  since username will not change when user changes its email which leads to a very insane state
  locking initial email.
- user can sign-in using its username, or using its email address if stored in user profile
  and if validated. Note that several accounts can share a same email address in their profile,
  but since validating an email address for an account invalidates this same email address from all
  other accounts, email-based sign-in selects the account with latest verified email.
- cognito can be configured to enforce email address uniqueness among accounts, but this is actually
  checked after account creation, upon confirmation code submission, leading to an unusable account
  since sign-in attempts to update profile requires the confirmation code which complains about
  email address collision and sign-up attempts to override email address complains about username
  collision.

If user pool has been created email-centric, account is identified by its email.

- all user identification API arguments must be given email values
- user can sign-in only using its email address
  - cognito user UUID actually works too but user is never given this UUID
- attempting to sign-up with a colliding email address is properly and early rejected
  - attempting to later change email address with a colliding one is also rejected
