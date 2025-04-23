import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_oauth2_google/src/data/google_url_constants.dart' as google_url_constants;

mixin MixinGoogleOAuth2Conf on AbstractConfigManager {
  final oauthClientConf = ParserConfigVar<DefaultOAuth2Conf, Map<String, dynamic>>(
    "auth.oauth2.google.config",
    parser:
        (value) => DefaultOAuth2Conf.tryToParseFromJson(
          value,
          defaultIssuer: google_url_constants.defaultIssuerUrl,
        ),
  );
}
