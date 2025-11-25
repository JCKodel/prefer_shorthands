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
    // Handle type arguments from literal itself
    // For list/set: `<String>[]` or `<String>{}`
    // For map: `<String, Direction>{}`
    if (typeArguments case TypeArgumentList(
      :final arguments,
    ) when arguments.isNotEmpty) {
      return switch (iterableType) {
        IterableType.mapValue when arguments.length == 2 => arguments[1].type,
        IterableType.mapKey when arguments.length == 2 => arguments[0].type,
        IterableType.list ||
        IterableType.set when arguments.length == 1 => arguments[0].type,
        _ => null,
      };
    }

    // Then resolve parent
    final declaredType = switch (parent) {
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

    if (declaredType == null) return null;

    final isMatchingType = switch (iterableType) {
      IterableType.set => declaredType.isDartCoreSet,
      IterableType.list => declaredType.isDartCoreList,
      IterableType.mapValue ||
      IterableType.mapKey => declaredType.isDartCoreMap,
    };
    if (!isMatchingType) return null;

    return switch ((iterableType, declaredType.typeArguments)) {
      (IterableType.mapValue, [_, final valueType]) => valueType,
      (IterableType.mapKey, [final keyType, _]) => keyType,
      (IterableType.list || IterableType.set, [final elementType]) =>
        elementType,
      _ => null,
    };
  }
}

enum IterableType { set, list, mapValue, mapKey }

extension AstNodeExtension on AstNode {
  DartType? findDeclaredType() {
    final varDecl = thisOrAncestorOfType<VariableDeclaration>();
    if (varDecl != null) {
      return switch (varDecl.parent) {
        VariableDeclarationList(type: NamedType(:final type)) => type,
        _ => null,
      };
    }

    final returnType = thisOrAncestorOfType<FunctionDeclaration>()?.returnType;
    if (returnType != null) {
      return returnType.type;
    }

    final getterReturnType =
        thisOrAncestorOfType<MethodDeclaration>()?.returnType;
    if (getterReturnType != null) {
      return getterReturnType.type;
    }

    return null;
  }

  DartType? getCollectionElementType() {
    final listLiteral = thisOrAncestorOfType<ListLiteral>();
    if (listLiteral != null) {
      return listLiteral.getIterableGenericType(IterableType.list);
    }

    final setLiteral = thisOrAncestorOfType<SetOrMapLiteral>();
    if (setLiteral != null && setLiteral.isSet) {
      return setLiteral.getIterableGenericType(IterableType.set);
    }

    return null;
  }
}
