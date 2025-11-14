void main() {
  final string = String.fromCharCode(96);
  final a = A();
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

  print([string, a, b, c, d, e, f, g, h, i, enumList, enumItem]);
}

class A {
  const A();

  const factory A.b() = B;

  const A.c();

  static const defaultB = B();

  static const defaultA = A();
}

class B extends A {
  const B();

  static B createB() => const B();
}

enum EnumA { a, b }
