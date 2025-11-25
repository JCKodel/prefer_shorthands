// ignore_for_file: unused_element, unused_local_variable

Direction leftDirection() {
  return Direction.left;
}

Direction rightDirection() => Direction.right;

Direction getDirection(String directionString) {
  final Direction temp = switch ('') {
    'left' => switch ('') {
      'left' => Direction.left,
      'right' => Direction.right,
      _ => throw ArgumentError(''),
    },
    'right' => Direction.right,
    _ => throw ArgumentError(''),
  };

  return switch (directionString) {
    'left' => switch (directionString) {
      'left' => Direction.left,
      'right' => Direction.right,
      _ => throw ArgumentError(''),
    },
    'right' => Direction.right,
    _ => throw ArgumentError(''),
  };
}

extension on String {
  Direction get direction => switch (this) {
    'left' => switch (this) {
      'left' => Direction.left,
      'right' => Direction.right,
      _ => throw ArgumentError(''),
    },
    'right' => Direction.right,
    _ => throw ArgumentError(''),
  };
}

enum Direction { left, right }
