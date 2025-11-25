final object = <String, Direction>{}..['a'] = Direction.left;
final object2 = <String, dynamic>{}..['a'] = Direction.left;

void main() {
  object['a'] = Direction.left;
  object2['a'] = Direction.left;
}

enum Direction { left, right }
