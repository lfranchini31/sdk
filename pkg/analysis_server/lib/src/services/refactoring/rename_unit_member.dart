// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show newLocation_fromElement, newLocation_fromMatch;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' show Identifier;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/java_core.dart';

/**
 * Checks if creating a top-level function with the given [name] in [library]
 * will cause any conflicts.
 */
Future<RefactoringStatus> validateCreateFunction(
    SearchEngine searchEngine, LibraryElement library, String name) {
  return _RenameUnitMemberValidator.forCreate(
          searchEngine, library, ElementKind.FUNCTION, name)
      .validate();
}

/**
 * Checks if creating a top-level function with the given [name] in [element]
 * will cause any conflicts.
 */
Future<RefactoringStatus> validateRenameTopLevel(
    SearchEngine searchEngine, Element element, String name) {
  return _RenameUnitMemberValidator.forRename(searchEngine, element, name)
      .validate();
}

/**
 * A [Refactoring] for renaming compilation unit member [Element]s.
 */
class RenameUnitMemberRefactoringImpl extends RenameRefactoringImpl {
  final ResolvedUnitResult resolvedUnit;

  /// If the [element] is a Flutter `StatefulWidget` declaration, this is the
  /// corresponding `State` declaration.
  ClassElement _flutterWidgetState;

  /// If [_flutterWidgetState] is set, this is the new name of it.
  String _flutterWidgetStateNewName;

  RenameUnitMemberRefactoringImpl(
      RefactoringWorkspace workspace, this.resolvedUnit, Element element)
      : super(workspace, element);

  @override
  String get refactoringName {
    if (element is FunctionElement) {
      return "Rename Top-Level Function";
    }
    if (element is FunctionTypeAliasElement) {
      return "Rename Function Type Alias";
    }
    if (element is TopLevelVariableElement) {
      return "Rename Top-Level Variable";
    }
    return "Rename Class";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var status = await validateRenameTopLevel(searchEngine, element, newName);
    if (_flutterWidgetState != null) {
      _updateFlutterWidgetStateName();
      status.addStatus(
        await validateRenameTopLevel(
          searchEngine,
          _flutterWidgetState,
          _flutterWidgetStateNewName,
        ),
      );
    }
    return status;
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    _findFlutterStateClass();
    return super.checkInitialConditions();
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    if (element is TopLevelVariableElement) {
      result.addStatus(validateVariableName(newName));
    }
    if (element is FunctionElement) {
      result.addStatus(validateFunctionName(newName));
    }
    if (element is FunctionTypeAliasElement) {
      result.addStatus(validateFunctionTypeAliasName(newName));
    }
    if (element is ClassElement) {
      result.addStatus(validateClassName(newName));
    }
    return result;
  }

  @override
  Future<void> fillChange() async {
    // prepare elements
    List<Element> elements = [];
    if (element is PropertyInducingElement && element.isSynthetic) {
      PropertyInducingElement property = element as PropertyInducingElement;
      PropertyAccessorElement getter = property.getter;
      PropertyAccessorElement setter = property.setter;
      if (getter != null) {
        elements.add(getter);
      }
      if (setter != null) {
        elements.add(setter);
      }
    } else {
      elements.add(element);
    }

    // Rename each element and references to it.
    var processor = RenameProcessor(workspace, change, newName);
    for (var element in elements) {
      await processor.renameElement(element);
    }

    // If a StatefulWidget is being renamed, rename also its State.
    if (_flutterWidgetState != null) {
      _updateFlutterWidgetStateName();
      await RenameProcessor(
        workspace,
        change,
        _flutterWidgetStateNewName,
      ).renameElement(_flutterWidgetState);
    }
  }

  void _findFlutterStateClass() {
    var flutter = Flutter.of(resolvedUnit);
    if (flutter.isStatefulWidgetDeclaration(element)) {
      var oldStateName = oldName + 'State';
      _flutterWidgetState = element.library.getType(oldStateName) ??
          element.library.getType('_' + oldStateName);
    }
  }

  void _updateFlutterWidgetStateName() {
    if (_flutterWidgetState != null) {
      _flutterWidgetStateNewName = newName + 'State';
      // If the State was private, ensure that it stays private.
      if (_flutterWidgetState.name.startsWith('_') &&
          !_flutterWidgetStateNewName.startsWith('_')) {
        _flutterWidgetStateNewName = '_' + _flutterWidgetStateNewName;
      }
    }
  }
}

