<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Amplify Core  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Amplify](#amplify)
  - [Gen 1](#gen-1)
    - [Presentation](#presentation-1)
    - [Install Amplify CLI](#install-amplify-cli)
    - [Add Amplify to the project](#add-amplify-to-the-project)

## Presentation

This package contains the link to flutter amplify and allow to use amplify with the act
libraries.

This only contains the core library, to use and add other features, you have to add other
`act_amplify_*` packages.

## Amplify

### Gen 1

#### Presentation

This package needs the usage of the Amplify code creation. The way it creates the code depends of
the Amplify Gen.

#### Install Amplify CLI

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
- Keep default profile name

#### Add Amplify to the project

In the root folder of your project, you have to init amplify by calling:

> amplify init

- Environment name: keep default "dev"
- Authentication: AWS access keys
- Enter your 20-char accessKeyId (given to you by the admin)
- Enter your 40-char secretAccessKey (given to you by the admin)
- Select _project_ region with down arrow (see your project README)
