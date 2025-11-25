import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

extension InterfaceElementExtension on InterfaceElement {
  ConstructorElement? getConstructorByNameOrNull(String constructorName) =>
      constructors.where((c) => c.name == constructorName).firstOrNull;
}

extension ExpressionExtension on Expression {
  String? get constructorNameIfInstanceCreation => switch (this) {
    InstanceCreationExpression(
      constructorName: ConstructorName(name: final name),
    ) =>
      name?.name,
    _ => null,
  };

  bool get isDotShorthand => switch (this) {
    DotShorthandConstructorInvocation() ||
    DotShorthandPropertyAccess() ||
    DotShorthandInvocation() => true,
    _ => false,
  };

  (InterfaceElement, DartType)? getShorthandPrefixElement() => switch (this) {
    InstanceCreationExpression(
      constructorName: ConstructorName(:final name),
      staticType: InterfaceType(:final element, :final extensionTypeErasure),
    )
        when name?.name != null && name?.name != 'new' =>
      (element, extensionTypeErasure),
    PropertyAccess(target: SimpleIdentifier(element: InterfaceElement e)) => (
      e,
      e.thisType,
    ),
    PrefixedIdentifier(prefix: SimpleIdentifier(element: InterfaceElement e)) =>
      (e, e.thisType),
    MethodInvocation(target: SimpleIdentifier(element: InterfaceElement e)) => (
      e,
      e.thisType,
    ),
    _ => null,
  };

  bool get hasExplicitTypeContext {
    final varDecl = thisOrAncestorOfType<VariableDeclaration>();
    if (varDecl != null) {
      final varList = varDecl.thisOrAncestorOfType<VariableDeclarationList>();
      if (varList?.type != null) {
        return true;
      }
    }

    return false;
  }
}

extension TypedLiteralExtension on TypedLiteral {
  DartType? getIterableGenericType(IterableType iterableType) {
    // `<String>[]`;
    //  ^^^^^^^^
    if (typeArguments case TypeArgumentList(
      arguments: [TypeAnnotation(:final type)],
    ) when type != null) {
      return type;
    }

    // then resolve parent
    final declaretype = switch (parent) {
      Declaration(
        parent: VariableDeclarationList(
          type: NamedType(:final InterfaceType type),
        ),
      ) =>
        type,
      DefaultFormalParameter(
        parameter: SimpleFormalParameter(
          type: NamedType(:final InterfaceType type),
        ),
      ) =>
        type,
      _ => null,
    };

    if (declaretype == null) return null;

    final checkIterableType = switch (iterableType) {
      IterableType.set => declaretype.isDartCoreSet,
      IterableType.list => declaretype.isDartCoreList,
    };
    if (!checkIterableType) return null;

    return switch (declaretype.typeArguments) {
      [final type] => type,
      _ => null,
    };
  }
}

enum IterableType { set, list }
