// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:prefer_shorthands/main.dart';
import 'package:prefer_shorthands/settings.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

late final String codeContent;

void main() async {
  Registry.ruleRegistry.registerLintRule(PreferShorthandsRule());

  codeContent = await File('example/lib/main.dart').readAsString();

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
      lint(200, 11),
      lint(353, 7),
      lint(372, 7),
      lint(400, 5),
      lint(410, 11),
      lint(439, 5),
      lint(446, 11),
      lint(497, 5),
      lint(512, 5),
    ]);
  }

  void test_convert_implicit_declaration() async {
    plugin.settings = Settings(convertImplicitDeclaration: true);
    await assertDiagnostics(codeContent, [
      lint(32, 23),
      lint(86, 10),
      lint(111, 5),
      lint(131, 5),
      lint(151, 7),
      lint(173, 10),
      lint(200, 11),
      lint(353, 7),
      lint(372, 7),
      lint(400, 5),
      lint(410, 11),
      lint(439, 5),
      lint(446, 11),
      lint(473, 30),
      lint(497, 5),
      lint(512, 5),
    ]);
  }
}
