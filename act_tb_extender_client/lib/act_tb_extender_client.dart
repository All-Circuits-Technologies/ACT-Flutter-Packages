// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The side of the tb-extender broker contract an application runs: the client which speaks its
/// endpoints, the models it answers with and the errors it names.
library;

export 'src/clients/tb_extender_broker_client.dart';
export 'src/models/broker_claim_result.dart';
export 'src/models/broker_login_response.dart';
export 'src/models/broker_login_result.dart';
export 'src/models/broker_user.dart';
export 'src/types/broker_auth_error.dart';
export 'src/utils/terms_accepted_version.dart';
