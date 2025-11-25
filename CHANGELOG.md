## 0.4.3

- Adapt `List` and `Set`.
- Adapt operator `!=`.
- Add case `DefaultFormalParameter` ([#8](https://github.com/huanghui1998hhh/prefer_shorthands/issues/8)).
- Fix case when assignment to `dynamic`, like `<String, dynamic>{}..**['a'] = Foo.a**` ([#11](https://github.com/huanghui1998hhh/prefer_shorthands/issues/11)).
- Add case `returnStatement` and `returnExpression` ([#9](https://github.com/huanghui1998hhh/prefer_shorthands/issues/9)).

## 0.4.2

- Fix `Size(100, 100) > Size.zero` be wrong marning, the opearator `>` required righthand type is `Size`'s Base Class, so here can't use shorthand.
A similar situation is operator `??`.
- Fix `bugDog(Animal.dog());`, `.dog` is `Animal`'s constructor, but function need a `Dog`, so here can't use shorthand.

## 0.4.1

- Fix [#5](https://github.com/huanghui1998hhh/prefer_shorthands/issues/5)

## 0.4.0

- Add more case.
- Optimized code.
- Improved testing.

## 0.3.3

- Chore

## 0.3.2

- Fix quick-fix case:

```dart
class Animal {
    static Dog dog => ...;
}
class Dog extends Animal{}

void main() {
    final animal = Animal.dog; // wrong quick-fix to `final Dog animal = .dog;`
}
```

- The assignment behavior will now be correctly detected.

## 0.3.1

- Support settings `convert_implicit_declaration`, defaults to `false`.

## 0.3.0+1

- Fix.

## 0.3.0

- Fix case `borderRadius: BorderRadius.all(.circular(16)),`

## 0.2.0

- Fix case:

```dart
class Animal {}
class Dog extends Animal{
    static Dog husky() => ...;
}

void foo(Animal animal){}

void main() {
    foo(Dog.husky()); // should not warning
}
```

## 0.1.0+1

- Update `README.md`.

## 0.1.0

- Fix analyze argument list.

## 0.0.1+1

- Fix.

## 0.0.1

- Warning when not use dot shorthands!
