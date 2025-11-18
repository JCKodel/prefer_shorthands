import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:prefer_shorthands/utils.dart';

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

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final nodeToDelete = node.getNodeToDelete();

    if (nodeToDelete == null) return;
    await builder.addDartFileEdit(file, (builder) {
      addExplicitTypeDeclarationIfNeeded(builder);
      builder.addDeletion(range.node(nodeToDelete));
    });
  }

  void addExplicitTypeDeclarationIfNeeded(DartFileEditBuilder builder) {
    final variableList = switch (node) {
      Expression(
        parent: VariableDeclaration(parent: final VariableDeclarationList e),
      ) =>
        e,
      _ => null,
    };
    if (variableList == null) return;

    final hasExplicitType = variableList.type != null;
    if (hasExplicitType) return;

    final staticType = (node as Expression)
        .getShorthandPrefixElement()
        ?.thisType;
    if (staticType == null) return;

    final keyword = variableList.keyword;
    if (keyword == null) return;

    builder.addSimpleInsertion(
      keyword.end,
      ' ${staticType.getDisplayString()}',
    );
  }
}

extension on AstNode {
  AstNode? getNodeToDelete() => switch (this) {
    PrefixedIdentifier(prefix: final prefix) => prefix,
    MethodInvocation(target: final target) => target,
    InstanceCreationExpression(
      constructorName: ConstructorName(name: final name, type: final type),
    )
        when name != null =>
      type,
    _ => null,
  };
}
