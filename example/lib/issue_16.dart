enum Direction { left, right }

Direction get direction => Direction.left;

sealed class A {
  Direction get direction;
}

class B extends A {
  @override
  Direction get direction => Direction.left; // should recommend .left
}
