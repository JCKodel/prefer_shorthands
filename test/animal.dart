const animalClasses = '''

abstract class Animal {
  static Dog dog() => Dog();
}

class Dog extends Animal {
  Dog();
  Dog.husky();
  Dog.labrador();
}

class Cat extends Animal {}
''';
