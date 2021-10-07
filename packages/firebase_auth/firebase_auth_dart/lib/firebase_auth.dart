/// Support for Firebase authentication methods
/// with pure dart implmentation.
///
library firebase_auth_dart;

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:googleapis/identitytoolkit/v3.dart'
    show DetailedApiRequestError;
import 'package:meta/meta.dart';

import 'src/api.dart';
import 'src/utils/jwt.dart';

export 'src/api.dart' show APIOptions;

part 'src/additional_user_info.dart';
part 'src/auth_credential.dart';
part 'src/auth_exception.dart';
part 'src/auth_providers.dart';
part 'src/firebase_auth.dart';
part 'src/id_token_result.dart';
part 'src/user.dart';
part 'src/user_credential.dart';
