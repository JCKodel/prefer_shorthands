## 0.2.0

- Fix case:

```dart
class Animal {}
class Dog {
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
