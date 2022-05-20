// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

Map<String, dynamic> map = <String, dynamic>{
  'number': 123,
  'string': 'foo',
  'booleanTrue': true,
  'booleanFalse': false,
  'null': null,
};

List<dynamic> list = ['1', 2, true, false];

Map<String, dynamic> deepMap = <String, dynamic>{
  'number': 123,
  'string': 'foo',
  'booleanTrue': true,
  'booleanFalse': false,
  'null': null,
  'list': list,
  'map': map,
};

List<dynamic> deepList = [
  '1',
  2,
  true,
  false,
  list,
  map,
];
