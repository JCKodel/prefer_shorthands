// ignore_for_file: unused_local_variable

void main() {
  final List<Direction> directions = [
    Direction.left,
    if (getCondition()) Direction.right,
  ];

  final Map<String, Direction> map1 = {
    'left': Direction.left,
    'right': Direction.right,
  };

  final Map<Direction, String> map2 = {
    Direction.left: 'left',
    Direction.right: 'right',
  };

  final Map<Direction, Direction> map3 = {
    Direction.left: Direction.right,
    Direction.right: Direction.left,
  };
}

bool getCondition() => true;

enum Direction { left, right }
