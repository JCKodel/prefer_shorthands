void f({
  Set<Direction> directions = const {Direction.left, Direction.right},
  String a = const String.fromEnvironment('a'),
  b = const String.fromEnvironment('b'),
}) {}

enum Direction { left, right }
