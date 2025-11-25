import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:prefer_shorthands/utils.dart';

import 'main.dart';
import 'settings.dart';

class Visitor extends SimpleAstVisitor<void> {
  const Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  Settings get settings => plugin.settings;

  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    AbstractAnalysisRule rule,
  ) {
    registry.addVariableDeclaration(rule, this);
    registry.addConstantPattern(rule, this);
    registry.addArgumentList(rule, this);
    registry.addAssignmentExpression(rule, this);
    registry.addBinaryExpression(rule, this);
    registry.addListLiteral(rule, this);
    registry.addSetOrMapLiteral(rule, this);
    registry.addDefaultFormalParameter(rule, this);
    registry.addReturnStatement(rule, this);
    registry.addExpressionFunctionBody(rule, this);
    registry.addSwitchExpressionCase(rule, this);
  }

  /// [canModifyDeclaredType] is true when the declared type can be modified,
  ///
  /// case `final animal = Animal.dog()` can -> `final Animal animal = .dog();`
  /// Even if `Animal.dog()` returns a `Dog` that is subclass of `Animal`,
  void _checkAndReport({
    required Expression expression,
    required DartType? declaredType,
    bool canModifyDeclaredType = false,
  }) {
    final temp = expression.getShorthandPrefixElement();
    if (temp == null) return;
    final (prefixElement, prefixType) = temp;

    final expressionType = expression.staticType;
    if (expressionType == null) return;
    if (!context.typeSystem.isSubtypeOf(expressionType, prefixType)) {
      return;
    }

    if (declaredType != null) {
      if (prefixType != context.typeSystem.promoteToNonNull(declaredType)) {
        if (context.typeSystem.isSubtypeOf(prefixType, declaredType)) {
          if (!_isRedirectConstructor(
            expression,
            prefixElement,
            declaredType,
          )) {
            return;
          }
        } else {
          if (!canModifyDeclaredType) return;
        }
      }
    }

    rule.reportAtNode(expression);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final expression = node.initializer;
    if (expression == null) return;
    if (expression.isDotShorthand) return;

    final variableList = node.thisOrAncestorOfType<VariableDeclarationList>();
    final hasExplicitType = variableList?.type != null;

    if (!hasExplicitType && !settings.convertImplicitDeclaration) {
      return;
    }

    _checkAndReport(
      expression: expression,
      declaredType: node.declaredFragment?.element.type,
      canModifyDeclaredType: true,
    );
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final expression = node.rightHandSide;
    if (expression.isDotShorthand) return;

    final declaredType = node.writeType;
    if (declaredType == null) return;

    _checkAndReport(expression: expression, declaredType: declaredType);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    final expression = node.expression;
    if (expression.isDotShorthand) return;
    if (expression is! PrefixedIdentifier) return;

    final declaredType = switch (node.parent) {
      GuardedPattern(:final pattern) => pattern.matchedValueType,
      LogicalOrPattern(parent: GuardedPattern(:final pattern)) =>
        pattern.matchedValueType,
      _ => null,
    };
    if (declaredType == null) return;

    _checkAndReport(expression: expression, declaredType: declaredType);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final expression = node.rightOperand;
    if (expression.isDotShorthand) return;

    _checkAndReport(
      expression: expression,
      declaredType: switch (node) {
        BinaryExpression(operator: Token(lexeme: '==')) ||
        BinaryExpression(operator: Token(lexeme: '!=')) ||
        BinaryExpression(
          operator: Token(lexeme: '??'),
        ) => node.leftOperand.staticType,
        _ => node.rightOperand.correspondingParameter?.type,
      },
    );
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (final argument in node.arguments) {
      final expression = switch (argument) {
        NamedExpression(:final expression) => expression,
        _ => argument,
      };

      if (expression.isDotShorthand) continue;

      final parameter = argument.correspondingParameter;
      final baseType = parameter?.baseElement.type;

      if (baseType is TypeParameterType) {
        final hasExplicitContext = argument.hasExplicitTypeContext;
        if (!hasExplicitContext) continue;
      }

      _checkAndReport(expression: expression, declaredType: parameter?.type);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    final declaredType = node.getIterableGenericType(IterableType.list);
    if (declaredType == null) return;

    for (final element in node.elements) {
      final expression = switch (element) {
        Expression() => element,
        _ => null,
      };
      if (expression == null) continue;
      if (expression.isDotShorthand) continue;

      _checkAndReport(expression: expression, declaredType: declaredType);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    final declaredType = node.getIterableGenericType(IterableType.set);
    if (declaredType == null) return;

    for (final element in node.elements) {
      final expression = switch (element) {
        Expression() => element,
        _ => null,
      };
      if (expression == null) continue;
      if (expression.isDotShorthand) continue;

      _checkAndReport(expression: expression, declaredType: declaredType);
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    final expression = node.defaultValue;
    if (expression == null) return;
    if (expression.isDotShorthand) return;

    final declaredType = switch (node.parameter) {
      SimpleFormalParameter(type: NamedType(type: final type)) => type,
      _ => null,
    };

    // not same as `variableDeclaration`, function parameter won't do type inference
    if (declaredType == null) return;

    _checkAndReport(expression: expression, declaredType: declaredType);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) return;
    if (expression.isDotShorthand) return;

    final functionDeclaration = node
        .thisOrAncestorOfType<FunctionDeclaration>();
    if (functionDeclaration == null) return;

    final returnType = functionDeclaration.returnType;
    if (returnType == null) return;

    _checkAndReport(expression: expression, declaredType: returnType.type);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    final expression = node.expression;
    if (expression.isDotShorthand) return;

    final functionDeclaration = node
        .thisOrAncestorOfType<FunctionDeclaration>();
    if (functionDeclaration == null) return;

    final returnType = functionDeclaration.returnType;
    if (returnType == null) return;

    _checkAndReport(expression: expression, declaredType: returnType.type);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    final expression = node.expression;
    if (expression.isDotShorthand) return;

    final declaredType = node.findDeclaredType();
    if (declaredType == null) return;

    _checkAndReport(expression: expression, declaredType: declaredType);
  }

  /// Check same name constructor is redirected constructor
  ///
  /// resolve case:
  /// ```dart
  /// Padding(
  ///   padding: const EdgeInsets.all(10),
  ///   child: xxx,
  /// );
  /// ```
  /// `padding` need a `EdgeInsetsGeometry`, then `EdgeInsetsGeometry`
  ///  has a redirected constructor to `EdgeInsets`, like
  /// `EdgeInsetsGeometry.all` -> `EdgeInsets.all`.
  bool _isRedirectConstructor(
    Expression expression,
    InterfaceElement prefixElement,
    DartType declaredType,
  ) {
    if (declaredType is! InterfaceType) return false;

    final parameterElement = declaredType.element;

    if (!context.typeSystem.isSubtypeOf(prefixElement.thisType, declaredType)) {
      return false;
    }

    final constructorName = expression.constructorNameIfInstanceCreation;
    if (constructorName == null) return false;

    final parentConstructor = parameterElement.getConstructorByNameOrNull(
      constructorName,
    );
    if (parentConstructor == null) return false;

    if (!parentConstructor.isFactory) return false;

    final redirectedConstructor = parentConstructor.redirectedConstructor;
    if (redirectedConstructor == null) return false;

    return redirectedConstructor.enclosingElement == prefixElement;
  }
}
