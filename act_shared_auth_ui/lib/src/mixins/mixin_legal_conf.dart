// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// This mixin contains the config variables linked to the legal pages of an application.
///
/// It fits the applications whose legal texts are not shipped with them: the texts are published on
/// the web and the terms are accepted on the page of the identity provider, which links to those
/// same pages. What the application needs to know is where they are, and since when the terms in
/// force are in force.
mixin MixinLegalConf on AbstractConfigManager {
  /// This is the base URL of the published legal pages, without a trailing slash
  ///
  /// The page file names are fixed, so a single base is enough to reach all of them.
  final legalBaseUrl = const ConfigVar<String>('legal.baseUrl');

  /// This is the publication date of the terms currently in force, as an ISO-8601 date
  ///
  /// The application compares it with the date the identity provider stamped on the account when
  /// the user accepted: an acceptance older than this one is no longer an acceptance of the current
  /// text. Bumping this date is what asks every user again.
  final termsPublishedAt = const ConfigVar<String>('legal.terms.publishedAt');
}
