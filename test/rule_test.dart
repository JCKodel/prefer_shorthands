// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferShorthandsRuleTest);
  });
}

// TODO: test not working yet, because i can't find a API to register the rule
@reflectiveTest
class PreferShorthandsRuleTest extends AnalysisRuleTest {
  @override
  String get analysisRule => 'prefer_shorthands';

  void test_prefer_shorthands() async {
    await assertDiagnostics(
      r'''
final SomeEnum temp = SomeEnum.a;
''',
      [lint(33, 5)],
    );
  }
}

enum SomeEnum { a, b }
