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
