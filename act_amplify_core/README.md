<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Amplify Core  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Package presentation](#package-presentation)
- [Amplify Gen 1](#amplify-gen-1)
  - [Presentation](#presentation)
  - [Install Amplify CLI](#install-amplify-cli)
  - [Add Amplify to the project](#add-amplify-to-the-project)
  - [Import AWS objects in the project](#import-aws-objects-in-the-project)
  - [Delete imported AWS objects](#delete-imported-aws-objects)

## Package presentation

This package contains the link to flutter amplify and allow to use amplify with the act
libraries.

This only contains the core library, to use and add other features, you have to add other
`act_amplify_*` packages.

## Amplify Gen 1

### Presentation

This package needs the usage of the Amplify code creation. The way it creates the code depends of
the Amplify Gen. In our case, we choose to go with Amplify Gen1 version 2.

Once Amplify tools are installed (see below), you can configure a project using amplify CLI. This
will create a `amplify` folder at the root of your project, containing the configuration of your
project. It will also create a `lib/amplifyconfiguration.dart` file that will be used by the
Amplify DART libraries to connect to your AWS resources (Cognito, S3 etc).

### Install Amplify CLI

_Source: https://docs.amplify.aws/gen1/flutter/start/getting-started/installation/_

_This part is only needed if you haven't done yet_

First, you need to have nodejs installed on your PC.

Open a bash prompt on the root of the project.

Then, install amplify cli:

> npm install -g @aws-amplify/cli

If you don't have an AWS IAM account yet, ask an AWS administrator to create you
a XXX-dev-amplify account with a permanent token (access key).
_(for admins, follow [this](https://docs.amplify.aws/gen1/javascript/tools/cli/start/set-up-cli/#configure-the-amplify-cli)
process)._

Configure amplify:

> amplify configure

- Ignore opened AWS console (press enter)
- Select _project_ region (see project README.md)
- Ignore user creation (press enter)
- Enter your 20-char accessKeyId (given to you by the admin)
- Enter your 40-char secretAccessKey (given to you by the admin)
- Set a project-specific profile name (see project README.md,
  typically `<project>-[dev|qualif|prod]`)

### Add Amplify to the project

In the root folder of your project, you have to init amplify by calling:

> amplify init

- Environment name: `[default|dev|qualif|prod]`, likely `default`
- Authentication: AWS profile
- Choose the previously-created `<project>-[dev|qualif|prod]` profile

### Import AWS objects in the project

You may need to import new AWS objects during the development of the project. For example you might
want to access an [aws S3 bucket](https://aws.amazon.com/fr/s3/) or use an
[aws cognito user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools.html).
In this case, you can just run the following command (given that a user pool and an S3 bucket exist
in aws):

Identify the aws service related to the object you want to import (e.g. `auth` for cognito, `storage`
for S3) and run the following command:

```bash
amplify <service> import
# for example to import a cognito user pool:
amplify auth import
# then follow the instructions in cli
# for example to import an S3 bucket:
amplify storage import
# then follow again the instructions in cli
```

Once your objects are imported, do not forget to push the changes to the cloud:

```bash
amplify push
```

### Delete imported AWS objects

At some point during the development, you might want to delete an imported object to replace it with
another one. To do so, you can run the following command:

Identify the aws service related to the object you want to delete (e.g. `auth` for cognito, `storage`
for S3) and run the following command:

```bash
amplify <service> remove
# for example to remove a cognito user pool:
amplify auth remove
# follow the instructions in cli
# and to remove an S3 bucket:
amplify storage remove
# follow again the instructions in cli
```
