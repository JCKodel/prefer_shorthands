import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
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
  }

  void _checkAndReport({
    required Expression expression,
    required DartType? declaredType,
    required InterfaceType prefixType,
  }) {
    final expressionType = expression.staticType;
    if (expressionType == null) return;
    if (!context.typeSystem.isSubtypeOf(expressionType, prefixType)) {
      return;
    }

    if (declaredType != null) {
      if (prefixType != declaredType &&
          context.typeSystem.isSubtypeOf(prefixType, declaredType)) {
        return;
      }
    }

    rule.reportAtNode(expression);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer == null) return;
    if (initializer.isDotShorthand) return;

    final declaredType = node.declaredFragment?.element.type;
    if (declaredType == null) return;

    final variableList = node.thisOrAncestorOfType<VariableDeclarationList>();
    final hasExplicitType = variableList?.type != null;

    if (!hasExplicitType && !settings.convertImplicitDeclaration) {
      return;
    }

    final prefixElement = initializer.getShorthandPrefixElement();
    if (prefixElement == null) return;

    _checkAndReport(
      expression: initializer,
      declaredType: declaredType,
      prefixType: prefixElement.thisType,
    );
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final rightHandSide = node.rightHandSide;
    if (rightHandSide.isDotShorthand) return;

    final declaredType = switch (node.leftHandSide) {
      SimpleIdentifier(element: VariableElement(type: final type)) => type,
      _ => null,
    };
    if (declaredType == null) return;

    final prefixElement = rightHandSide.getShorthandPrefixElement();
    if (prefixElement == null) return;

    _checkAndReport(
      expression: rightHandSide,
      declaredType: declaredType,
      prefixType: prefixElement.thisType,
    );
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    final expression = node.expression;
    if (expression.isDotShorthand) return;
    if (expression is! PrefixedIdentifier) return;

    final prefixElement = expression.getShorthandPrefixElement();
    if (prefixElement == null) return;

    _checkAndReport(
      expression: expression,
      declaredType: null,
      prefixType: prefixElement.thisType,
    );
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (final argument in node.arguments) {
      final expression = switch (argument) {
        NamedExpression(expression: final expr) => expr,
        Expression expr => expr,
      };

      if (expression.isDotShorthand) continue;

      final prefixElement = expression.getShorthandPrefixElement();
      if (prefixElement == null) continue;

      final expressionType = expression.staticType;
      if (expressionType == null) continue;

      final parameterType = _getParameterType(argument, expression);
      if (parameterType == null) continue;

      final prefixType = prefixElement.thisType;
      final parameterBaseType = _getNonNullableType(parameterType);

      if (parameterBaseType == prefixType &&
          context.typeSystem.isSubtypeOf(expressionType, parameterType)) {
        rule.reportAtNode(expression);
        continue;
      }

      if (_shouldUseShorthandForFactoryRedirect(
        expression,
        prefixElement,
        parameterBaseType,
      )) {
        rule.reportAtNode(expression);
      }
    }
  }

  DartType? _getParameterType(Expression argument, Expression expression) {
    if (argument is NamedExpression) {
      return argument.element?.type;
    }

    if (expression.parent case final parent?) {
      if (parent is NamedExpression) {
        return parent.element?.type;
      }
    }

    final argumentList = expression.thisOrAncestorOfType<ArgumentList>();
    if (argumentList == null) return null;

    final parent = argumentList.parent;
    final argumentIndex = argumentList.arguments.indexOf(argument);
    if (argumentIndex == -1) return null;

    if (parent is MethodInvocation) {
      final element = parent.methodName.element;
      return _getParameterTypeFromElement(element, argumentIndex);
    } else if (parent is InstanceCreationExpression) {
      final element = parent.constructorName.element;
      return _getParameterTypeFromElement(element, argumentIndex);
    }

    return null;
  }

  DartType? _getParameterTypeFromElement(Element? element, int index) {
    if (element is! ExecutableElement) return null;

    final formalParameters = element.formalParameters;
    if (index < 0 || index >= formalParameters.length) return null;

    return formalParameters[index].type;
  }

  DartType _getNonNullableType(DartType type) {
    if (type.nullabilitySuffix == NullabilitySuffix.none) {
      return type;
    }
    return context.typeSystem.promoteToNonNull(type);
  }

  bool _shouldUseShorthandForFactoryRedirect(
    Expression expression,
    InterfaceElement prefixElement,
    DartType parameterBaseType,
  ) {
    if (parameterBaseType is! InterfaceType) return false;

    final parameterElement = parameterBaseType.element;

    if (!context.typeSystem.isSubtypeOf(
      prefixElement.thisType,
      parameterBaseType,
    )) {
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
