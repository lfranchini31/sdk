// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotIterableSpreadTest);
  });
}

@reflectiveTest
class NotIterableSpreadTest extends DriverResolutionTest {
  test_iterable_list() async {
    await assertNoErrorsInCode('''
var a = [0];
var v = [...a];
''');
  }

  test_iterable_null() async {
    await assertNoErrorsInCode('''
var v = [...?null];
''');
  }

  test_notIterable_direct() async {
    await assertErrorsInCode('''
var a = 0;
var v = [...a];
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 23, 1),
    ]);
  }

  test_notIterable_forElement() async {
    await assertErrorsInCode('''
var a = 0;
var v = [for (var i in []) ...a];
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 41, 1),
    ]);
  }

  test_notIterable_ifElement_else() async {
    await assertErrorsInCode('''
var a = 0;
var v = [if (1 > 0) ...[] else ...a];
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 45, 1),
    ]);
  }

  test_notIterable_ifElement_then() async {
    await assertErrorsInCode('''
var a = 0;
var v = [if (1 > 0) ...a];
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 34, 1),
    ]);
  }
}
