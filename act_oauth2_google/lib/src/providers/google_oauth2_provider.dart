// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_oauth2_google/src/errors/no_google_oauth2_conf_error.dart';
import 'package:act_oauth2_google/src/mixins/mixin_google_oauth2_conf.dart';

/// This is the OAuth2 class to communicate to Google provider
class GoogleOAuth2Provider<C extends MixinGoogleOAuth2Conf> extends AbsOAuth2ProviderService {
  /// This is the logs category for Google OAuth2 provider
  static const _logsCategory = "google";

  /// Class constructor
  GoogleOAuth2Provider() : super(logsCategory: _logsCategory);

  /// {@macro act_oauth2_google.AbsOAuth2ProviderService.getDefaultOAuth2Conf}
  @override
  Future<DefaultOAuth2Conf> getDefaultOAuth2Conf() async {
    final tmpConf = globalGetIt().get<C>().oauthClientConf.load();
    if (tmpConf == null) {
      throw NoGoogleOAuth2ConfError();
    }

    return tmpConf;
  }
}