/**
 * Helper to check if the created or renamed [Element] will cause any conflicts.
 */
class _RenameUnitMemberValidator {
  final SearchEngine searchEngine;
  LibraryElement library;
  Element element;
  ElementKind elementKind;
  final String name;
  final bool isRename;
  List<SearchMatch> references = <SearchMatch>[];

  final RefactoringStatus result = RefactoringStatus();

  _RenameUnitMemberValidator.forCreate(
      this.searchEngine, this.library, this.elementKind, this.name)
      : isRename = false;

  _RenameUnitMemberValidator.forRename(
      this.searchEngine, this.element, this.name)
      : isRename = true {
    library = element.library;
    elementKind = element.kind;
  }

  Future<RefactoringStatus> validate() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    _validateWillConflict();
    if (isRename) {
      references = await searchEngine.searchReferences(element);
      _validateWillBeInvisible();
      _validateWillBeShadowed();
    }
    await _validateWillShadow();
    return result;
  }

  /**
   * Returns `true` if [element] is visible at the given [SearchMatch].
   */
  bool _isVisibleAt(Element element, SearchMatch at) {
    LibraryElement atLibrary = at.element.library;
    // may be the same library
    if (library == atLibrary) {
      return true;
    }
    // check imports
    for (ImportElement importElement in atLibrary.imports) {
      // ignore if imported with prefix
      if (importElement.prefix != null) {
        continue;
      }
      // check imported elements
      if (getImportNamespace(importElement).containsValue(element)) {
        return true;
      }
    }
    // no, it is not visible
    return false;
  }

  /**
   * Validates if any usage of [element] renamed to [name] will be invisible.
   */
  void _validateWillBeInvisible() {
    if (!Identifier.isPrivateName(name)) {
      return;
    }
    for (SearchMatch reference in references) {
      Element refElement = reference.element;
      LibraryElement refLibrary = refElement.library;
      if (refLibrary != library) {
        String message = format("Renamed {0} will be invisible in '{1}'.",
            getElementKindName(element), getElementQualifiedName(refLibrary));
        result.addError(message, newLocation_fromMatch(reference));
      }
    }
  }

  /**
   * Validates if any usage of [element] renamed to [name] will be shadowed.
   */
  void _validateWillBeShadowed() {
    for (SearchMatch reference in references) {
      Element refElement = reference.element;
      ClassElement refClass = refElement.thisOrAncestorOfType();
      if (refClass != null) {
        visitChildren(refClass, (shadow) {
          if (hasDisplayName(shadow, name)) {
            String message = format(
                "Reference to renamed {0} will be shadowed by {1} '{2}'.",
                getElementKindName(element),
                getElementKindName(shadow),
                getElementQualifiedName(shadow));
            result.addError(message, newLocation_fromElement(shadow));
          }
          return false;
        });
      }
    }
  }

  /**
   * Validates if [element] renamed to [name] will conflict with another
   * top-level [Element] in the same library.
   */
  void _validateWillConflict() {
    visitLibraryTopLevelElements(library, (element) {
      if (hasDisplayName(element, name)) {
        String message = format("Library already declares {0} with name '{1}'.",
            getElementKindName(element), name);
        result.addError(message, newLocation_fromElement(element));
      }
    });
  }

  /**
   * Validates if renamed [element] will shadow any [Element] named [name].
   */
  Future _validateWillShadow() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchMatch> declarations =
        await searchEngine.searchMemberDeclarations(name);
    for (SearchMatch declaration in declarations) {
      Element member = declaration.element;
      ClassElement declaringClass = member.enclosingElement;
      List<SearchMatch> memberReferences =
          await searchEngine.searchReferences(member);
      for (SearchMatch memberReference in memberReferences) {
        Element refElement = memberReference.element;
        // cannot be shadowed if qualified
        if (memberReference.isQualified) {
          continue;
        }
        // cannot be shadowed if declared in the same class as reference
        ClassElement refClass = refElement.thisOrAncestorOfType();
        if (refClass == declaringClass) {
          continue;
        }
        // ignore if not visible
        if (!_isVisibleAt(element, memberReference)) {
          continue;
        }
        // OK, reference will be shadowed be the element being renamed
        String message = format(
            isRename
                ? "Renamed {0} will shadow {1} '{2}'."
                : "Created {0} will shadow {1} '{2}'.",
            elementKind.displayName,
            getElementKindName(member),
            getElementQualifiedName(member));
        result.addError(message, newLocation_fromMatch(memberReference));
      }
    }
  }
}
