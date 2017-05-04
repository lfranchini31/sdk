// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.kernel.element_map;

class KernelNoSuchMethodResolver implements NoSuchMethodResolver {
  final KernelToElementMap elementMap;

  KernelNoSuchMethodResolver(this.elementMap);

  ElementEnvironment get _elementEnvironment => elementMap.elementEnvironment;

  CommonElements get _commonElements => elementMap.commonElements;

  @override
  bool hasForwardingSyntax(KFunction method) {
    ir.Procedure node = elementMap._lookupProcedure(method);
    if (node.function.positionalParameters.isEmpty) return false;
    ir.VariableDeclaration firstParameter =
        node.function.positionalParameters.first;
    ir.Statement body = node.function.body;
    ir.Expression expr;
    if (body is ir.Block && body.statements.isNotEmpty) {
      ir.Block block = body;
      body = block.statements.first;
    }
    if (body is ir.ReturnStatement) {
      expr = body.expression;
    }
    if (expr is ir.AsExpression &&
        elementMap.getDartType(expr.type) == _commonElements.dynamicType) {
      ir.AsExpression asExpression = expr;
      expr = asExpression.operand;
    }
    if (expr is ir.SuperMethodInvocation &&
        expr.name.name == Identifiers.noSuchMethod_) {
      ir.Arguments arguments = expr.arguments;
      if (arguments.positional.length == 1 &&
          arguments.named.isEmpty &&
          arguments.positional.first is ir.VariableGet) {
        ir.VariableGet get = arguments.positional.first;
        return get.variable == firstParameter;
      }
    }
    return false;
  }

  @override
  bool hasThrowingSyntax(KFunction method) {
    ir.Procedure node = elementMap._lookupProcedure(method);
    ir.Statement body = node.function.body;
    if (body is ir.Block && body.statements.isNotEmpty) {
      ir.Block block = body;
      body = block.statements.first;
    }
    ir.Expression expr;
    if (body is ir.ReturnStatement) {
      expr = body.expression;
    } else if (body is ir.ExpressionStatement) {
      expr = body.expression;
    }
    return expr is ir.Throw;
  }

  @override
  FunctionEntity getSuperNoSuchMethod(FunctionEntity method) {
    ClassEntity cls = method.enclosingClass;
    while (cls != null) {
      cls = _elementEnvironment.getSuperClass(cls);
      MemberEntity member =
          _elementEnvironment.lookupClassMember(cls, Identifiers.noSuchMethod_);
      if (member != null) {
        if (member.isFunction) {
          FunctionEntity function = member;
          if (function.parameterStructure.positionalParameters >= 1) {
            return function;
          }
        }
        // If [member] is not a valid `noSuchMethod` the target is
        // `Object.superNoSuchMethod`.
        break;
      }
    }
    FunctionEntity function = _elementEnvironment.lookupClassMember(
        _commonElements.objectClass, Identifiers.noSuchMethod_);
    assert(invariant(method, function != null,
        message: "No super noSuchMethod found for $method."));
    return function;
  }
}
