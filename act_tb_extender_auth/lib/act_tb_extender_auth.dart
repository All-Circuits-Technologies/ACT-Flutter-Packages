// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Keycloak sign in exchanged for ThingsBoard tokens through the tb-extender broker.
///
/// The client of the broker, its models and its errors come from `act_tb_extender_client` and are
/// re-exported here: an application which signs in through this package needs nothing else.
library;

export 'package:act_tb_extender_client/act_tb_extender_client.dart';

export 'src/builders/keycloak_tb_auth_service_builder.dart';
export 'src/mixins/mixin_keycloak_auth_secrets.dart';
export 'src/mixins/mixin_tb_extender_conf.dart';
export 'src/services/keycloak_tb_auth_service.dart';
