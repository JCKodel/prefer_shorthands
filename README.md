# prefer_shorthands

[![pub package](https://img.shields.io/pub/v/prefer_shorthands.svg)](https://pub.dev/packages/prefer_shorthands)

⚡ **Linter** and **Quick-fix**. Enjoy it! ✨

> ⚠️ **Warning:** There may be some missing cases and other unknown issues. Welcome to [report an issue](https://github.com/huanghui1998hhh/prefer_shorthands/issues).

## Usage

To use this analyzer plugin, add it to your `analysis_options.yaml` file at the root of your Dart or Flutter project:

```yaml
plugins:
  prefer_shorthands: ^0.4.2
```

After adding the plugin, restart the Dart Analysis Server (in VS Code: press `Cmd+Shift+P` and select "Dart: Restart Analysis Server", or in IntelliJ/Android Studio: click the "Restart Dart Analysis Server" button in the toolbar).

## Settings

Add like this in your project `analysis_options.yaml`:

```yaml
prefer_shorthands:
  convert_implicit_declaration: true
```

|Paramenter|Default Value|Warning Code|Fix Result|
|----------|:-----------:|:----------:|:--------:|
|convert_implicit_declaration|false|`final a = String.fromCharCode(96);`|`final String a = .fromCharCode(96);`|

## Learn More

To learn more about Dart's dot shorthand syntax, check out the official documentation: [Dot shorthands - Dart](https://dart.dev/language/dot-shorthands)

## Feedback

If you encounter any issues while using this package, please feel free to report them on [GitHub Issues](https://github.com/huanghui1998hhh/prefer_shorthands/issues).
