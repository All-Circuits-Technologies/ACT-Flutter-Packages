import 'dart:convert';

import 'package:act_server_req_manager/act_server_req_manager.dart';

sealed class AuthFormatUtility {
  static ({String key, String value}) formatBasicAuthentication({
    required String username,
    required String password,
  }) {
    final toEncode = "$username${AuthConstants.credsSeparator}$password";
    final encoded = base64Encode(toEncode.codeUnits);

    return (
      key: AuthConstants.authorizationKey,
      value: AuthConstants.authBasic.replaceFirst(
        AuthConstants.credsBasicKey,
        encoded,
      ),
    );
  }
}
