// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library firebase_core_dart;

import 'dart:async';

import 'package:meta/meta.dart';

import 'src/firebase_core_exceptions.dart';
import 'src/firebase_options.dart';

export 'src/firebase_exception.dart';
export 'src/firebase_options.dart';

part 'src/firebase.dart';
part 'src/firebase_app.dart';
part 'src/internal/firebase_app_delegate.dart';
part 'src/internal/firebase_core_delegate.dart';
