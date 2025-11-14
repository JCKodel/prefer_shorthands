import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToShorthand extends ResolvedCorrectionProducer {
  static const _convertToShorthandKind = FixKind(
    'dart.fix.convertToShorthand',
    DartFixKindPriority.standard,
    "Convert to shorthand syntax",
  );

  ConvertToShorthand({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

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

    if (errorNode case PrefixedIdentifier(
      prefix: final prefix,
    ) when errorNode.thisOrAncestorOfType<ConstantPattern>() != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.node(prefix));
      });
      return;
    }

    final nodeToDelete = errorNode.getNodeToDelete();
    if (nodeToDelete == null) return;

    if (errorNode.thisOrAncestorOfType<ArgumentList>() != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.node(nodeToDelete));
      });
      return;
    }

    final variableDeclaration = errorNode
        .thisOrAncestorOfType<VariableDeclaration>();
    if (variableDeclaration == null) return;

    final variableList = variableDeclaration
        .thisOrAncestorOfType<VariableDeclarationList>();
    if (variableList == null) return;

    await _applyFix(
      builder: builder,
      variableList: variableList,
      hasExplicitType: variableList.type != null,
      staticType: (errorNode as Expression).staticType,
      nodeToDelete: nodeToDelete,
    );
  }
}

extension on AstNode {
  AstNode? getNodeToDelete() => switch (this) {
    InstanceCreationExpression(
      constructorName: ConstructorName(name: final name, type: final type),
    )
        when name != null =>
      type,
    PropertyAccess(target: final target) => target,
    PrefixedIdentifier(prefix: final prefix) => prefix,
    MethodInvocation(target: final target) => target,
    _ => null,
  };
}
