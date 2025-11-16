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

  InterfaceElement? getShorthandPrefixElement() => switch (this) {
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
