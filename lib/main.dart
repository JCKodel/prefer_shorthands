import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

final plugin = PreferShorthandsPlugin();

class PreferShorthandsPlugin extends Plugin {
  @override
  String get name => 'prefer_shorthands';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(PreferShorthandsRule());
    registry.registerFixForRule(
      PreferShorthandsRule.code,
      ConvertToShorthand.new,
    );
  }
}

class PreferShorthandsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_shorthands',
    'Prefer shorthands',
    correctionMessage: "Try using shorthand syntax instead.",
  );

  PreferShorthandsRule()
    : super(name: 'prefer_shorthands', description: 'Prefer shorthands');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addVariableDeclaration(this, visitor);
    registry.addConstantPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  bool _isRelaxingType({
    required InterfaceElement prefixElement,
    required DartType declaredType,
  }) {
    if (declaredType is! InterfaceType) return false;

    final prefixType = prefixElement.thisType;
    if (prefixType == declaredType) return false;

    return prefixType.asInstanceOf(declaredType.element) != null &&
        declaredType.asInstanceOf(prefixElement) == null;
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

    if (hasExplicitType &&
        _isRelaxingType(
          prefixElement: prefixElement,
          declaredType: declaredType,
        )) {
      return;
    }

    rule.reportAtNode(expression);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer == null) return;

    final usesDotShorthand =
        initializer is DotShorthandConstructorInvocation ||
        initializer is DotShorthandPropertyAccess ||
        initializer is DotShorthandInvocation;

    if (usesDotShorthand) return;

    final declaredType = node.declaredFragment?.element.type;
    if (declaredType == null) return;

    final variableList = node.thisOrAncestorOfType<VariableDeclarationList>();
    final hasExplicitType = variableList?.type != null;

    if (initializer is InstanceCreationExpression) {
      final constructorName = initializer.constructorName.name?.name;
      if (constructorName == null || constructorName == 'new') return;

      final constructorType = initializer.staticType;
      if (constructorType is! InterfaceType) return;

      _checkAndReport(
        expression: initializer,
        staticType: constructorType,
        declaredType: declaredType,
        prefixElement: constructorType.element,
        hasExplicitType: hasExplicitType,
      );
    }

    if (initializer is PropertyAccess) {
      final target = initializer.target;
      if (target is! SimpleIdentifier) return;

      final targetElement = target.element;
      if (targetElement is! InterfaceElement) return;

      _checkAndReport(
        expression: initializer,
        staticType: initializer.staticType,
        declaredType: declaredType,
        prefixElement: targetElement,
        hasExplicitType: hasExplicitType,
      );
    }

    if (initializer is PrefixedIdentifier) {
      final prefix = initializer.prefix;
      final prefixElement = prefix.element;
      if (prefixElement is! InterfaceElement) return;

      _checkAndReport(
        expression: initializer,
        staticType: initializer.staticType,
        declaredType: declaredType,
        prefixElement: prefixElement,
        hasExplicitType: hasExplicitType,
      );
    }

    if (initializer is MethodInvocation) {
      final target = initializer.target;
      if (target is! SimpleIdentifier) return;

      final targetElement = target.element;
      if (targetElement is! InterfaceElement) return;

      _checkAndReport(
        expression: initializer,
        staticType: initializer.staticType,
        declaredType: declaredType,
        prefixElement: targetElement,
        hasExplicitType: hasExplicitType,
      );
    }
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    final expression = node.expression;

    if (expression is DotShorthandConstructorInvocation ||
        expression is DotShorthandPropertyAccess ||
        expression is DotShorthandInvocation) {
      return;
    }

    if (expression is! PrefixedIdentifier) return;

    final prefix = expression.prefix;
    final prefixElement = prefix.element;
    if (prefixElement is! InterfaceElement) return;

    final staticType = expression.staticType;
    if (staticType == null) return;

    final prefixType = prefixElement.thisType;

    if (staticType == prefixType ||
        (staticType is InterfaceType &&
            staticType.asInstanceOf(prefixElement) != null)) {
      rule.reportAtNode(expression);
    }
  }
}

class ConvertToShorthand extends ResolvedCorrectionProducer {
  static const _convertToShorthandKind = FixKind(
    'dart.fix.convertToShorthand',
    DartFixKindPriority.standard,
    "Convert to shorthand syntax",
  );

  ConvertToShorthand({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _convertToShorthandKind;

  Future<void> _applyFix({
    required ChangeBuilder builder,
    required VariableDeclarationList variableList,
    required bool hasExplicitType,
    required DartType? staticType,
    required AstNode nodeToDelete,
  }) async {
    if (staticType == null) return;

    await builder.addDartFileEdit(file, (builder) {
      if (!hasExplicitType) {
        final keyword = variableList.keyword;
        if (keyword != null) {
          builder.addSimpleInsertion(
            keyword.end,
            ' ${staticType.getDisplayString()}',
          );
        }
      }

      builder.addDeletion(range.node(nodeToDelete));
    });
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final errorNode = node;

    if (errorNode is PrefixedIdentifier) {
      final constantPattern = errorNode.thisOrAncestorOfType<ConstantPattern>();
      if (constantPattern != null) {
        final prefix = errorNode.prefix;
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.node(prefix));
        });
        return;
      }
    }

    final variableDeclaration = errorNode
        .thisOrAncestorOfType<VariableDeclaration>();
    if (variableDeclaration == null) return;

    final variableList = variableDeclaration
        .thisOrAncestorOfType<VariableDeclarationList>();
    if (variableList == null) return;

    final hasExplicitType = variableList.type != null;

    if (errorNode is InstanceCreationExpression) {
      final constructorName = errorNode.constructorName;
      final typeNode = constructorName.type;
      if (constructorName.name == null) return;

      await _applyFix(
        builder: builder,
        variableList: variableList,
        hasExplicitType: hasExplicitType,
        staticType: errorNode.staticType,
        nodeToDelete: typeNode,
      );
    }

    if (errorNode is PropertyAccess) {
      final target = errorNode.target;
      if (target == null) return;

      await _applyFix(
        builder: builder,
        variableList: variableList,
        hasExplicitType: hasExplicitType,
        staticType: errorNode.staticType,
        nodeToDelete: target,
      );
    }

    if (errorNode is PrefixedIdentifier) {
      await _applyFix(
        builder: builder,
        variableList: variableList,
        hasExplicitType: hasExplicitType,
        staticType: errorNode.staticType,
        nodeToDelete: errorNode.prefix,
      );
    }

    if (errorNode is MethodInvocation) {
      final target = errorNode.target;
      if (target == null) return;

      await _applyFix(
        builder: builder,
        variableList: variableList,
        hasExplicitType: hasExplicitType,
        staticType: errorNode.staticType,
        nodeToDelete: target,
      );
    }
  }
}
