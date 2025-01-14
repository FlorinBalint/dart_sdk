// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/error/deprecated_member_use_verifier.dart';
// ignore: implementation_imports
import 'package:analyzer/src/workspace/workspace.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc =
    'Avoid using deprecated elements from within the package in which they are '
    'declared.';

class DeprecatedMemberUseFromSamePackage extends LintRule {
  DeprecatedMemberUseFromSamePackage()
      : super(
          name: LintNames.deprecated_member_use_from_same_package,
          description: _desc,
        );

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.deprecated_member_use_from_same_package_with_message,
        LinterLintCode.deprecated_member_use_from_same_package_without_message
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _DeprecatedMemberUseVerifier extends BaseDeprecatedMemberUseVerifier {
  final LintRule _rule;
  final WorkspacePackage _workspacePackage;

  _DeprecatedMemberUseVerifier(this._rule, this._workspacePackage);

  @override
  void reportError(SyntacticEntity errorEntity, Element element,
      String displayName, String? message) {
    var library = element is LibraryElement ? element : element.library;
    if (library == null || !_workspacePackage.contains(library.source)) {
      // In this case, `DEPRECATED_MEMBER_USE` is reported by the analyzer.
      return;
    }

    var normalizedMessage = message?.trim();
    if (normalizedMessage == null ||
        normalizedMessage.isEmpty ||
        normalizedMessage == '.') {
      _rule.reportLintForOffset(
        errorEntity.offset,
        errorEntity.length,
        arguments: [displayName],
        errorCode: LinterLintCode
            .deprecated_member_use_from_same_package_without_message,
      );
    } else {
      if (!normalizedMessage.endsWith('.') &&
          !normalizedMessage.endsWith('?') &&
          !normalizedMessage.endsWith('!')) {
        normalizedMessage = '$message.';
      }
      _rule.reportLintForOffset(
        errorEntity.offset,
        errorEntity.length,
        arguments: [displayName, normalizedMessage],
        errorCode:
            LinterLintCode.deprecated_member_use_from_same_package_with_message,
      );
    }
  }
}

/// This visitor uses a [DeprecatedMemberUseVerifier] to both report uses of
/// deprecated elements, and to track the deprecated-ness of ancestor
/// declaration nodes.
class _RecursiveVisitor extends RecursiveAstVisitor<void> {
  final _DeprecatedMemberUseVerifier _deprecatedVerifier;

  _RecursiveVisitor(
    LintRule rule,
    WorkspacePackage package,
  ) : _deprecatedVerifier = _DeprecatedMemberUseVerifier(rule, package);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _deprecatedVerifier.assignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _deprecatedVerifier.binaryExpression(node);
    super.visitBinaryExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitClassDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitClassTypeAlias(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var library = node.declaredElement?.library;
    if (library == null) {
      return;
    }
    _deprecatedVerifier.pushInDeprecatedValue(library.hasDeprecated);

    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitConstructorDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _deprecatedVerifier.constructorName(node);
    super.visitConstructorName(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitDefaultFormalParameter(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitEnumDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _deprecatedVerifier.exportDirective(node);
    super.visitExportDirective(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitExtensionDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _deprecatedVerifier.extensionOverride(node);
    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitExtensionTypeDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedMetadata(node.metadata);

    try {
      super.visitFieldDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitFieldFormalParameter(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitFunctionDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _deprecatedVerifier.functionExpressionInvocation(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitFunctionTypeAlias(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitGenericTypeAlias(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _deprecatedVerifier.importDirective(node);
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _deprecatedVerifier.indexExpression(node);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _deprecatedVerifier.instanceCreationExpression(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitMethodDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _deprecatedVerifier.methodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitMixinDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitNamedType(NamedType node) {
    _deprecatedVerifier.namedType(node);
    super.visitNamedType(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _deprecatedVerifier.postfixExpression(node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _deprecatedVerifier.prefixExpression(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _deprecatedVerifier.redirectingConstructorInvocation(node);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _deprecatedVerifier
        .pushInDeprecatedValue(node.declaredElement?.hasDeprecated ?? false);

    try {
      super.visitSimpleFormalParameter(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _deprecatedVerifier.simpleIdentifier(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _deprecatedVerifier.superConstructorInvocation(node);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedMetadata(node.metadata);

    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }
}

/// This [SimpleAstVisitor] visits the [CompilationUnit], and forwards the
/// remainder of visitations to [_RecursiveVisitor], which keeps track of
/// the deprecated-ness of ancestor declaration nodes.
class _Visitor extends SimpleAstVisitor<void> {
  final LintRule _rule;
  final LinterContext _context;

  _Visitor(this._rule, this._context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var package = _context.package;
    if (package == null) {
      // If we don't appear to be in any known package structure, then we can
      // never report that a deprecated use is from the same package as the
      // declaration.
      return;
    }

    var visitor = _RecursiveVisitor(_rule, package);
    node.accept(visitor);
  }
}
