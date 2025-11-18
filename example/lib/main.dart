void main() {
  final string = String.fromCharCode(96);
  var a = A();
  final b = A.defaultA;
  final d = A.b();
  final c = A.c();
  final e = EnumA.a;
  final f = A.defaultB;
  final B g = B.createB();
  final A h = B.createB();
  final enumList = EnumA.values;
  final enumItem = EnumA.values.first;
  final i = switch (enumItem) {
    EnumA.a => 1,
    EnumA.b => 2,
  };
  test(A.b(), b: B.createB());
  final j = C(A.b(), B.createB());
  final k = C.named(B.createB(), b: B.b());
  a = A.c();
  final A l = B.b();
  final m = switch (enumItem) {
    EnumA.a || EnumA.b when enumItem == EnumA.a => 1,
    _ => 2,
  };
  if (a == A.defaultB) {}
  switch (enumItem) {
    case EnumA.a:
    case EnumA.a || EnumA.b when enumItem == EnumA.a:
    default:
  }
  final A n = .integer(int.parse('1'));
  // dart format off
  print([string, a, b, c, d, e, f, g, h, i, j, k, l, m, n, enumList, enumItem]);
  // dart format on
}

class A {
  const A();

  const factory A.b() = B.b;

  const A.c();

  static A integer(int value) => A();

  static const defaultB = B();

  static const defaultA = A();
}

void test(A a, {B? b}) {}

class B extends A {
  const B();

  const B.b();

  static B createB() => const B();
}

class C {
  const C(A a, [B? b]);
  const C.named(A a, {A? b});
}

enum EnumA { a, b }

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
