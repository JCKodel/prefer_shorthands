// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:prefer_shorthands/main.dart';
import 'package:prefer_shorthands/settings.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'size.dart';

late final String codeContent;

void main() async {
  Registry.ruleRegistry.registerLintRule(PreferShorthandsRule());

  codeContent = (await File('example/lib/main.dart').readAsLines()).join('\n');

  defineReflectiveSuite(() {
    defineReflectiveTests(PreferShorthandsRuleTest);
  });
}

@reflectiveTest
class PreferShorthandsRuleTest extends AnalysisRuleTest {
  @override
  String get analysisRule => 'prefer_shorthands';

  void test_prefer_shorthands() async {
    plugin.settings = Settings(convertImplicitDeclaration: false);
    await assertDiagnostics(codeContent, [
      lint(192, 11),
      lint(340, 7),
      lint(358, 7),
      lint(384, 5),
      lint(394, 11),
      lint(422, 5),
      lint(429, 11),
      lint(479, 5),
      lint(493, 5),
      lint(514, 5),
      lint(557, 7),
      lint(568, 7),
      lint(593, 7),
      lint(635, 10),
      lint(681, 7),
      lint(699, 7),
      lint(710, 7),
      lint(735, 7),
      lint(784, 14),
    ]);
  }

  void test_convert_implicit_declaration() async {
    plugin.settings = Settings(convertImplicitDeclaration: true);
    await assertDiagnostics(codeContent, [
      lint(31, 23),
      lint(83, 10),
      lint(107, 5),
      lint(126, 5),
      lint(145, 7),
      lint(166, 10),
      lint(192, 11),
      lint(340, 7),
      lint(358, 7),
      lint(384, 5),
      lint(394, 11),
      lint(422, 5),
      lint(429, 11),
      lint(455, 30),
      lint(479, 5),
      lint(493, 5),
      lint(514, 5),
      lint(557, 7),
      lint(568, 7),
      lint(593, 7),
      lint(635, 10),
      lint(681, 7),
      lint(699, 7),
      lint(710, 7),
      lint(735, 7),
      lint(784, 14),
    ]);
  }

  /// https://github.com/huanghui1998hhh/prefer_shorthands/issues/5
  void test_5_generics_implicit() async {
    const code = '''
  final a = List.filled(5, EnumA.a);

  enum EnumA { a, b }
  ''';

    plugin.settings = Settings(convertImplicitDeclaration: false);
    await assertDiagnostics(code, []);
    plugin.settings = Settings(convertImplicitDeclaration: true);
    await assertDiagnostics(code, [lint(12, 23)]);
  }

  void test_5_generics_explicit() async {
    plugin.settings = Settings(convertImplicitDeclaration: true);
    await assertDiagnostics(
      '''
  final List<EnumA> a = List.filled(5, EnumA.a);

  enum EnumA { a, b }
  ''',
      [lint(24, 23), lint(39, 7)],
    );
  }

  void test_binaryExpression() async {
    await assertDiagnostics(
      '''
void main() {
  if (Size(100, 100) == Size.zero) {}
  if (Size(100, 100) > Size.zero) {}
}
$sizeClasses
''',
      [lint(38, 9)],
    );
  }
}
