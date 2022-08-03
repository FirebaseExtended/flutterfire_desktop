// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

/// Support for Firebase authentication methods
/// with pure dart implementation.
library firebase_auth_dart;

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core_dart/firebase_core_dart.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:storagebox/storagebox.dart';

import 'src/api/api.dart';
import 'src/api/errors.dart';
import 'src/firebase_auth_exception.dart';
import 'src/providers/email_auth.dart';
import 'src/providers/enums.dart';
import 'src/providers/facebook_auth.dart';
import 'src/providers/google_auth.dart';
import 'src/providers/oauth.dart';
import 'src/providers/phone_auth.dart';
import 'src/providers/twitter_auth.dart';
import 'src/utils/jwt.dart';

export 'src/api/api.dart' show RecaptchaVerifier, RecaptchaArgs, API, APIConfig;
export 'src/auth_provider.dart';
export 'src/firebase_auth_exception.dart';
export 'src/providers/email_auth.dart';
export 'src/providers/facebook_auth.dart';
export 'src/providers/github_auth.dart';
export 'src/providers/google_auth.dart';
export 'src/providers/oauth.dart';
export 'src/providers/phone_auth.dart';
export 'src/providers/twitter_auth.dart';

part 'src/additional_user_info.dart';
part 'src/auth_credential.dart';
part 'src/confirmation_result.dart';
part 'src/firebase_auth.dart';
part 'src/id_token_result.dart';
part 'src/user.dart';
part 'src/user_credential.dart';
part 'src/user_info.dart';
part 'src/user_metadata.dart';
