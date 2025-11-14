import 'dart:io';

import 'package:yaml/yaml.dart';

class Settings {
  static Future<Settings> loadFromAnalysisOptions() async {
    final file = File('analysis_options.yaml');
    if (!file.existsSync()) {
      return const Settings();
    }
    final contents = await file.readAsString();
    final yaml = loadYaml(contents);
    final preferShorthands = yaml['prefer_shorthands'];
    if (preferShorthands is! YamlMap) {
      return const Settings();
    }

    return Settings(
      convertImplicitDeclaration: preferShorthands.getKeyAsTypeOrNull<bool>(
        'convert_implicit_declaration',
      ),
    );
  }

  const Settings({bool? convertImplicitDeclaration})
    : convertImplicitDeclaration = convertImplicitDeclaration ?? false;

  final bool convertImplicitDeclaration;

  @override
  String toString() =>
      'PreferShorthandsSettings(convertImplicitDeclaration: $convertImplicitDeclaration)';
}

extension on YamlMap {
  T? getKeyAsTypeOrNull<T>(String key) => switch (this[key]) {
    T value => value,
    _ => null,
  };
}
