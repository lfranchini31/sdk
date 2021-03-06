// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper';

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_embedded_names';

/// ignore: IMPORT_INTERNAL_LIBRARY, UNUSED_IMPORT
import 'dart:_interceptors';

/*member: main:[null]*/
main() {
  jsCallInt();
  jsCallEmpty();
  jsCallVoid();
  jsCallUnion();

  jsBuiltin_rawRtiToJsConstructorName();

  jsEmbeddedGlobal_getTypeFromName();
  jsEmbeddedGlobal_libraries();

  jsStringConcat();

  jsGetStaticState();
}

/*member: jsCallEmpty:[null|subclass=Object]*/
jsCallEmpty() => JS('', '#', 0);

/*member: jsCallInt:[subclass=JSInt]*/
jsCallInt() => JS('int', '#', 0);

/*member: jsCallVoid:[null|subclass=Object]*/
jsCallVoid() => JS('void', '#', 0);

/*member: jsCallUnion:Union([exact=JSString], [subclass=JSInt])*/
jsCallUnion() => JS('int|String', '#', 0);

/*member: jsBuiltin_rawRtiToJsConstructorName:[exact=JSString]*/
jsBuiltin_rawRtiToJsConstructorName() {
  return JS_BUILTIN('String', JsBuiltin.rawRtiToJsConstructorName, null);
}

/*member: jsEmbeddedGlobal_getTypeFromName:[null|subclass=Object]*/
jsEmbeddedGlobal_getTypeFromName() {
  return JS_EMBEDDED_GLOBAL('', GET_TYPE_FROM_NAME);
}

/*member: jsEmbeddedGlobal_libraries:[null|exact=JSExtendableArray]*/
jsEmbeddedGlobal_libraries() {
  return JS_EMBEDDED_GLOBAL('JSExtendableArray|Null', LIBRARIES);
}

/*member: jsStringConcat:[exact=JSString]*/
jsStringConcat() => JS_STRING_CONCAT('a', 'b');

/*member: jsGetStaticState:[null|subclass=Object]*/
jsGetStaticState() => JS_GET_STATIC_STATE();
