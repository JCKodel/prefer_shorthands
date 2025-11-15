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
