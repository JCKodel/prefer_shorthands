import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
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
  }

  void _checkAndReport({
    required Expression expression,
    required DartType? declaredType,
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
      if (prefixType != context.typeSystem.promoteToNonNull(declaredType) &&
          context.typeSystem.isSubtypeOf(prefixType, declaredType)) {
        if (!_isRedirectConstructor(expression, prefixElement, declaredType)) {
          return;
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
    );
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final expression = node.rightHandSide;
    if (expression.isDotShorthand) return;

    final declaredType = switch (node.leftHandSide) {
      SimpleIdentifier(element: VariableElement(type: final type)) => type,
      _ => null,
    };

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
      declaredType: node.leftOperand.staticType,
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
