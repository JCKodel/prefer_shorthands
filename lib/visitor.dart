import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

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
  }

  void _checkAndReport({
    required Expression expression,
    required DartType? staticType,
    required DartType declaredType,
    required InterfaceElement prefixElement,
    required bool hasExplicitType,
  }) {
    if (staticType == null) return;

    if (declaredType.getDisplayString() != staticType.getDisplayString()) {
      return;
    }

    final prefixType = prefixElement.thisType;

    if (staticType != prefixType &&
        (staticType is! InterfaceType ||
            staticType.asInstanceOf(prefixElement) == null)) {
      return;
    }

    if (hasExplicitType && prefixElement.isRelaxingType(declaredType)) {
      return;
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

    final prefixElement = initializer.extractInterfaceElement();
    if (prefixElement == null) return;

    _checkAndReport(
      expression: initializer,
      staticType: initializer.staticType,
      declaredType: declaredType,
      prefixElement: prefixElement,
      hasExplicitType: hasExplicitType,
    );
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    final expression = node.expression;
    if (expression.isDotShorthand) return;
    if (expression is! PrefixedIdentifier) return;

    final prefixElement = expression.extractInterfaceElement();
    if (prefixElement == null) return;

    if (prefixElement.isPrefixType(expression.staticType)) {
      rule.reportAtNode(expression);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (final argument in node.arguments) {
      final expression = switch (argument) {
        NamedExpression(expression: final expr) => expr,
        Expression expr => expr,
      };

      if (expression.isDotShorthand) continue;

      final prefixElement = expression.extractInterfaceElement();
      if (prefixElement == null) continue;

      final expressionType = expression.staticType;
      if (expressionType == null) continue;

      final parameterType = _getParameterType(argument, expression);
      if (parameterType == null) continue;

      final prefixType = prefixElement.thisType;
      final parameterBaseType = _getNonNullableType(parameterType);
      final expressionBaseType = _getNonNullableType(expressionType);

      if (expressionBaseType == prefixType && parameterBaseType == prefixType) {
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
}

extension on InterfaceElement {
  bool isRelaxingType(DartType declaredType) => switch (declaredType) {
    InterfaceType type
        when type != thisType &&
            thisType.asInstanceOf(type.element) != null &&
            type.asInstanceOf(this) == null =>
      true,
    _ => false,
  };

  bool isPrefixType(DartType? staticType) => switch (staticType) {
    null => false,
    final type when type == thisType => true,
    InterfaceType type when type.asInstanceOf(this) != null => true,
    _ => false,
  };
}

extension on Expression {
  bool get isDotShorthand => switch (this) {
    DotShorthandConstructorInvocation() ||
    DotShorthandPropertyAccess() ||
    DotShorthandInvocation() => true,
    _ => false,
  };

  InterfaceElement? extractInterfaceElement() => switch (this) {
    InstanceCreationExpression(
      constructorName: ConstructorName(name: final name),
      staticType: InterfaceType(element: final element),
    )
        when name?.name != null && name?.name != 'new' =>
      element,
    PropertyAccess(target: SimpleIdentifier(element: InterfaceElement e)) => e,
    PrefixedIdentifier(prefix: SimpleIdentifier(element: InterfaceElement e)) =>
      e,
    MethodInvocation(target: SimpleIdentifier(element: InterfaceElement e)) =>
      e,
    _ => null,
  };
}
