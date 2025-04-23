import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_oauth2_google/src/errors/no_google_oauth2_conf_error.dart';
import 'package:act_oauth2_google/src/mixins/mixin_google_oauth2_conf.dart';

class GoogleOAuth2Provider<C extends MixinGoogleOAuth2Conf, S extends MixinOAuth2TokensSecret>
    extends AbsOAuth2ProviderService
    with MixinDefaultOAuth2Provider {
  static const _logsCategory = "google";

  GoogleOAuth2Provider() : super(logsCategory: _logsCategory);

  @override
  Future<DefaultOAuth2Conf> getDefaultOAuth2Conf() async {
    final tmpConf = globalGetIt().get<C>().oauthClientConf.load();
    if (tmpConf == null) {
      throw NoGoogleOAuth2ConfError();
    }

    return tmpConf;
  }

  @override
  Future<MixinOAuth2TokensSecret> getTokensSecretService() async => globalGetIt().get<S>();
}
