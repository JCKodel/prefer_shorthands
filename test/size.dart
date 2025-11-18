const sizeClasses = '''

abstract class OffsetBase {
  const OffsetBase(this._dx, this._dy);

  final double _dx;
  final double _dy;

  bool operator >(OffsetBase other) => _dx > other._dx && _dy > other._dy;
}

class Size extends OffsetBase {
  const Size(super.width, super.height);
  static const Size zero = Size(0.0, 0.0);
}
''';
