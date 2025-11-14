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
  test(A.b(), b: B.createB());
  final j = C(A.b(), B.createB());
  final k = C.named(.b(), b: .createB());
  print([string, a, b, c, d, e, f, g, h, i, j, k, enumList, enumItem]);
}

class A {
  const A();

  const factory A.b() = B;

  const A.c();

  static const defaultB = B();

  static const defaultA = A();
}

void test(A a, {B? b}) {}

class B extends A {
  const B();

  static B createB() => const B();
}

class C {
  const C(A a, [B? b]);
  const C.named(A a, {B? b});
}

enum EnumA { a, b }
